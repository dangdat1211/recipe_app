import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';

import 'package:recipe_app/screens/detail_recipe.dart/widgets/item_ingredient.dart';
import 'package:recipe_app/screens/detail_recipe.dart/widgets/item_step.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class AdminRecipeReview extends StatefulWidget {
  final String recipeId;
  final String userId;

  const AdminRecipeReview({
    Key? key,
    required this.recipeId,
    required this.userId,
  }) : super(key: key);

  @override
  State<AdminRecipeReview> createState() => _AdminRecipeReviewState();
}

class _AdminRecipeReviewState extends State<AdminRecipeReview> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _recipeFuture;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  late Future<List<DocumentSnapshot<Map<String, dynamic>>>> _stepsFuture;

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _recipeFuture = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .get();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
    _stepsFuture = _fetchSteps();
  }

  Future<List<DocumentSnapshot<Map<String, dynamic>>>> _fetchSteps() async {
    final stepsSnapshot = await FirebaseFirestore.instance
        .collection('steps')
        .where('recipeID', isEqualTo: widget.recipeId)
        .orderBy('order')
        .get();

    return stepsSnapshot.docs;
  }

  Widget _buildYoutubePlayerOrImage(String? urlYoutube, String imageUrl) {
    if (urlYoutube == null ||
        YoutubePlayer.convertUrlToId(urlYoutube) == null) {
      return Image.network(
        imageUrl,
        height: 200,
        width: 355,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.error);
        },
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

  void _approveRecipe(String recipeId) async {
    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      String recipeOwnerId = recipeDoc.get('userID');
      String recipeName = recipeDoc.get('namerecipe');

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'status': 'Đã được phê duyệt'});

      // Gửi thông báo cho chủ công thức
      await NotificationService().createNotification(
          content: 'Công thức "$recipeName" của bạn đã được phê duyệt',
          fromUser: currentUser!.uid,
          userId: recipeOwnerId,
          recipeId: recipeId,
          screen: 'recipe');

      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipeOwnerId)
          .get();
      String? ownerFcmToken = ownerDoc.get('FCM');
      String? recipeOwnerName = ownerDoc.get('fullname');

      if (ownerFcmToken != null && ownerFcmToken.isNotEmpty) {
        await NotificationService.sendNotification(
            ownerFcmToken,
            'Công thức được phê duyệt',
            'Công thức "$recipeName" của bạn đã được phê duyệt',
            data: {
              'screen': 'recipe',
              'recipeId': recipeId,
              'userId': currentUser!.uid
            });
      }

      // Gửi thông báo cho những người đang follow chủ công thức
      QuerySnapshot usersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('following', arrayContains: recipeOwnerId)
          .get();

      for (var userDoc in usersDocs.docs) {
        String followerId = userDoc.id;

        await NotificationService().createNotification(
            content: 'vừa đăng một công thức mới: "$recipeName"',
            fromUser: recipeOwnerId,
            userId: followerId,
            recipeId: recipeId,
            screen: 'recipe');

        String? followerFcmToken = userDoc.get('FCM');

        if (followerFcmToken != null && followerFcmToken.isNotEmpty) {
          await NotificationService.sendNotification(
              followerFcmToken,
              'Công thức mới',
              '$recipeOwnerName vừa đăng một công thức mới: "$recipeName"',
              data: {
                'screen': 'recipe',
                'recipeId': recipeId,
                'userId': recipeOwnerId
              });
        }
      }
      SnackBarCustom.showbar(context, 'Công thức đã được phê duyệt');
      Navigator.pop(context);
    } catch (error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi phê duyệt công thức');
    }
  }

  void _rejectRecipe(String recipeId) async {
    String? rejectionReason = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        String reason = '';
        return AlertDialog(
          title: Text('Lý do từ chối'),
          content: TextField(
            onChanged: (value) {
              reason = value;
            },
            decoration: InputDecoration(hintText: "Nhập lý do từ chối"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xác nhận'),
              onPressed: () {
                Navigator.of(context).pop(reason);
              },
            ),
          ],
        );
      },
    );

    if (rejectionReason == null || rejectionReason.isEmpty) {
      SnackBarCustom.showbar(context, 'Vui lòng nhập lý do từ chối');
      return;
    }

    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      String recipeOwnerId = recipeDoc.get('userID');
      String recipeName = recipeDoc.get('namerecipe');

      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({'status': 'Bị từ chối', 'rejectionReason': rejectionReason});

      // Gửi thông báo cho chủ công thức
      await NotificationService().createNotification(
          content:
              'Công thức "$recipeName" của bạn đã bị từ chối. Lý do: $rejectionReason',
          fromUser: currentUser!.uid,
          userId: recipeOwnerId,
          recipeId: recipeId,
          screen: 'recipe');

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(recipeOwnerId)
          .get();
      String? ownerFcmToken = userDoc.get('FCM');

      if (ownerFcmToken != null && ownerFcmToken.isNotEmpty) {
        await NotificationService.sendNotification(
            ownerFcmToken,
            'Công thức bị từ chối',
            'Công thức "$recipeName" của bạn đã bị từ chối. Lý do: $rejectionReason',
            data: {
              'screen': 'recipe',
              'recipeId': recipeId,
              'userId': currentUser!.uid
            });
      }
      SnackBarCustom.showbar(context, 'Công thức đã bị từ chối');
      Navigator.pop(context);
    } catch (error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi từ chối công thức');
    }
  }

  bool _showAllIngredients = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Xem xét công thức'),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              _approveRecipe(widget.recipeId);
            },
          ),
          IconButton(
            icon: Icon(Icons.close),
            onPressed: () {
              _rejectRecipe(widget.recipeId);
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_recipeFuture, _userFuture, _stepsFuture]),
        builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.length != 3) {
            return Center(child: Text('Data not available'));
          }

          var recipeSnapshot =
              snapshot.data![0] as DocumentSnapshot<Map<String, dynamic>>;
          var userSnapshot =
              snapshot.data![1] as DocumentSnapshot<Map<String, dynamic>>;
          var stepsSnapshot =
              snapshot.data![2] as List<DocumentSnapshot<Map<String, dynamic>>>;

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
                        recipeData['image'],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      'Tên món ăn: ${recipeData['namerecipe']}',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                            'Thông tin cơ bản',
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
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    children: [
                      Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Text('Khẩu phần'),
                              Text(recipeData['ration'] + ' người')
                            ],
                          )),
                      Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Text('Thời gian'),
                              Text(recipeData['time'])
                            ],
                          )),
                      Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              Text('Độ khó'),
                              Text(recipeData['level'])
                            ],
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
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
                  StatefulBuilder(builder: (context, setState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...(recipeData['ingredients'] as List<dynamic>)
                            .take(3)
                            .map((ingredient) {
                          return ItemIngredient(
                            index: ((recipeData['ingredients'] as List<dynamic>)
                                        .indexOf(ingredient)
                                        .toInt() +
                                    1)
                                .toString(),
                            title: ingredient['quality'] != '' ?
                                          '${ingredient['name']} - ${ingredient['quality']}' : '${ingredient['name']}',
                          );
                        }).toList(),
                        if ((recipeData['ingredients'] as List<dynamic>)
                                .length >
                            3)
                          AnimatedCrossFade(
                            duration: Duration(milliseconds: 300),
                            firstChild: Container(),
                            secondChild: Column(
                              children:
                                  (recipeData['ingredients'] as List<dynamic>)
                                      .skip(3)
                                      .map((ingredient) {
                                return ItemIngredient(
                                  index: ((recipeData['ingredients']
                                                  as List<dynamic>)
                                              .indexOf(ingredient)
                                              .toInt() +
                                          1)
                                      .toString(),
                                  title: ingredient['quality'] != '' ?
                                          '${ingredient['name']} - ${ingredient['quality']}' : '${ingredient['name']}',
                                );
                              }).toList(),
                            ),
                            crossFadeState: _showAllIngredients
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                          ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _showAllIngredients = !_showAllIngredients;
                            });
                          },
                          child: Text(
                              _showAllIngredients ? 'Ẩn bớt' : 'Hiện tất cả'),
                        ),
                      ],
                    );
                  }),
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
                      return ItemStep(
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
                                  height:
                                      MediaQuery.of(context).size.width * 0.25,
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
