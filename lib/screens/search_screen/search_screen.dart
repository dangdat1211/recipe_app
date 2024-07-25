import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/search_screen/search_user_screen.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/service/rate_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class SearchScreen extends StatefulWidget {
  final String? initialSearchTerm;
  const SearchScreen({super.key, this.initialSearchTerm});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResultsWithUserData = [];
  bool isLoading = false;
  String currentSortOption = 'Mới nhất';
  bool _hasSearchText = false;

  User? currentUser = FirebaseAuth.instance.currentUser;

  Map<String, List<String>> selectedFilters = {
    'difficulty': [],
    'time': [],
    'method': [],
  };

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialSearchTerm);
    _searchController.addListener(_onSearchTextChanged);
    if (widget.initialSearchTerm != null) {
      _onSearchSubmitted(widget.initialSearchTerm!);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged() {
  setState(() {
    _hasSearchText = _searchController.text.isNotEmpty;
  });
}

  void _onSearchSubmitted(String query) async {
    if (query.isNotEmpty) {
      setState(() {
        isLoading = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .where('status', isEqualTo: 'Đã được phê duyệt')
          .get();

      var filteredDocs = snapshot.docs.where((doc) {
        var data = doc.data() as Map<String, dynamic>;
        return data['hidden'] == false;
      }).toList();

      searchResultsWithUserData = [];

      for (var recipeDoc in filteredDocs) {
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
          var ratingData = await RateService.fetchAverageRating(recipeId);

          bool nameMatch = recipeData['namerecipe']
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase());

          bool ingredientMatch = false;
          if (recipeData['ingredients'] != null &&
              recipeData['ingredients'] is List) {
            ingredientMatch = (recipeData['ingredients'] as List).any(
                (ingredient) => ingredient
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()));
          }

          bool difficultyMatch = true;
          if (selectedFilters['difficulty']!.isNotEmpty) {
            difficultyMatch = selectedFilters['difficulty']!.contains(recipeData['level']);
          }

          bool methodMatch = true;
          if (selectedFilters['method']!.isNotEmpty) {
            methodMatch = selectedFilters['method']!.any((method) =>
                recipeData['namerecipe']
                    .toString()
                    .toLowerCase()
                    .contains(method.toLowerCase()));
          }

          bool timeMatch = true;
          if (selectedFilters['time']!.isNotEmpty) {
            int recipeCookingTime = int.tryParse(recipeData['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            print(recipeCookingTime);
            timeMatch = selectedFilters['time']!.any((timeFilter) {
              if (timeFilter == '< 30 phút') {
                return recipeCookingTime < 30;
              } else if (timeFilter == '30-60 phút') {
                return recipeCookingTime >= 30 && recipeCookingTime <= 60;
              } else if (timeFilter == '> 60 phút') {
                return recipeCookingTime > 60;
              }
              return false;
            });
          }

          if ((nameMatch || ingredientMatch) && difficultyMatch && methodMatch && timeMatch) {
            searchResultsWithUserData.add({
              'recipe': recipeData,
              'user': userData,
              'isFavorite': isFavorite,
              'recipeId': recipeId,
              'avgRating': ratingData['avgRating'],
              
            });
          }
        }
      }

      // Sắp xếp kết quả
      searchResultsWithUserData.sort((a, b) {
        switch (currentSortOption) {
          case 'Đánh giá cao nhất':
            final ratingA = a['avgRating'] as num? ?? 0;
            final ratingB = b['avgRating'] as num? ?? 0;
            return ratingB.compareTo(ratingA);
          case 'Yêu thích nhiều nhất':
            return (b['recipe']['likes'] as List).length.compareTo((a['recipe']['likes'] as List).length);
          case 'Mới nhất':
          default:
            return (b['recipe']['createAt'] as Timestamp).compareTo(a['recipe']['createAt'] as Timestamp);
        }
      });

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

  void _showFilterDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: Text('Lọc và Sắp xếp', style: TextStyle(fontWeight: FontWeight.bold)),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildSortingSection(setState),
                  
                  _buildFilterSection('Độ khó', 'difficulty', ['Dễ', 'Trung bình', 'Khó'], setState),
                  _buildFilterSection('Thời gian', 'time', ['< 30 phút', '30-60 phút', '> 60 phút'], setState),
                  _buildFilterSection('Phương pháp', 'method', ['Rán', 'Xào', 'Nướng', 'Hấp'], setState),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Hủy', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text('Áp dụng'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _applyFiltersAndSort();
                },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _buildSortingSection(StateSetter setState) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: DropdownButton<String>(
          value: currentSortOption,
          onChanged: (String? newValue) {
            setState(() => currentSortOption = newValue!);
          },
          items: ['Mới nhất', 'Đánh giá cao nhất', 'Yêu thích nhiều nhất']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
          isExpanded: true,
          underline: SizedBox(),
        ),
      ),
    ],
  );
}

Widget _buildFilterSection(String title, String filterType, List<String> options, StateSetter setState) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: options.map((option) {
          bool isSelected = selectedFilters[filterType]!.contains(option);
          return FilterChip(
            showCheckmark: false,
            label: Text(option),
            selected: isSelected,
            onSelected: (bool selected) {
              setState(() {
                if (selected) {
                  selectedFilters[filterType]!.add(option);
                } else {
                  selectedFilters[filterType]!.remove(option);
                }
              });
            },
            backgroundColor: Colors.grey[200],
            selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
          );
        }).toList(),
      ),
      SizedBox(height: 12),
    ],
  );
}

  void _applyFiltersAndSort() {
    _onSearchSubmitted(_searchController.text);
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
      suffixIcon: _hasSearchText
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            )
          : null,
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
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
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
                        padding:  EdgeInsets.only(left: MediaQuery.of(context).size.width * 0.048, right: MediaQuery.of(context).size.width * 0.045),
                        child: Container(
                          child: ListView.builder(
                            itemCount: searchResultsWithUserData.length,
                            itemBuilder: (context, index) {
                              final recipeWithUser = searchResultsWithUserData[index];
                              final recipe = recipeWithUser['recipe'];
                              final user = recipeWithUser['user'];
                              final isFavorite = recipeWithUser['isFavorite'];
                              final recipeId = recipeWithUser['recipeId'];
                              final avgRating = recipeWithUser['avgRating'];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ItemRecipe(
                                  name: recipe['namerecipe'],
                                  star: avgRating.toStringAsFixed(1),
                                  favorite: recipe['likes'].length.toString(),
                                  avatar: user['avatar'],
                                  fullname: user['fullname'],
                                  image: recipe['image'],
                                  ontap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DetailReCipe(recipeId: recipeId, userId: recipe['userID'],),
                                      ),
                                    );
                                  },
                                  isFavorite: isFavorite,
                                  onFavoritePressed: () {
                                    if (currentUser != null) {
                                      FavoriteService.toggleFavorite(context, recipeId, recipe['userID']);
                                    }
                                    else {
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
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchUserScreen(),
                          ),
                        );
                      },
                      child: Text('Tìm kiếm người dùng'),
                    ),
                    Center(
                      child: Text('Không có kết quả tìm kiếm'),
                    ),
                  ],
                ),
    );
  }
}