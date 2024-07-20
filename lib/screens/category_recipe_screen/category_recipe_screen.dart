import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class CategoryRecipeScreen extends StatefulWidget {
  final String categoryId;

  const CategoryRecipeScreen({super.key, required this.categoryId});

  @override
  State<CategoryRecipeScreen> createState() => _CategoryRecipeScreenState();
}

class _CategoryRecipeScreenState extends State<CategoryRecipeScreen> {
  String categoryName = '';
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResultsWithUserData = [];
  bool isLoading = false;
  String currentSortOption = 'Mới nhất';

  Map<String, List<String>> selectedFilters = {
    'difficulty': [],
    'time': [],
    'method': [],
  };

  @override
  void initState() {
    super.initState();
    _loadCategoryName();
    _loadRecipes();
  }

  Future<void> _loadCategoryName() async {
    try {
      DocumentSnapshot categoryDoc = await FirebaseFirestore.instance
          .collection('categories')
          .doc(widget.categoryId)
          .get();

      if (categoryDoc.exists) {
        setState(() {
          categoryName = categoryDoc.get('name') as String;
        });
      }
    } catch (e) {
      print('Error loading category name: $e');
    }
  }

  void _loadRecipes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('category', arrayContains: widget.categoryId)
          .where('status', isEqualTo: 'Đã được phê duyệt')
          .where('hidden', isEqualTo: false)
          .get();

      searchResultsWithUserData = [];

      for (var recipeDoc in snapshot.docs) {
        var recipeData = recipeDoc.data() as Map<String, dynamic>;
        var recipeId = recipeDoc.id;

        var userId = recipeData['userID'];

        var userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        var userData = userDoc.data();

        if (userData != null) {
          bool isFavorite = await FavoriteService.isRecipeFavorite(recipeId);

          searchResultsWithUserData.add({
            'recipe': recipeData,
            'user': userData,
            'isFavorite': isFavorite,
            'recipeId': recipeId,
          });
        }
      }

      _applySortAndFilter();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error loading recipes: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _applySortAndFilter() {
    searchResultsWithUserData = searchResultsWithUserData.where((result) {
      var recipeData = result['recipe'];
      
      bool difficultyMatch = selectedFilters['difficulty']!.isEmpty || 
                             selectedFilters['difficulty']!.contains(recipeData['level']);

      bool methodMatch = selectedFilters['method']!.isEmpty ||
                         selectedFilters['method']!.any((method) =>
                             recipeData['namerecipe']
                                 .toString()
                                 .toLowerCase()
                                 .contains(method.toLowerCase()));

      bool timeMatch = selectedFilters['time']!.isEmpty;
      if (!timeMatch) {
        int recipeCookingTime = int.tryParse(recipeData['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        timeMatch = selectedFilters['time']!.any((timeFilter) {
          if (timeFilter == '< 30 phút') return recipeCookingTime < 30;
          if (timeFilter == '30-60 phút') return recipeCookingTime >= 30 && recipeCookingTime <= 60;
          if (timeFilter == '> 60 phút') return recipeCookingTime > 60;
          return false;
        });
      }

      return difficultyMatch && methodMatch && timeMatch;
    }).toList();

    searchResultsWithUserData.sort((a, b) {
      switch (currentSortOption) {
        case 'Đánh giá cao nhất':
          return (b['recipe']['rates'] as List).length.compareTo((a['recipe']['rates'] as List).length);
        case 'Yêu thích nhiều nhất':
          return (b['recipe']['likes'] as List).length.compareTo((a['recipe']['likes'] as List).length);
        case 'Mới nhất':
        default:
          return (b['recipe']['createAt'] as Timestamp).compareTo(a['recipe']['createAt'] as Timestamp);
      }
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Lọc và Sắp xếp kết quả'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButton<String>(
                      value: currentSortOption,
                      onChanged: (String? newValue) {
                        setState(() {
                          currentSortOption = newValue!;
                        });
                      },
                      items: <String>['Mới nhất', 'Đánh giá cao nhất', 'Yêu thích nhiều nhất']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20),
                    Text('Độ khó:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('difficulty', ['Dễ', 'Trung bình', 'Khó'], setState),
                    SizedBox(height: 10),
                    Text('Mốc thời gian:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('time', ['< 30 phút', '30-60 phút', '> 60 phút'], setState),
                    SizedBox(height: 10),
                    Text('Phương pháp chế biến:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._buildCheckboxes('method', ['Rán', 'Xào', 'Nướng', 'Hấp'], setState),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Áp dụng'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applySortAndFilter();
                    setState(() {});
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildCheckboxes(String filterType, List<String> options, StateSetter setState) {
    return options.map((option) {
      return CheckboxListTile(
        title: Text(option),
        value: selectedFilters[filterType]!.contains(option),
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              selectedFilters[filterType]!.add(option);
            } else {
              selectedFilters[filterType]!.remove(option);
            }
          });
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(categoryName.isNotEmpty ? categoryName : 'Loại món ăn'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm công thức...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  // Áp dụng tìm kiếm ngay khi người dùng nhập
                  _applySortAndFilter();
                });
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : searchResultsWithUserData.isEmpty
                    ? Center(child: Text('Không có công thức nào.'))
                    : Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        color: Colors.white,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 21.0, right: 22, top: 10),
                            child: Container(
                              child: ListView.builder(
                                  itemCount: searchResultsWithUserData.length,
                                  itemBuilder: (context, index) {
                                    final recipeWithUser = searchResultsWithUserData[index];
                                    final recipe = recipeWithUser['recipe'];
                                    final user = recipeWithUser['user'];
                                    final isFavorite = recipeWithUser['isFavorite'];
                                    final recipeId = recipeWithUser['recipeId'];
                              
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: ItemRecipe(
                                        name: recipe['namerecipe'],
                                        star: recipe['rates'].length.toString(),
                                        favorite: recipe['likes'].length.toString(),
                                        avatar: user['avatar'],
                                        fullname: user['fullname'],
                                        image: recipe['image'],
                                        ontap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => DetailReCipe(recipeId: recipeId, userId: recipe['userID']),
                                            ),
                                          );
                                        },
                                        isFavorite: isFavorite,
                                        onFavoritePressed: () {
                                          FavoriteService.toggleFavorite(context, recipeId, recipe['userID']);
                                          setState(() {
                                            recipeWithUser['isFavorite'] = !isFavorite;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                            ),
                          ),
                        ),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}