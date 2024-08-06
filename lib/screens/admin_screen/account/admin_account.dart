import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/profile_user.dart/profile_user.dart';

class AdminAccount extends StatefulWidget {
  const AdminAccount({super.key});

  @override
  State createState() => _AdminAccountState();
}

class _AdminAccountState extends State<AdminAccount> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _sortBy = 'fullname';
  bool _isAscending = true;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalItems = 0;

  final List<String> _roles = ['Thành viên', 'Chuyên gia'];
  String _selectedRole = 'Thành viên';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedRole = _roles[_tabController.index];
          _currentPage = 1;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý tài khoản'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
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
                      _currentPage = 1;
                    });
                  },
                ),
              ),
              TabBar(
                dividerColor: Colors.transparent,
                controller: _tabController,
                tabs: [
                  Tab(text: 'Thành viên'),
                  Tab(text: 'Chuyên gia'),
                  Tab(text: 'Quản trị viên'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountList('Thành viên'),
          _buildAccountList('Chuyên gia'),
          _buildAccountList('Quản trị viên'),
        ],
      ),
    );
  }

  Widget _buildAccountList(String role) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy(_sortBy, descending: !_isAscending)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('Error: ${snapshot.error}');
          return Center(child: Text('Đã xảy ra lỗi: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có tài khoản nào'));
        }

        var filteredDocs = snapshot.data!.docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return data['fullname'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                 data['email'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredDocs.isEmpty) {
          return Center(child: Text('Không tìm thấy kết quả'));
        }

        _totalItems = filteredDocs.length;
        int totalPages = (_totalItems / _itemsPerPage).ceil();

        int startIndex = (_currentPage - 1) * _itemsPerPage;
        int endIndex = startIndex + _itemsPerPage;
        if (endIndex > _totalItems) endIndex = _totalItems;

        var paginatedDocs = filteredDocs.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: paginatedDocs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot document = paginatedDocs[index];
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(data['avatar'] ?? ''),
                      ),
                      title: Text(
                        data['fullname'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['email'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('Vai trò: ${data['role']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: data['status'] ?? false,
                            onChanged: data['role'] == 'Quản trị viên' ? null : (bool value) {
                              _showConfirmationDialog(document.id, value);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: data['role'] == 'Quản trị viên' ? null : () {
                              _showChangeRoleDialog(document.id, data['role']);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        _navigateToUserDetail(document.id);
                      },
                    ),
                  );
                },
              ),
            ),
            _buildPaginationControls(totalPages),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Sắp xếp theo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Tên'),
                leading: Radio(
                  value: 'fullname',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value.toString();
                      _currentPage = 1;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
              ListTile(
                title: Text('Email'),
                leading: Radio(
                  value: 'email',
                  groupValue: _sortBy,
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value.toString();
                      _currentPage = 1;
                      Navigator.pop(context);
                    });
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(_isAscending ? 'Tăng dần' : 'Giảm dần'),
              onPressed: () {
                setState(() {
                  _isAscending = !_isAscending;
                  _currentPage = 1;
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(String documentId, bool newValue) {
    FirebaseFirestore.instance.collection('users').doc(documentId).get().then((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data['role'] == 'Quản trị viên') {
          SnackBarCustom.showbar(context, 'Không thể thay đổi trạng thái của tài khoản quản trị viên');
          return;
        }
        
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Xác nhận'),
              content: Text('Bạn có chắc chắn muốn ${newValue ? "kích hoạt" : "vô hiệu hóa"} tài khoản này?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Xác nhận'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _toggleAccountStatus(documentId, newValue);
                  },
                ),
              ],
            );
          },
        );
      }
    });
  }

  void _toggleAccountStatus(String documentId, bool isActive) {
    FirebaseFirestore.instance.collection('users').doc(documentId).update({
      'status': isActive,
    }).then((_) {
      SnackBarCustom.showbar(context, 'Cập nhật trạng thái tài khoản thành công');
    }).catchError((error) {
      SnackBarCustom.showbar(context, 'Lỗi khi cập nhật trạng thái tài khoản: $error');
    });
  }

  void _navigateToUserDetail(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileUser(userId: userId),
      ),
    );
  }

  void _showChangeRoleDialog(String documentId, String currentRole) {
    String newRole = currentRole;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thay đổi quyền'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: _roles.map((String role) {
                  return RadioListTile<String>(
                    title: Text(role),
                    value: role,
                    groupValue: newRole,
                    onChanged: (String? value) {
                      setState(() {
                        newRole = value!;
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xác nhận'),
              onPressed: () {
                Navigator.of(context).pop();
                _changeUserRole(documentId, newRole);
              },
            ),
          ],
        );
      },
    );
  }

  void _changeUserRole(String documentId, String newRole) {
    FirebaseFirestore.instance.collection('users').doc(documentId).update({
      'role': newRole,
    }).then((_) {
      SnackBarCustom.showbar(context, 'Cập nhật quyền tài khoản thành công');
    }).catchError((error) {
      SnackBarCustom.showbar(context, 'Lỗi khi cập nhật quyền tài khoản: $error');
    });
  }
}