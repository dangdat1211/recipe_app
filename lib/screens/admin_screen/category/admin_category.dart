import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/admin_screen/category/add_category.dart';
import 'package:recipe_app/screens/admin_screen/category/edit_category.dart';

class AdminCategory extends StatefulWidget {
  const AdminCategory({super.key});

  @override
  State<AdminCategory> createState() => _AdminCategoryState();
}

class _AdminCategoryState extends State<AdminCategory> {
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý danh mục'),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: _showSortDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm danh mục...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .orderBy(_sortBy, descending: !_sortAscending)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Không có danh mục nào.'));
                }

                var categories = snapshot.data!.docs
                    .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                    .where((category) =>
                        category['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        category['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                _totalItems = categories.length;
                int totalPages = (_totalItems / _itemsPerPage).ceil();

                int startIndex = (_currentPage - 1) * _itemsPerPage;
                int endIndex = startIndex + _itemsPerPage;
                if (endIndex > _totalItems) endIndex = _totalItems;

                var paginatedCategories = categories.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: paginatedCategories.length,
                        itemBuilder: (context, index) {
                          var data = paginatedCategories[index];
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  data['image'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              title: Text(
                                data['name'],
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mô tả: ${data['description']}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Ngày tạo: ${_formatDateTime(data['createAt'])}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditCategory(categoryId: data['id']),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _showDeleteConfirmationDialog(data['id'], data['name']),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildPaginationControls(totalPages),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddCategory()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Thêm danh mục'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
          ),
          Text(
            'Trang $_currentPage / $totalPages',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sắp xếp theo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tên (A-Z)'),
                leading: Radio<String>(
                  value: 'name_asc',
                  groupValue: '${_sortBy}_${_sortAscending ? 'asc' : 'desc'}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'name';
                      _sortAscending = true;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Tên (Z-A)'),
                leading: Radio<String>(
                  value: 'name_desc',
                  groupValue: '${_sortBy}_${_sortAscending ? 'asc' : 'desc'}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'name';
                      _sortAscending = false;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Mới nhất'),
                leading: Radio<String>(
                  value: 'createAt_desc',
                  groupValue: '${_sortBy}_${_sortAscending ? 'asc' : 'desc'}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'createAt';
                      _sortAscending = false;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: Text('Cũ nhất'),
                leading: Radio<String>(
                  value: 'createAt_asc',
                  groupValue: '${_sortBy}_${_sortAscending ? 'asc' : 'desc'}',
                  onChanged: (String? value) {
                    setState(() {
                      _sortBy = 'createAt';
                      _sortAscending = true;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(String categoryId, String categoryName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa danh mục "$categoryName"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xóa'),
              onPressed: () {
                _deleteCategory(categoryId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteCategory(String categoryId) {
    FirebaseFirestore.instance
        .collection('categories')
        .doc(categoryId)
        .delete()
        .then((_) {
      SnackBarCustom.showbar(context, 'Đã xóa danh mục thành công');
    }).catchError((error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi xóa danh mục');
    });
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return 'Không có thông tin';
    }
    if (dateTime is Timestamp) {
      DateTime dt = dateTime.toDate();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute}';
    }
    if (dateTime is DateTime) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
    }
    return 'Định dạng không hợp lệ';
  }
}