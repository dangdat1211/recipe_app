import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/screens.dart';

class ProfileUser extends StatefulWidget {
  const ProfileUser({super.key});

  @override
  State<ProfileUser> createState() => _ProfileUserState();
}

class _ProfileUserState extends State<ProfileUser> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title:Text('Trịnh Đăng Đạt'),
          centerTitle: true,
        ),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/food_intro.jpg', // Đường dẫn tới hình ảnh của bạn trong thư mục assets
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    '@user_name',
                    style: TextStyle(),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [Text('111'), Text('Đang theo dõi')],
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        children: [Text('111'), Text('Người theo dõi')],
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        children: [Text('111'), Text('Tổng lượt thích')],
                      )
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EditProfile()),
                            );
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
                  SizedBox(
                    height: 10,
                  ),
                  Text('Mô tả về cuộc đời của bạn'),
                  SizedBox(
                    height: 10,
                  ),
                  TabBar(
                    tabs: [
                      Tab(text: 'Công thức của bạn'),
                      Tab(text: 'Yêu thích'),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Container(
                    height: 800,
                    child: TabBarView(
                      children: [
                        GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: 20,
                          itemBuilder: (context, index) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(child: Text('Công thức $index')),
                            );
                          },
                        ),
                        GridView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5,
                          ),
                          itemCount: 20,
                          itemBuilder: (context, index) {
                            return Container(
                              color: Colors.grey[300],
                              child: Center(child: Text('Video $index')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
