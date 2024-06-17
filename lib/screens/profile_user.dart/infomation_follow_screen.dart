import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;

  const FollowersFollowingScreen({Key? key, required this.userId})
      : super(key: key);

  @override
  _FollowersFollowingScreenState createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? currentUser = FirebaseAuth.instance.currentUser;

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

  Future<List<Map<String, dynamic>>> fetchUsers(String field) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    List<dynamic> userIds = userDoc[field] ?? [];

    List<Map<String, dynamic>> users = [];
    for (String userId in userIds) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userSnapshot.exists) {
        Map<String, dynamic> userData =
            userSnapshot.data() as Map<String, dynamic>;
        userData['id'] = userSnapshot.id;
        users.add(userData);
      }
    }
    return users;
  }

  Future<bool> isFollowing(String userId) async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      List<dynamic> followings = userDoc['followings'] ?? [];
      return followings.contains(userId);
    }
    return false;
  }

  Future<void> toggleFollow(String userId) async {
    if (currentUser != null) {
      DocumentReference currentUserRef =
          FirebaseFirestore.instance.collection('users').doc(currentUser!.uid);
      DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
      List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

      DocumentReference otherUserRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      DocumentSnapshot otherUserSnapshot = await otherUserRef.get();
      List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

      if (followings.contains(userId)) {
        followings.remove(userId);
        followers.remove(currentUser!.uid);
      } else {
        followings.add(userId);
        followers.add(currentUser!.uid);
      }

      await currentUserRef.update({'followings': followings});
      await otherUserRef.update({'followers': followers});

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Followers & Following'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildUserList('followers'),
          buildUserList('followings'),
        ],
      ),
    );
  }

  Widget buildUserList(String field) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchUsers(field),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        List<Map<String, dynamic>> users = snapshot.data ?? [];
        return users.isEmpty
            ? Center(child: Text('No users found'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> user = users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(user['avatar']),
                    ),
                    title: Text(user['fullname']),
                    subtitle: Text(user['bio']),
                    trailing: FutureBuilder<bool>(
                      future: isFollowing(user['id']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container();
                        }
                        bool isFollowing = snapshot.data ?? false;
                        return ElevatedButton(
                          onPressed: () => toggleFollow(user['id']),
                          child: Text(isFollowing ? 'Unfollow' : 'Follow'),
                        );
                      },
                    ),
                  );
                },
              );
      },
    );
  }
}
