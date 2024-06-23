import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRecipe extends StatefulWidget {
  const AdminRecipe({super.key});

  @override
  State<AdminRecipe> createState() => _AdminRecipeState();
}

class _AdminRecipeState extends State<AdminRecipe> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
      default:
        return Colors.black;
    }
  }

  Widget buildRecipeList(String status) {
  Query recipesQuery = FirebaseFirestore.instance.collection('recipes');

  if (status.isNotEmpty) {
    recipesQuery = recipesQuery.where('status', isEqualTo: status);
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

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          var recipe = snapshot.data!.docs[index].data() as Map<String, dynamic>;
          var recipeId = snapshot.data!.docs[index].id;
          return ListTile(
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
                  onPressed: () {
                    // Xử lý khi nút tích được nhấn
                    approveRecipe(recipeId);
                  },
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: () {
                    // Xử lý khi nút x được nhấn
                    rejectRecipe(recipeId);
                  },
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
  FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({
    'status': 'Đã được phê duyệt'
  }).then((_) {
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
  FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({
    'status': 'Bị từ chối'
  }).then((_) {
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
      body: TabBarView(
        controller: _tabController,
        children: [
          buildRecipeList(''),
          buildRecipeList('Đợi phê duyệt'),
          buildRecipeList('Đã được phê duyệt'),
        ],
      ),
    );
  }
}