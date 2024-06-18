import 'package:flutter/material.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeRanking extends StatefulWidget {
  const RecipeRanking({super.key});

  @override
  State<RecipeRanking> createState() => _RecipeRankingState();
}

class _RecipeRankingState extends State<RecipeRanking> {
  String dropdownValue = 'Option 1';
  List<Map<String, dynamic>> recipesWithUserData = [];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    final recipes = snapshot.docs;

    recipesWithUserData = [];

    for (var recipeDoc in recipes) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id;

      var userId = recipeData['userID'];

      var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      var userData = userDoc.data();

      if (userData != null) {
        recipeData['recipeId'] = recipeId;

        bool isFavorite = await FavoriteService.isRecipeFavorite(recipeId);

        recipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
          'isFavorite': isFavorite,
        });
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: dropdownValue,
                    onChanged: (String? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                    items: <String>[
                      'Option 1',
                      'Option 2',
                      'Option 3',
                      'Option 4'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
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
                                ontap: () {},
                                name: recipe['namerecipe'],
                                star: recipe['rates'].length.toString(),
                                favorite: recipe['likes'].length.toString(),
                                avatar: user['avatar'],
                                fullname: user['fullname'],
                                image: recipe['image'],
                                isFavorite: isFavorite,
                                onFavoritePressed: () =>
                                    FavoriteService.toggleFavorite(context, recipe['recipeId']),
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
}