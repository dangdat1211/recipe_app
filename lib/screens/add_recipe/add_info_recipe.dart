import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/screens.dart';

class AddInfoRecipe extends StatefulWidget {
  const AddInfoRecipe({super.key});

  @override
  State<AddInfoRecipe> createState() => _AddInfoRecipeState();
}

class _AddInfoRecipeState extends State<AddInfoRecipe> {
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bạn chưa đăng nhập'),
          content: Text('Vui lòng đăng nhập để tiếp tục.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SignInScreen()),
      );
              },
              child: Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: currentUser != null
          ? Text('Menu Screen')
          : Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 150,
                  child: Image.asset('assets/logo_noback.png'),
                ),
                Text('Tham gia ngay cùng cộng đồng lớn'),
                SizedBox(
                  height: 30,
                ),
                GestureDetector(
                  onTap: () {

                  },
                  child: Text('Đăng nhập ngay'),
                )
              ],
            ),
          )
    );
  }
}
