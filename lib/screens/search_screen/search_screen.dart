import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];
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
      setState(() {
        searchResults = snapshot.docs;
        isLoading = false;
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchResults.clear();
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
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                searchResults.clear();
              });
            } else {
              _onSearchSubmitted(value);
            }
          },
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : searchResults.isNotEmpty
              ? Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    color: Colors.white,
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final recipe =
                            searchResults[index].data() as Map<String, dynamic>;
                        final userId = recipe['userID'] as String;

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text('Đang kết nối');
                            }

                            if (snapshot.hasError) {
                              return Text('Lỗi: ${snapshot.error}');
                            }

                            final user =
                                snapshot.data!.data() as Map<String, dynamic>;
                            print('Dữ liệu người dùng: $user');
                            if (recipe['namerecipe'].toString().toLowerCase().contains(_searchController.text.toString().toLowerCase())) {
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
                              );
                            }
                            return  Container();
                          },
                        );
                      },
                    ),
                  ),
                )
              : Center(
                  child: Text('Không có kết quả tìm kiếm'),
                ),
    );
  }
}
