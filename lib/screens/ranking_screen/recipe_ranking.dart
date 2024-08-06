import 'package:flutter/material.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/service/rate_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/constants/colors.dart';

class RecipeRanking extends StatefulWidget {
  const RecipeRanking({super.key});

  @override
  State<RecipeRanking> createState() => _RecipeRankingState();
}

class _RecipeRankingState extends State<RecipeRanking> {
  String sortValue = 'Lượt thích cao nhất';
  String timeValue = 'Tất cả';
  List<Map<String, dynamic>> recipesWithUserData = [];
  bool isLoading = false;

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await FirebaseFirestore.instance.collection('recipes').where('status', isEqualTo: 'Đã được phê duyệt').get();

    var filteredDocs = snapshot.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      return data['hidden'] == false;
    }).toList();

    final recipes = filteredDocs;

    recipesWithUserData = [];

    for (var recipeDoc in recipes) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id;

      var userId = recipeData['userID'];

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var userData = userDoc.data();

      if (userData != null) {
        recipeData['recipeId'] = recipeId;

        var favoriteCount = await _getFavoriteCount(recipeId);
        var ratingData = await _fetchAverageRating(recipeId);

        bool isFavorite = await FavoriteService.isRecipeFavorite(recipeId);

        recipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
          'isFavorite': isFavorite,
          'favoriteCount': favoriteCount,
          'avgRating': ratingData['avgRating'],
          'ratingCount': ratingData['ratingCount'],
        });
      }
    }

    _sortRecipes();

    setState(() {
      isLoading = false;
    });
  }

  Future<int> _getFavoriteCount(String recipeId) async {
    var now = DateTime.now();
    var query = FirebaseFirestore.instance.collection('favorites').where('recipeId', isEqualTo: recipeId);

    if (timeValue == '7 ngày gần nhất') {
      query = query.where('createAt', isGreaterThan: now.subtract(Duration(days: 9)));
    } else if (timeValue == '30 ngày gần nhất') {
      query = query.where('createAt', isGreaterThan: now.subtract(Duration(days: 30)));
    }

    var snapshot = await query.get();
    return snapshot.docs.length;
  }

  Future<Map<String, dynamic>> _fetchAverageRating(String recipeId) async {
  User? currentUser = FirebaseAuth.instance.currentUser;
  var now = DateTime.now();
  var query = FirebaseFirestore.instance
      .collection('rates')
      .where('recipeId', isEqualTo: recipeId);

  if (timeValue == '7 ngày gần nhất') {
    query = query.where('createAt', isGreaterThan: now.subtract(Duration(days: 7)));
  } else if (timeValue == '30 ngày gần nhất') {
    query = query.where('createAt', isGreaterThan: now.subtract(Duration(days: 30)));
  }

  final ratingsSnapshot = await query.get();

  final ratings =
      ratingsSnapshot.docs.map((doc) => doc.data()['star'] as num).toList();

  final userRatingSnapshot = await FirebaseFirestore.instance
      .collection('rates')
      .doc('${currentUser?.uid}_${recipeId}')
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

  void _sortRecipes() {
    if (sortValue == 'Lượt thích cao nhất') {
      recipesWithUserData.sort((a, b) {
        return b['favoriteCount'].compareTo(a['favoriteCount']);
      });
    } else if (sortValue == 'Điểm đánh giá cao nhất') {
      recipesWithUserData.sort((a, b) {
        return b['avgRating'].compareTo(a['avgRating']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildSortDropdown(),),
              Expanded(child: _buildTimeDropdown(),)
            ],
          ),
          isLoading
              ? Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recipesWithUserData.length,
                        itemBuilder: (context, index) {
                          final recipeWithUser = recipesWithUserData[index];
                          final recipe = recipeWithUser['recipe'];
                          final user = recipeWithUser['user'];
                          final isFavorite = recipeWithUser['isFavorite'];

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: index + 1 == 1
                                      ? Colors.amber
                                      : index + 1 == 2
                                          ? Colors.grey
                                          : Colors.brown,
                                ),
                                child: Center(
                                  child: Text(
                                    (index + 1).toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                width: 30,
                                height: 30,
                              ),
                              SizedBox(width: 10),
                              Container(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ItemRecipe(
                                      ontap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => DetailReCipe(recipeId: recipe['recipeId'], userId: recipe['userID'])),
                                        );
                                      },
                                      name: recipe['namerecipe'],
                                      star: recipeWithUser['avgRating'].toStringAsFixed(1),
                                      favorite: recipeWithUser['favoriteCount'].toString(),
                                      avatar: user['avatar'],
                                      fullname: user['fullname'],
                                      image: recipe['image'],
                                      isFavorite: isFavorite,
                                      onFavoritePressed: () {
                                        if (currentUser != null) {
                                          FavoriteService.toggleFavorite(context, recipe['recipeId'], recipe['userID']);
                                        } else {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text('Bạn chưa đăng nhập'),
                                                content: Text('Vui lòng đăng nhập để tiếp tục.'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(builder: (context) => const SignInScreen()),
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
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: sortValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: mainColor, size: 20),
          style: TextStyle(color: mainColor, fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              sortValue = newValue!;
              _fetchRecipes();
            });
          },
          items: <String>['Lượt thích cao nhất', 'Điểm đánh giá cao nhất']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown() {
    return Container(
      margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: timeValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: mainColor, size: 20),
          style: TextStyle(color: mainColor, fontSize: 14),
          onChanged: (String? newValue) {
            setState(() {
              timeValue = newValue!;
              _fetchRecipes();
            });
          },
          items: <String>['7 ngày gần nhất', '30 ngày gần nhất', 'Tất cả']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}