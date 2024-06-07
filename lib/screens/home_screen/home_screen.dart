import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                // Handle app icon pressed
              },
            ),
          ],
          backgroundColor: Color(0xFFFF7622),
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
              SizedBox(height: 10,),
              Expanded(
                child: TabBarView(
                  children: [
                    ProposeScreen(),
                    Center(child: Text('Nội dung Trang 2')),
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
