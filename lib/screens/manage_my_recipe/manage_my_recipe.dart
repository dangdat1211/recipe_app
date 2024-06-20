import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';

class ManageMyRecipe extends StatefulWidget {
  const ManageMyRecipe({super.key});

  @override
  State<ManageMyRecipe> createState() => _ManageMyRecipeState();
}

class _ManageMyRecipeState extends State<ManageMyRecipe>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String sortOption = 'Newest';

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePopupMenuSelection(String value, String recipeId) {
    switch (value) {
      case 'edit':
        // Navigate to edit recipe screen
        break;
      case 'delete':
        // Delete recipe from Firestore
        break;
      case 'hide':
        // Hide recipe from the list
        break;
    }
  }

  Widget buildRecipeList(String status) {
    Query recipesQuery = FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: currentUser!.uid);

    if (status.isNotEmpty) {
      recipesQuery = recipesQuery.where('status', isEqualTo: status);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: recipesQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Something went wrong');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text("Loading");
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var recipe =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            var recipeId = snapshot.data!.docs[index].id;
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailReCipe(
                        recipeId: recipeId, userId: currentUser!.uid),
                  ),
                );
              },
              child: ListTile(
                leading: Container(
                  width: 80,
                  height: 80,
                  child: Image.network(
                    recipe['image'],
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  recipe['namerecipe'],
                  overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
                  maxLines: 1,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['description'],
                      overflow: TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
                      maxLines: 1,
                    ),
                    Text(
                      'Status: ${recipe['status']}',
                      style: TextStyle(
                        color: getStatusColor(recipe['status']),
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) =>
                      _handlePopupMenuSelection(value, recipeId),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Sửa'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('Xóa'),
                    ),
                    const PopupMenuItem<String>(
                      value: 'hide',
                      child: Text('Ẩn'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý công thức'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đợi phê duyệt'),
            Tab(text: 'Đã được phê duyệt'),
            Tab(text: 'Bị từ chối'),
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
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to search screen
                    },
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          width: 1,
                          color: Colors.grey,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8.0),
                          Text('Search...'),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                DropdownButton<String>(
                  value: sortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      sortOption = newValue!;
                    });
                  },
                  items: <String>[
                    'Newest',
                    'Oldest',
                    'Most Popular',
                    'Least Popular'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
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
                buildRecipeList('Bị từ chối'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
