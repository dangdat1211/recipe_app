import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/home_screen/following_screen.dart';
import 'package:recipe_app/screens/home_screen/propose_screen.dart';

import 'package:badges/badges.dart' as badges;
import 'package:recipe_app/screens/notify_screen/notify_screen.dart';
import 'package:recipe_app/screens/search_screen/search_screen.dart';
import 'package:recipe_app/service/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int unreadNotifications = 0;
  late Stream<QuerySnapshot> _notificationsStream;
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initNotificationsStream();
    checkAccount();
  }

  void checkAccount() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        return;
      }

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
        
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
      bool isActiveInFirestore = userData['status'] ?? true;

      if (isActiveInFirestore == false) {
        SnackBarCustom.showbar(context, 'Tài khoản của bạn đã bị vô hiệu hóa');
        AuthService().signOut();
      }
    } catch (e) {

    }
  }

  void _initNotificationsStream() {
    // final user = FirebaseAuth.instance.currentUser;
    // if (user != null) {
    _notificationsStream = FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser ?? "")
        .where('isRead', isEqualTo: false)
        .snapshots();
    //}
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SearchScreen(initialSearchTerm: _searchController.text),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: Image.asset(
            'assets/logo_noback.png',
            scale: 10,
          ),
          title: Container(
            height: 40,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 10).copyWith(left: 20),
                hintText: 'Tìm công thức cho bữa ăn của bạn',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _performSearch,
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          centerTitle: true,
          actions: [
            StreamBuilder<QuerySnapshot>(
              stream: _notificationsStream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  unreadNotifications = snapshot.data!.docs.length;
                }
                return badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  showBadge: unreadNotifications > 0,
                  badgeContent: Text(
                    unreadNotifications.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotifyScreen()),
                      );
                    },
                  ),
                );
              },
            ),
          ],
          backgroundColor: mainColor,
        ),
        body: Padding(
          padding: EdgeInsets.only(left: 16, right: 16),
          child: Column(
            children: [
              TabBar(
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(text: 'Đề xuất cho bạn'),
                  Tab(text: 'Đang theo dõi'),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    ProposeScreen(),
                    FollowingScreen(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
