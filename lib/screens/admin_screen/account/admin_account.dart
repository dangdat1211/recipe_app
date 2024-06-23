import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAccount extends StatefulWidget {
  const AdminAccount({super.key});

  @override
  State createState() => _AdminAccountState();
}

class _AdminAccountState extends State<AdminAccount> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Đang hoạt động'),
            Tab(text: 'Vô hiệu hóa'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAccountList(true),
          _buildAccountList(false),
        ],
      ),
    );
  }

  Widget _buildAccountList(bool isActive) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isActive', isEqualTo: isActive)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Đã xảy ra lỗi'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có tài khoản nào'));
        }

        return ListView(
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data = document.data() as Map<String, dynamic>;
            print('object');
            print(data);
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(data['avatar'] ?? ''),
              ),
              title: Text(data['fullname'] ?? ''),
              subtitle: Text(data['email'] ?? ''),
              trailing: Switch(
                value: data['isActive'] == 'true',
                onChanged: (bool value) {
                  _toggleAccountStatus(document.id, value);
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _toggleAccountStatus(String documentId, bool isActive) {
    FirebaseFirestore.instance.collection('users').doc(documentId).update({
      'isActive': isActive.toString(),
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật trạng thái tài khoản thành công')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật trạng thái tài khoản')),
      );
    });
  }
}