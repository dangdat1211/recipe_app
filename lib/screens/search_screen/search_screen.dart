import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResultsWithUserData = [];
  bool isLoading = false;

  void _onSearchSubmitted(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          // .where('namerecipe', isGreaterThanOrEqualTo: query)
          // .where('namerecipe', isLessThan: query + '\uf8ff')
          .get();
      print('Số lượng kết quả tìm kiếm: ${snapshot.docs.length}');

      searchResultsWithUserData = [];

      for (var recipeDoc in snapshot.docs) {
        var recipeData = recipeDoc.data() as Map<String, dynamic>;
        var recipeId = recipeDoc.id;

        var userId = recipeData['userID'];

        var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        var userData = userDoc.data();

        if (userData != null) {
          recipeData['recipeId'] = recipeId;

          bool isFavorite = await FavoriteService.isRecipeFavorite(recipeId);

          if (recipeData['namerecipe'].toString().toLowerCase().contains(query.toLowerCase())) {
            searchResultsWithUserData.add({
              'recipe': recipeData,
              'user': userData,
              'isFavorite': isFavorite,
            });
          }
        }
      }

      setState(() {
        isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResultsWithUserData.clear();
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
          ),
          onSubmitted: _onSearchSubmitted,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              _onSearchSubmitted(_searchController.text);
            },
          ),
        ],
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : searchResultsWithUserData.isNotEmpty
              ? Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    color: Colors.white,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(21.0),
                        child: Container(
                          child: ListView.builder(
                            itemCount: searchResultsWithUserData.length,
                            itemBuilder: (context, index) {
                              final recipeWithUser = searchResultsWithUserData[index];
                              final recipe = recipeWithUser['recipe'];
                              final user = recipeWithUser['user'];
                              final isFavorite = recipeWithUser['isFavorite'];
                          
                              return ItemRecipe(
                                name: recipe['namerecipe'],
                                star: recipe['rates'].length.toString(),
                                favorite: recipe['likes'].length.toString(),
                                avatar: user['avatar'],
                                fullname: user['fullname'],
                                image: recipe['image'],
                                ontap: () {
                                  // Xử lý sự kiện khi nhấn vào công thức
                                },
                                isFavorite: isFavorite,
                                onFavoritePressed: () {
                                  FavoriteService.toggleFavorite(context,recipe['recipeId']);
                                  _onSearchSubmitted(_searchController.text);
                                } 
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text('Không có kết quả tìm kiếm'),
                ),
    );
  }
}