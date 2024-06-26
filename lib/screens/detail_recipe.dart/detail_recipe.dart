import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:recipe_app/screens/add_recipe/edit_recipe.dart';
import 'package:recipe_app/screens/detail_recipe.dart/widgets/item_detail_recipe.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/service/rate_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailReCipe extends StatefulWidget {
  final String recipeId;
  final String userId;

  const DetailReCipe({
    super.key,
    required this.recipeId,
    required this.userId,
  });

  @override
  State<DetailReCipe> createState() => _DetailReCipeState();
}

class _DetailReCipeState extends State<DetailReCipe> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _recipeFuture;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _userRecipesFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _stepsFuture;

  User? currentUser = FirebaseAuth.instance.currentUser;

  List<Map<String, dynamic>> recipesWithUserData = [];

  double _avgRating = 0.0;
  int _ratingCount = 0;
  bool _hasRated = false;
  double _userRating = 0.0;

  bool _isFavorite = false;

  bool _isFollowing = false;
  Future<void> _checkFollowingStatus() async {
    final currentUserId = currentUser?.uid;
    final userId = widget.userId;
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data();
    final followings = userData?['followings'] ?? [];

    setState(() {
      _isFollowing = followings.contains(userId);
    });
  }

  @override
  void initState() {
    super.initState();
    _recipeFuture = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .get();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    _userRecipesFuture = _fetchUserRecipes();
    _stepsFuture = _fetchSteps();
    RateService.fetchAverageRating(widget.recipeId).then((result) {
      setState(() {
        _avgRating = result['avgRating'];
        _ratingCount = result['ratingCount'];
        _hasRated = result['hasRated'];
      });
    });
    _getUserRating();
    isRecipeFavorite(widget.recipeId).then((isFavorite) {
      setState(() {
        _isFavorite = isFavorite;
      });
    });

    _fetchRecipes();
    _checkFollowingStatus();
  }

  Future<void> _fetchRecipes() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userID',
            isEqualTo:
                widget.userId) // Lọc công thức của chủ công thức hiện tại
        .orderBy('createAt',
            descending: true) // Sắp xếp theo thời gian giảm dần
        .limit(4)
        .get();
    final recipes = snapshot.docs;

    recipesWithUserData = [];

    for (var recipeDoc in recipes) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id;

      var userId = recipeData['userID'];

      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userDoc.data();

      if (userData != null) {
        recipeData['recipeId'] = recipeId;

        bool test = await FavoriteService.isRecipeFavorite(recipeId);

        recipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
          'isFavorite': test,
        });
      }
    }

    setState(() {});
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>>
      _fetchUserRecipes() async {
    final userRecipesSnapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: widget.userId)
        .get();

    return userRecipesSnapshot.docs;
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchSteps() async {
    final stepsSnapshot = await FirebaseFirestore.instance
        .collection('steps')
        .where('recipeID', isEqualTo: widget.recipeId)
        .orderBy('order')
        .get();

    return stepsSnapshot.docs;
  }

  // rate
  Future<Map<String, dynamic>> _fetchAverageRating() async {
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('recipeId', isEqualTo: widget.recipeId)
        .get();

    final ratings =
        ratingsSnapshot.docs.map((doc) => doc.data()['star'] as num).toList();

    final userRatingSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .doc('${currentUser?.uid}_${widget.recipeId}')
        .get();

    final hasRated = userRatingSnapshot.exists;

    if (ratings.isEmpty) {
      return {'avgRating': 0.0, 'ratingCount': 0, 'hasRated': hasRated};
    }

    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    final ratingCount = ratings.length;

    return {
      'avgRating': avgRating.toDouble(),
      'ratingCount': ratingCount,
      'hasRated': hasRated
    };
  }

  Future<void> _getUserRating() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final recipeId = widget.recipeId;

    final ratingSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('userId', isEqualTo: currentUserId)
        .where('recipeId', isEqualTo: recipeId)
        .get();

    if (ratingSnapshot.docs.isNotEmpty) {
      final ratingData = ratingSnapshot.docs.first.data();
      _userRating = ratingData['star']?.toDouble() ?? 0.0;
    }
  }

  Future<void> _updateRatingState() async {
    final newAvgRating = await _fetchAverageRating();
    setState(() {
      _avgRating = newAvgRating['avgRating'];
      _ratingCount = newAvgRating['ratingCount'];
      _hasRated = newAvgRating['hasRated'];
    });
  }

  // Favorite
  Future<bool> isRecipeFavorite(String recipeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }

    final favoriteSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: currentUser.uid)
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    return favoriteSnapshot.docs.isNotEmpty;
  }

  Widget _buildYoutubePlayerOrImage(String? urlYoutube, String imageUrl) {
    if (urlYoutube == null ||
        YoutubePlayer.convertUrlToId(urlYoutube) == null) {
      return Image.network(
        imageUrl,
        height: 200,
        width: 355,
        fit: BoxFit.cover,
      );
    }

    return YoutubePlayer(
      controller: YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(urlYoutube).toString(),
        flags: YoutubePlayerFlags(autoPlay: false),
      ),
      showVideoProgressIndicator: true,
      onReady: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          currentUser != null 
          ?
          currentUser!.uid == widget.userId
              ? IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                           EditRecipeScreen(recipeId: widget.recipeId),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit))
              : Container()
          : Container(),

          StatefulBuilder(builder: (context, setState) {
            return IconButton(
              onPressed: () async {
                await FavoriteService.toggleFavorite(context, widget.recipeId);
                setState(() {
                  _isFavorite = !_isFavorite;
                });
              },
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : null,
              ),
            );
          }),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: FutureBuilder(
          future: Future.wait(
              [_recipeFuture, _userFuture, _userRecipesFuture, _stepsFuture]),
          builder:
              (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.length != 4) {
              return Center(child: Text('Data not available'));
            }

            var recipeSnapshot =
                snapshot.data![0] as DocumentSnapshot<Map<String, dynamic>>;
            var userSnapshot =
                snapshot.data![1] as DocumentSnapshot<Map<String, dynamic>>;
            var userRecipesSnapshot = snapshot.data![2]
                as List<DocumentSnapshot<Map<String, dynamic>>>;
            var stepsSnapshot = snapshot.data![3]
                as List<DocumentSnapshot<Map<String, dynamic>>>;

            var recipeData = recipeSnapshot.data();
            var userData = userSnapshot.data();

            if (recipeData == null || userData == null) {
              return Center(child: Text('Data not available'));
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10),
                    Center(
                      child: Container(
                        height: 200,
                        width: 355,
                        child: _buildYoutubePlayerOrImage(
                          recipeData['urlYoutube'],
                          recipeData[
                              'image'], // Ensure this field exists in your data
                        ),
                        // YoutubePlayer(
                        //   controller: YoutubePlayerController(
                        //       initialVideoId: YoutubePlayer.convertUrlToId(
                        //               recipeData['urlYoutube'])
                        //           .toString(),
                        //       flags: YoutubePlayerFlags(autoPlay: false)),
                        //   showVideoProgressIndicator: true,
                        //   onReady: () {},
                        // ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Tên món ăn: ${recipeData['namerecipe']}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'Mô tả món ăn: ${recipeData['description']}',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Divider(color: Colors.black, thickness: 1),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'Nguyên liệu',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Divider(color: Colors.black, thickness: 1),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (recipeData['ingredients'] as List<dynamic>)
                          .map((ingredient) {
                        return ItemDetailRecipe(
                          index: ((recipeData['ingredients'] as List<dynamic>)
                                      .indexOf(ingredient)
                                      .toInt() +
                                  1)
                              .toString(),
                          title: ingredient.toString(),
                        );
                      }).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Divider(color: Colors.black, thickness: 1),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Cách làm',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Divider(color: Colors.black, thickness: 1),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: stepsSnapshot.map((step) {
                        var stepData = step.data();
                        return ItemDetailRecipe(
                          index: (stepData!['order'] as int).toString(),
                          title: stepData['title'],
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (stepData['images'] != null &&
                                    (stepData['images'] as List<dynamic>)
                                        .isNotEmpty)
                                  Container(
                                    height: MediaQuery.of(context).size.width *
                                        0.25,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount:
                                          (stepData['images'] as List<dynamic>)
                                              .length,
                                      itemBuilder: (context, imageIndex) {
                                        return Padding(
                                          padding: EdgeInsets.only(right: 8.0),
                                          child: Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width *
                                                0.25,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: NetworkImage(
                                                  (stepData['images'] as List<
                                                      dynamic>)[imageIndex],
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                              color: Colors.blue,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 5),
                    SizedBox(height: 10),
                    Divider(),
                    SizedBox(height: 5),
                    Center(
                      child: Container(
                        height: 60,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(width: 10),
                              RatingBar.builder(
                                initialRating: _hasRated ? _userRating : 0,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemPadding:
                                    EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rating) async {
                                  if (currentUser != null) {
                                    final userRatingRef = FirebaseFirestore
                                        .instance
                                        .collection('rates')
                                        .doc(
                                            '${currentUser?.uid}_${widget.recipeId}');

                                    if (_hasRated) {
                                      await userRatingRef
                                          .update({'star': rating});
                                    } else {
                                      await userRatingRef.set({
                                        'userId': currentUser?.uid,
                                        'recipeId': widget.recipeId,
                                        'star': rating,
                                        'createAt':
                                            FieldValue.serverTimestamp(),
                                      });
                                      setState(() {
                                        _hasRated = true;
                                      });
                                    }

                                    await _updateRatingState();
                                    setState(() {
                                      _userRating = rating;
                                    });
                                  } else {
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: Text('Bạn chưa đăng nhập'),
                                          content: Text(
                                              'Vui lòng đăng nhập để tiếp tục.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          const SignInScreen()),
                                                );
                                              },
                                              child: Text('Đăng nhập'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: Text('Hủy'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  }
                                },
                              ),
                              Text(
                                'Đánh giá $_avgRating/5 từ ${_ratingCount.toString()} thành viên',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 5),
                    Center(
                      child: Container(
                        height: 180,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.comment),
                                  SizedBox(width: 10),
                                  Text('Bình luận'),
                                  SizedBox(width: 10),
                                  Text('4'),
                                ],
                              ),
                              SizedBox(height: 5),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => CommentScreen(
                                        recipeId: widget.recipeId,
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                                child: Text('Xem tất cả bình luận'),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Phạm Duy Đạt'),
                                  SizedBox(width: 10),
                                  Text('Ngon quá'),
                                ],
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  CircleAvatar(radius: 20),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => CommentScreen(
                                              recipeId: widget.recipeId,
                                              userId: widget.userId,
                                              autoFocus: true,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          border: Border.all(),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color: Colors.white,
                                        ),
                                        alignment: Alignment.centerLeft,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16),
                                        child: Text('Bình luận ngay'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Divider(),
                    SizedBox(height: 5),
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 250,
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              SizedBox(height: 20),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ProfileUser(
                                              userId: widget.userId,
                                            )),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(
                                    userData['avatar'] ?? '',
                                  ),
                                ),
                              ),
                              Text('Được đăng tải bởi'),
                              Text(userData['fullname'] ?? ''),
                              Text(
                                'Ngày tạo công thức: ${recipeData['createAt']?.toDate().toString() ?? ''}',
                              ),
                              StatefulBuilder(
                                builder: (context, setState) {
                                  return GestureDetector(
                                    onTap: () async {
                                      final currentUserId = currentUser?.uid;
                                      final userId = widget.userId;
                                      final userRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(currentUserId);

                                      final userOther = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(userId);

                                      final userSnapshot = await userRef.get();
                                      final userData = userSnapshot.data();
                                      final followings =
                                          userData?['followings'] ?? [];

                                      if (followings.contains(userId)) {
                                        // Nếu đã theo dõi, hủy theo dõi
                                        await userRef.update({
                                          'followings':
                                              FieldValue.arrayRemove([userId])
                                        });
                                        await userOther.update({
                                          'followers': FieldValue.arrayRemove(
                                              [currentUserId])
                                        });
                                        setState(() {
                                          _isFollowing = false;
                                        });
                                      } else {
                                        await userRef.update({
                                          'followings':
                                              FieldValue.arrayUnion([userId])
                                        });
                                        await userOther.update({
                                          'followers': FieldValue.arrayUnion(
                                              [currentUserId])
                                        });
                                        setState(() {
                                          _isFollowing = true;
                                        });
                                      }
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 100,
                                      color: Colors.amber,
                                      child: Center(
                                        child: Text(
                                          _isFollowing
                                              ? 'Đang theo dõi'
                                              : 'Theo dõi',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 5),
                    Divider(),
                    SizedBox(height: 5),
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Các món mới từ ${userData['fullname']}',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: recipesWithUserData.length,
                              itemBuilder: (context, index) {
                                final recipeWithUser =
                                    recipesWithUserData[index];
                                final recipe = recipeWithUser['recipe'];
                                final user = recipeWithUser['user'];
                                final isFavorite = recipeWithUser['isFavorite'];

                                return Container(
                                  child: Center(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: FutureBuilder<double>(
                                          future: RateService.getAverageRating(
                                              recipe['recipeId']),
                                          builder: (context, snapshot) {
                                            double averageRating =
                                                snapshot.data ?? 0.0;
                                            return ItemRecipe(
                                              ontap: () {
                                                // Navigate to recipe detail screen
                                              },
                                              name: recipe['namerecipe'] ?? '',
                                              star: averageRating
                                                  .toStringAsFixed(1),
                                              favorite: recipe['liked']
                                                      ?.length
                                                      .toString() ??
                                                  '0',
                                              avatar: user['avatar'] ?? '',
                                              fullname: user['fullname'] ?? '',
                                              image: recipe['image'] ?? '',
                                              isFavorite: isFavorite,
                                              onFavoritePressed: () =>
                                                  FavoriteService
                                                      .toggleFavorite(context,
                                                          recipe['recipeId']),
                                            );
                                          }),
                                    ),
                                  ),
                                );
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
