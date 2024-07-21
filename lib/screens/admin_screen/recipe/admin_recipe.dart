import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/admin_screen/recipe/recipe_review.dart';
import 'package:recipe_app/service/notification_service.dart';

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
  int _itemsPerPage = 10;
  List<int> _currentPages = [1, 1, 1]; // Một trang hiện tại cho mỗi tab

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

  Widget buildRecipeList(String status, int tabIndex) {
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

        int totalPages = (recipes.length / _itemsPerPage).ceil();
        int startIndex = (_currentPages[tabIndex] - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > recipes.length) endIndex = recipes.length;

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: endIndex - startIndex,
                itemBuilder: (context, index) {
                  var recipe = recipes[startIndex + index];
                  var recipeId = snapshot.data!.docs[startIndex + index].id;
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
                    trailing: recipe['status'] != 'Đã được phê duyệt'
                        ? Row(
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
                          )
                        : null
                  );
                },
              ),
            ),
            buildPaginationControls(totalPages, tabIndex),
          ],
        );
      },
    );
  }

  Widget buildPaginationControls(int totalPages, int tabIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: _currentPages[tabIndex] > 1
              ? () {
                  setState(() {
                    _currentPages[tabIndex]--;
                  });
                }
              : null,
        ),
        Text('Trang ${_currentPages[tabIndex]} / $totalPages'),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: _currentPages[tabIndex] < totalPages
              ? () {
                  setState(() {
                    _currentPages[tabIndex]++;
                  });
                }
              : null,
        ),
      ],
    );
  }

  void approveRecipe(String recipeId) async {
    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
      String recipeOwnerId = recipeDoc.get('userID');
      String recipeName = recipeDoc.get('namerecipe');
      

      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({'status': 'Đã được phê duyệt'});

      // Gửi thông báo cho chủ công thức
      await NotificationService().createNotification(
        content: 'Công thức "$recipeName" của bạn đã được phê duyệt',
        fromUser: currentUser!.uid,
        userId: recipeOwnerId,
        recipeId: recipeId,
        screen: 'recipe'
      );

      DocumentSnapshot ownerDoc = await FirebaseFirestore.instance.collection('users').doc(recipeOwnerId).get();
      String? ownerFcmToken = ownerDoc.get('FCM');
      String? recipeOwnerName = ownerDoc.get('fullname');
      
      if (ownerFcmToken != null && ownerFcmToken.isNotEmpty) {
        await NotificationService.sendNotification(
          ownerFcmToken,
          'Công thức được phê duyệt',
          'Công thức "$recipeName" của bạn đã được phê duyệt',
          data: {'screen': 'recipe', 'recipeId': recipeId, 'userId': currentUser!.uid}
        );
      }

      // Gửi thông báo cho những người đang follow chủ công thức
      QuerySnapshot usersDocs = await FirebaseFirestore.instance
          .collection('users')
          .where('following', arrayContains: recipeOwnerId)
          .get();

      for (var userDoc in usersDocs.docs) {
        String followerId = userDoc.id;
        
        await NotificationService().createNotification(
          content: 'vừa đăng một công thức mới: "$recipeName"',
          fromUser: recipeOwnerId,
          userId: followerId,
          recipeId: recipeId,
          screen: 'recipe'
        );

        String? followerFcmToken = userDoc.get('FCM');
        
        if (followerFcmToken != null && followerFcmToken.isNotEmpty) {
          await NotificationService.sendNotification(
            followerFcmToken,
            'Công thức mới',
            '$recipeOwnerName vừa đăng một công thức mới: "$recipeName"',
            data: {'screen': 'recipe', 'recipeId': recipeId, 'userId': recipeOwnerId}
          );
        }
      }
      SnackBarCustom.showbar(context, 'Công thức đã được phê duyệt');

    } catch (error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi phê duyệt công thức');
    }
  }

  void rejectRecipe(String recipeId) async {
    try {
      DocumentSnapshot recipeDoc = await FirebaseFirestore.instance.collection('recipes').doc(recipeId).get();
      String recipeOwnerId = recipeDoc.get('userID');
      String recipeName = recipeDoc.get('namerecipe');

      await FirebaseFirestore.instance.collection('recipes').doc(recipeId).update({'status': 'Bị từ chối'});

      // Gửi thông báo cho chủ công thức
      await NotificationService().createNotification(
        content: 'Công thức "$recipeName" của bạn đã bị từ chối',
        fromUser: currentUser!.uid,
        userId: recipeOwnerId,
        recipeId: recipeId,
        screen: 'recipe'
      );

      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(recipeOwnerId).get();
      String? ownerFcmToken = userDoc.get('FCM');
      
      if (ownerFcmToken != null && ownerFcmToken.isNotEmpty) {
        await NotificationService.sendNotification(
          ownerFcmToken,
          'Công thức bị từ chối',
          'Công thức "$recipeName" của bạn đã bị từ chối',
          data: {'screen': 'recipe', 'recipeId': recipeId, 'userId': currentUser!.uid}
        );
      }
      SnackBarCustom.showbar(context, 'Công thức đã bị từ chối');

    } catch (error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi từ chối công thức');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kiểm duyệt công thức'),
        centerTitle: true,
        bottom: TabBar(
          dividerColor: Colors.transparent,
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
                      prefixIcon: Icon(Icons.search, size: 20),
                      contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(width: 1, color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(width: 1, color: Theme.of(context).primaryColor),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _currentPages = [1, 1, 1]; // Reset all pages when searching
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
                      _currentPages = [1, 1, 1]; // Reset all pages when sorting
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                buildRecipeList('', 0),
                buildRecipeList('Đợi phê duyệt', 1),
                buildRecipeList('Đã được phê duyệt', 2),
              ],
            ),
          ),
        ],
      ),
    );
  }
}