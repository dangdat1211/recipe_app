import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/input_form.dart';

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

  bool _obscureText = false;

  @override
  void initState() {
    super.initState();

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        setState(() {
          _emailError =
              _emailController.text.isEmpty ? 'Email cannot be empty' : null;
        });
      }
    });

    _passwordFocusNode.addListener(() {
      if (!_passwordFocusNode.hasFocus) {
        setState(() {
          _passwordError = _passwordController.text.isEmpty
              ? 'Password cannot be empty'
              : null;
        });
      }
    });
  }

  bool remember = false;

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
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đăng nhập',
                style: TextStyle(
                  fontSize: 40,
                ),
              ),
              SizedBox(
                height: 50,
              ),
              InputForm(
                controller: _emailController, 
                focusNode: _emailFocusNode, 
                errorText: _emailError,
                label: 'Email',
              ),
              SizedBox(height: 20),
              InputForm(
                controller: _passwordController, 
                focusNode: _passwordFocusNode, 
                errorText: _passwordError,
                label: 'Password',
                isPassword: true ,
              ),
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: remember,
                        onChanged: (value) {
                          setState(() {
                            remember = !remember;
                          });
                        },
                        visualDensity:
                            VisualDensity(vertical: -4, horizontal: -4),
                        activeColor: Color(0xFFFF7622),
                      ),
                      Text('Ghi nhớ mật khẩu')
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Quên mật khẩu',
                      style: TextStyle(
                        color: Color(0xFFFF7622),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  String email = _emailController.text;
                  String password = _passwordController.text;

                  setState(() {
                    _emailError =
                        email.isEmpty ? 'Email cannot be empty' : null;
                    _passwordError =
                        password.isEmpty ? 'Password cannot be empty' : null;
                  });

                  if (_emailError == null && _passwordError == null) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => NavigateScreen()),
                    );
                  }
                },
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF7622),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Đăng nhập',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Chưa có tài khoản? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterScreen()),
                      );
                    },
                    child: Text(
                      'Đăng ký ngay',
                      style: TextStyle(
                        color: Color(0xFFFF7622),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text('Hoặc'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.only(left: 20),
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 219, 219, 219),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.facebook),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Đăng nhập với Facebook',
                        style: TextStyle(color: Colors.blue),
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: EdgeInsets.only(left: 20),
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 219, 219, 219),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.login),
                      SizedBox(
                        width: 10,
                      ),
                      Text('Đăng nhập với Google')
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
