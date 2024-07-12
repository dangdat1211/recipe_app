import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/add_recipe/edit_recipe.dart';
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

  void _handlePopupMenuSelection(String value, String recipeId) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditRecipeScreen(
                    recipeId: recipeId,
                  )),
        );
        break;
      case 'delete':
        bool? confirmDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Xác nhận xóa'),
            content: Text('Bạn có chắc chắn muốn xóa công thức này không?'),
            actions: <Widget>[
              TextButton(
                child: Text('Hủy'),
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
              ),
              TextButton(
                child: Text('Xóa'),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
            ],
          );
        },
      );

      // Nếu người dùng xác nhận xóa, thực hiện việc xóa
      if (confirmDelete == true) {
        await _deleteRecipe(recipeId);
      }
      break;
      case 'hide':
        await _hideRecipe(recipeId);
        break;
      case 'show':
        await _showRecipe(recipeId);
        break;
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      // Bắt đầu một batch operation
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // Xóa công thức
      batch.delete(
          FirebaseFirestore.instance.collection('recipes').doc(recipeId));

      // Xóa tất cả đánh giá liên quan
      QuerySnapshot rateSnapshots = await FirebaseFirestore.instance
          .collection('rates')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in rateSnapshots.docs) {
        batch.delete(doc.reference);
      }

      // Xóa tất cả bình luận liên quan
      QuerySnapshot commentSnapshots = await FirebaseFirestore.instance
          .collection('comments')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in commentSnapshots.docs) {
        batch.delete(doc.reference);
      }

      // Xóa tất cả yêu thích liên quan
      QuerySnapshot favoriteSnapshots = await FirebaseFirestore.instance
          .collection('favorites')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in favoriteSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot stepSnapshots = await FirebaseFirestore.instance
          .collection('steps')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in stepSnapshots.docs) {
        batch.delete(doc.reference);
      }

      // Thực hiện batch operation
      await batch.commit();

      // Hiển thị thông báo xóa thành công
      SnackBarCustom.showbar(context, 'Xóa thành công');

      // Cập nhật UI nếu cần
      setState(() {
        // Xóa công thức khỏi danh sách hiển thị (nếu có)
      });
    } catch (e) {
      print('Lỗi khi xóa công thức và dữ liệu liên quan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Có lỗi xảy ra khi xóa công thức và dữ liệu liên quan')),
      );
    }
  }

  Future<void> _hideRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': true,
      });
      // Hiển thị thông báo ẩn thành công
      SnackBarCustom.showbar(context, 'Công thức đã được ẩn');
      // Cập nhật UI nếu cần
      setState(() {
        // Ẩn công thức khỏi danh sách hiển thị (nếu có)
      });
    } catch (e) {
      print('Lỗi khi ẩn công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi ẩn công thức')),
      );
    }
  }

  Future<void> _showRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': false,
      });
      // Hiển thị thông báo ẩn thành công
      SnackBarCustom.showbar(context, 'Công thức đã được hiện');
      // Cập nhật UI nếu cần
      setState(() {
        // Ẩn công thức khỏi danh sách hiển thị (nếu có)
      });
    } catch (e) {
      print('Lỗi khi ẩn công thức: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi ẩn công thức')),
      );
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
                      color: Colors.black, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe['description'],
                      overflow:
                          TextOverflow.ellipsis, // Thêm dấu ... nếu quá dài
                      maxLines: 1,
                    ),
                    Text(
                      'Trạng thái: ${recipe['status']}',
                      style: TextStyle(
                        color: getStatusColor(recipe['status']),
                      ),
                    ),
                    Text(
                      recipe['hidden'] ? 'Đang ẩn' : '',
                      style: TextStyle(
                        color: Colors.purple,
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
                    PopupMenuItem<String>(
                      value: recipe['hidden'] ? 'show' : 'hide',
                      child: Text(recipe['hidden'] ? 'Hiện' : 'Ẩn'),
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
