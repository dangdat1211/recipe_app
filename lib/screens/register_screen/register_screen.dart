import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
    
  final FocusNode _usernameFocusNode = FocusNode();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _fullnameFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  String? _usernameError;
  String? _emailError;
  String? _fullnameError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        setState(() {
          _usernameError = _usernameController.text.isEmpty
              ? 'username cannot be empty'
              : null;
        });
      }
    });

    _fullnameFocusNode.addListener(() {
      if (!_fullnameFocusNode.hasFocus) {
        setState(() {
          _fullnameError = _fullnameController.text.isEmpty
              ? 'fullname cannot be empty'
              : null;
        });
      }
    });

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

    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        setState(() {
          _confirmPasswordError = _confirmPasswordController.text.isEmpty
              ? 'confirmPassword cannot be empty'
              : null;
          if (_passwordController.value != null ) {
            if (_passwordController.value != _confirmPasswordController.value) {
              _confirmPasswordError = "ccc";
            }
            else {
              _confirmPasswordError = null;
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đăng ký'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Đăng ký',
                style: TextStyle(
                  fontSize: 40,
                ),
              ),
              SizedBox(height: 10,),
              TextField(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Usename',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                    color: Color(0xFFFF7622),
                  )),
                  errorText: _usernameError,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                focusNode: _emailFocusNode,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                    color: Color(0xFFFF7622),
                  )),
                  errorText: _emailError,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _fullnameController,
                focusNode: _fullnameFocusNode,
                decoration: InputDecoration(
                  labelText: 'Fullname',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                    color: Color(0xFFFF7622),
                  )),
                  errorText: _fullnameError,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                    color: Color(0xFFFF7622),
                  )),
                  errorText: _passwordError,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(
                    color: Color(0xFFFF7622),
                  )),
                  errorText: _confirmPasswordError,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  labelStyle: TextStyle(fontSize: 16),
                  errorStyle: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: () {
                  // Xử lý việc đăng ký tài khoản ở đây
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}