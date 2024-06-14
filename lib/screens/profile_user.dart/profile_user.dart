import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/profile_user.dart/widgets/view_item.dart';
import 'package:recipe_app/screens/screens.dart';

class ProfileUser extends StatefulWidget {
  final String userId;

  const ProfileUser({super.key, required this.userId});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  User? currentUser = FirebaseAuth.instance.currentUser;
  DocumentSnapshot? userProfile;

  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    checkFollow().then((value) {
      setState(() {
        isFollowing = value;
      });
    });
  }

  Future<void> fetchUserData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      setState(() {
        userProfile = userDoc;
      });
    }
  }

  Future<bool> checkFollow() async {
    String currentUserId = currentUser!.uid;
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    List<dynamic> followedUsers = docSnapshot['followings'] ?? [];
    print(followedUsers);
    return List<String>.from(followedUsers).contains(widget.userId);
  }

  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('recipes');

  Future<List<Map<String, dynamic>>> _getData() async {
    QuerySnapshot querySnapshot =
        await _collectionRef.where('iduser', isEqualTo: currentUser!.uid).get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  Future<void> _refreshPage() async {
    await fetchUserData();
    setState(() {});
  }

  Future<void> toggleFollow(String userId) async {
    String currentUserId = currentUser!.uid;

    DocumentReference currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
    List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

    DocumentReference otherUser =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot otherUserSnapshot = await otherUser.get();
    List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

    if (followings.contains(userId)) {
      // Nếu đang theo dõi, xóa userId khỏi danh sách
      followings.remove(userId);
      followers.remove(currentUserId);
    } else {
      // Nếu chưa theo dõi, thêm userId vào danh sách
      followings.add(userId);
      followers.add(currentUserId);
    }

    await currentUserRef.update({'followings': followings});
    await otherUser.update({'followers': followers});

    setState(() {
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
          centerTitle: true,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(userProfile!['fullname']),
          centerTitle: true,
        ),
        body: RefreshIndicator(
          onRefresh: _refreshPage,
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ClipOval(
                          child: Image.network(
                            userProfile!['avatar'].isNotEmpty
                                ? userProfile!['avatar']
                                : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png', // Đường dẫn tới hình ảnh của bạn trong thư mục assets
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '@' + userProfile!['username'],
                          style: TextStyle(),
                        ),
                        SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                Text((userProfile!['followers'] as List)
                                    .length
                                    .toString()),
                                Text('Người theo dõi')
                              ],
                            ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                Text((userProfile!['followings'] as List)
                                    .length
                                    .toString()),
                                Text('Đang theo dõi')
                              ],
                            ),
                            SizedBox(width: 10),
                            Column(
                              children: [
                                Text((userProfile!['recipes'] as List)
                                    .length
                                    .toString()),
                                Text('Số công thức')
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        if (currentUser?.uid == widget.userId)
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => EditProfile()),
                              ).then((_) {
                                _refreshPage();
                              });
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  'Sửa hồ sơ',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        if (currentUser?.uid != widget.userId)
                          GestureDetector(
                            onTap: () {
                              toggleFollow(widget.userId);
                            },
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width * 0.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(isFollowing ? 'Đang theo dõi' : 'Theo dõi ngay',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 10),
                        Text(userProfile!['bio']),
                        SizedBox(height: 10),
                        TabBar(
                          tabs: [
                            Tab(text: 'Công thức của bạn'),
                            Tab(text: 'Yêu thích'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              children: [
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: FutureBuilder(
                      future: _getData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                        }
                        List<Map<String, dynamic>> data = snapshot.data ?? [];
                        return GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            List<String> likedList =
                                List<String>.from(item['liked'] ?? []);
                            return ViewItem(
                              image: item['image'] ??
                                  'https://static.vinwonders.com/production/mon-ngon-ha-dong-4.jpeg',
                              rate: item['rate'] ?? '0.0',
                              like: likedList.length.toString(),
                              date: item['date'] ?? '12/11/2002',
                              title: item['name'] ?? 'Com ngon',
                              onTap: () {
                                // Xử lý khi người dùng nhấn vào
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16),
                    child: FutureBuilder(
                      future: _getData(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Lỗi: ${snapshot.error}'));
                        }
                        List<Map<String, dynamic>> data = snapshot.data ?? [];
                        return GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: data.length,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            List<String> likedList =
                                List<String>.from(item['liked'] ?? []);
                            return ViewItem(
                              image: item['image'] ??
                                  'https://static.vinwonders.com/production/mon-ngon-ha-dong-4.jpeg',
                              rate: item['rate'] ?? '0.0',
                              like: likedList.length.toString(),
                              date: item['date'] ?? '12/11/2002',
                              title: item['name'] ?? 'Com ngon',
                              onTap: () {
                                // Xử lý khi người dùng nhấn vào
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
