import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/screens/admin_screen/recipe/recipe_review.dart';

class AdminRecipe extends StatefulWidget {
  const AdminRecipe({super.key});

  @override
  State<AdminRecipe> createState() => _AdminRecipeState();
}

class _AdminRecipeState extends State<AdminRecipe>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đợi phê duyệt':
        return Colors.orange;
      case 'Đã được phê duyệt':
        return Colors.green;
      case 'Bị từ chối':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  Widget buildRecipeList(String status) {
    Query recipesQuery = FirebaseFirestore.instance.collection('recipes');

    if (status.isNotEmpty) {
      recipesQuery = recipesQuery.where('status', isEqualTo: status);
    }

    if (_sortBy == 'name') {
      recipesQuery =
          recipesQuery.orderBy('namerecipe', descending: !_sortAscending);
    } else if (_sortBy == 'time') {
      recipesQuery =
          recipesQuery.orderBy('createAt', descending: !_sortAscending);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: recipesQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Đã xảy ra lỗi');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        var recipes = snapshot.data!.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .where((recipe) => recipe['namerecipe']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        if (recipes.isEmpty) {
          return Center(child: Text('Không có công thức nào'));
        }

        return ListView.builder(
          itemCount: recipes.length,
          itemBuilder: (context, index) {
            var recipe = recipes[index];
            var recipeId = snapshot.data!.docs[index].id;
            return ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => AdminRecipeReview(
                          recipeId: recipeId, userId: currentUser!.uid)),
                );
              },
              leading: Container(
                width: 60,
                height: 60,
                child: Image.network(
                  recipe['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.error);
                  },
                ),
              ),
              title: Text(
                recipe['namerecipe'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recipe['description'] ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(
                    'Trạng thái: ${recipe['status']}',
                    style: TextStyle(
                      color: getStatusColor(recipe['status']),
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.check, color: Colors.green),
                    onPressed: () => approveRecipe(recipeId),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () => rejectRecipe(recipeId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void approveRecipe(String recipeId) {
    FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .update({'status': 'Đã được phê duyệt'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Công thức đã được phê duyệt')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi phê duyệt công thức')),
      );
    });
  }

  void rejectRecipe(String recipeId) {
    FirebaseFirestore.instance
        .collection('recipes')
        .doc(recipeId)
        .update({'status': 'Bị từ chối'}).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Công thức đã bị từ chối')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi từ chối công thức')),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý công thức'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đợi phê duyệt'),
            Tab(text: 'Đã phê duyệt'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên...',
                      prefixIcon:
                          Icon(Icons.search, size: 20), // Giảm kích thước icon
                      contentPadding: EdgeInsets.symmetric(
                          vertical: 0, horizontal: 10), // Giảm padding
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(20), // Bo tròn góc nhiều hơn
                        borderSide: BorderSide(
                            width: 1,
                            color: Colors.grey), // Đường viền mỏng hơn
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            width: 1, color: Theme.of(context).primaryColor),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort),
                  onSelected: (String value) {
                    setState(() {
                      if (_sortBy == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                        _sortAscending = true;
                      }
                    });
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'name',
                      child: Text('Sắp xếp theo tên'),
                    ),
                    PopupMenuItem<String>(
                      value: 'time',
                      child: Text('Sắp xếp theo thời gian'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildRecipeList(''),
                buildRecipeList('Đợi phê duyệt'),
                buildRecipeList('Đã được phê duyệt'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
