import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();

    // Lắng nghe sự thay đổi tiêu điểm của ô nhập email
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        setState(() {
          _emailError = _emailController.text.isEmpty ? 'Email cannot be empty' : null;
        });
      }
    });

    // Lắng nghe sự thay đổi tiêu điểm của ô nhập password
    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          _passwordError = _passwordController.text.isEmpty ? 'Password cannot be empty' : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                errorText: _emailError,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                errorText: _passwordError,
              ),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Xử lý sự kiện đăng nhập tại đây
                String email = _emailController.text;
                String password = _passwordController.text;

                setState(() {
                  _emailError = email.isEmpty ? 'Email cannot be empty' : null;
                  _passwordError = password.isEmpty ? 'Password cannot be empty' : null;
                });

                if (_emailError == null && _passwordError == null) {
                  // Ví dụ: In thông tin đăng nhập ra console
                  print('Email: $email');
                  print('Password: $password');
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

