import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/screens/home_screen/following_screen.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();

    NotificationService notificationService = NotificationService();
    notificationService.firebaseInit(context);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.apps),
            onPressed: () {
              // Handle notification icon pressed
            },
          ),
          title: Container(
            height: 40,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotifyScreen()),
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
