import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/constants/colors.dart';

class UserRanking extends StatefulWidget {
  const UserRanking({Key? key}) : super(key: key);

  @override
  State<UserRanking> createState() => _UserRankingState();
}

class _UserRankingState extends State<UserRanking> {
  String dropdownValue = 'Người theo dõi';
  List<DocumentSnapshot> users = [];
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    fetchUsers();

    // Lắng nghe các thay đổi trong thời gian thực
    FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        users = snapshot.docs;
        sortUsers();
      });
    });
  }

  Future<void> fetchUsers() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('users').get();
    setState(() {
      users = snapshot.docs;
      sortUsers();
    });
  }

  void sortUsers() {
    if (dropdownValue == 'Người theo dõi') {
      users.sort((a, b) {
        final aFollowers = (a.data() as Map<String, dynamic>?)?['followers'];
        final bFollowers = (b.data() as Map<String, dynamic>?)?['followers'];
        final aCount = aFollowers is List ? aFollowers.length : 0;
        final bCount = bFollowers is List ? bFollowers.length : 0;
        return bCount.compareTo(aCount);
      });
    } else {
      users.sort((a, b) {
        final aRecipes = (a.data() as Map<String, dynamic>?)?['recipes'];
        final bRecipes = (b.data() as Map<String, dynamic>?)?['recipes'];
        final aCount = aRecipes is List ? aRecipes.length : 0;
        final bCount = bRecipes is List ? bRecipes.length : 0;
        return bCount.compareTo(aCount);
      });
    }
    users = users.take(10).toList(); // Chỉ lấy top 10
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          _buildDropdown(),
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: dropdownValue,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: Colors.teal),
          style: TextStyle(color: Colors.teal, fontSize: 16),
          onChanged: (String? newValue) {
            setState(() {
              dropdownValue = newValue!;
              sortUsers();
            });
          },
          items: <String>['Người theo dõi', 'Công thức']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        Map<String, dynamic> userData =
            users[index].data() as Map<String, dynamic>;
        return _buildUserCard(userData, index);
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, int index) {
    String userId = users[index].id;
    bool isFollowing = currentUserId != null &&
        (userData['followers'] as List?)?.contains(currentUserId) == true;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: NetworkImage(userData['avatar'] ?? ''),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getRankColor(index),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          userData['fullname'] ?? '',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '@${userData['username'] ?? ''}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 4),
            Text(
              '${(userData['followers'] as List?)?.length ?? 0} người theo dõi',
              style: TextStyle(color: Colors.teal),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            _toggleFollow(userId, isFollowing);
          },
          child: Text(
            isFollowing ? 'Đang theo dõi' : 'Theo dõi',
            style: TextStyle(
              color: isFollowing ? Colors.grey[600] : Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFollowing ? Colors.grey[200] : mainColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleFollow( String targetUserId, bool isCurrentlyFollowing) async {
    if (currentUserId == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final currentUserDoc =
          FirebaseFirestore.instance.collection('users').doc(currentUserId);
      final targetUserDoc =
          FirebaseFirestore.instance.collection('users').doc(targetUserId);

      if (isCurrentlyFollowing) {
        // Hủy theo dõi
        batch.update(currentUserDoc, {
          'following': FieldValue.arrayRemove([targetUserId])
        });
        batch.update(targetUserDoc, {
          'followers': FieldValue.arrayRemove([currentUserId])
        });
      } else {
        // Theo dõi
        batch.update(currentUserDoc, {
          'following': FieldValue.arrayUnion([targetUserId])
        });
        batch.update(targetUserDoc, {
          'followers': FieldValue.arrayUnion([currentUserId])
        });
      }

      await batch.commit();

      // Cập nhật UI
      setState(() {
        // int index = users.indexWhere((user) => user.id == targetUserId);
        // if (index != -1) {
        //   Map<String, dynamic> userData =
        //       users[index].data() as Map<String, dynamic>;
        //   List followers = userData['followers'] ?? [];
        //   if (isCurrentlyFollowing) {
        //     followers.remove(currentUserId);
        //   } else {
        //     followers.add(currentUserId);
        //   }
        //   userData['followers'] = followers;
        //   users[index] = users[index].copyWith(data: () => userData);
        // }
      });
    } catch (e) {
      print('Error toggling follow: $e');
      // Có thể thêm xử lý lỗi ở đây, ví dụ: hiển thị thông báo cho người dùng
    }
  }

  Color _getRankColor(int index) {
    if (index == 0) return Colors.amber;
    if (index == 1) return Colors.grey[400]!;
    if (index == 2) return Colors.brown[300]!;
    return Colors.teal;
  }
}
