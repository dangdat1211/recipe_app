import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/admin_screen/method/add_method.dart';
import 'package:recipe_app/screens/admin_screen/method/edit_method.dart';

class AdminMethod extends StatefulWidget {
  const AdminMethod({super.key});

  @override
  State<AdminMethod> createState() => _AdminMethodState();
}

class _AdminMethodState extends State<AdminMethod> {
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
        title: Text('Quản lý phương pháp nấu'),
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Container(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm phương pháp...',
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
                style: TextStyle(fontSize: 14),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1; // Reset to first page when searching
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('cookingmethods')
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
                  return Center(child: Text('Không có phương pháp nấu nào.'));
                }

                var methods = snapshot.data!.docs
                    .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                    .where((method) =>
                        method['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        method['keysearch'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
                    .toList();

                _totalItems = methods.length;
                int totalPages = (_totalItems / _itemsPerPage).ceil();

                int startIndex = (_currentPage - 1) * _itemsPerPage;
                int endIndex = startIndex + _itemsPerPage;
                if (endIndex > _totalItems) endIndex = _totalItems;

                var paginatedMethods = methods.sublist(startIndex, endIndex);

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: paginatedMethods.length,
                        itemBuilder: (context, index) {
                          var data = paginatedMethods[index];
                          return ListTile(
                            leading: Image.network(data['image'],
                                width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(data['name']),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Key search: ${data['keysearch']}'),
                                Text('Ngày tạo: ${_formatDateTime(data['createAt'])}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditMethod(methodId: data['id']),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _showDeleteConfirmationDialog(data['id'], data['name']),
                                ),
                              ],
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
            MaterialPageRoute(builder: (context) => AddMethod()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('Thêm phương pháp'),
      ),
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Row(
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
        Text('Trang $_currentPage / $totalPages'),
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
                      _currentPage = 1; // Reset to first page when sorting
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
                      _currentPage = 1; // Reset to first page when sorting
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
                      _currentPage = 1; // Reset to first page when sorting
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
                      _currentPage = 1; // Reset to first page when sorting
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

  void _showDeleteConfirmationDialog(String methodId, String methodName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa'),
          content: Text('Bạn có chắc chắn muốn xóa phương pháp "$methodName"?'),
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
                _deleteMethod(methodId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteMethod(String methodId) {
    FirebaseFirestore.instance
        .collection('cookingmethods')
        .doc(methodId)
        .delete()
        .then((_) {
          SnackBarCustom.showbar(context, 'Đã xóa phương pháp nấu thành công');
    }).catchError((error) {
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi xóa phương pháp nấu');
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