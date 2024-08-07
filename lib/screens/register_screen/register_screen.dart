import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/service/auth_service.dart';
import 'package:recipe_app/widgets/input_form.dart';

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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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

  bool _isLoading = false;

  bool isPasswordValid(String password) {
    return password.length >= 6 && !password.contains(' ');
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      return result.docs.isEmpty;
    } catch (e) {
      print('Lỗi khi kiểm tra tên tài khoản: $e');
      throw e;
    }
  }
  @override
  void initState() {
    super.initState();

    _usernameFocusNode.addListener(() {
      if (!_usernameFocusNode.hasFocus) {
        setState(() {
          _usernameError = _usernameController.text.isEmpty
              ? 'Tên người dùng không được để trống'
              : null;
        });
      }
    });

    _fullnameFocusNode.addListener(() {
      if (!_fullnameFocusNode.hasFocus) {
        setState(() {
          _fullnameError = _fullnameController.text.isEmpty
              ? 'Tên đầy đủ không được để trống'
              : null;
        });
      }
    });

    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        setState(() {
          _emailError =
              _emailController.text.isEmpty ? 'Email không được để trống' : null;
        });
      }
    });

    _passwordFocusNode.addListener(() {
  if (!_passwordFocusNode.hasFocus) {
    setState(() {
      if (_passwordController.text.isEmpty) {
        _passwordError = 'Mật khẩu không thể để trống';
      } else if (!isPasswordValid(_passwordController.text)) {
        _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự và không chứa khoảng trắng';
      } else {
        _passwordError = null;
      }
    });
  }
});

    _confirmPasswordFocusNode.addListener(() {
      if (!_confirmPasswordFocusNode.hasFocus) {
        setState(() {
          _confirmPasswordError = _confirmPasswordController.text.isEmpty
              ? 'Xác nhận mật khẩu không được để trống'
              : null;
          if (_passwordController.value != null) {
            if (_passwordController.value != _confirmPasswordController.value) {
              _confirmPasswordError = "Mật khẩu nhập lại không trùng khớp";
            } else {
              _confirmPasswordError = null;
            }
          }
        });
      }
    });
  }

  final AuthService _authService = AuthService();

  Future<void> _register() async {
    // if (_usernameController.text.isEmpty ||
    //     _fullnameController.text.isEmpty ||
    //     _emailController.text.isEmpty ||
    //     _passwordController.text.isEmpty ||
    //     _confirmPasswordController.text.isEmpty || 
    //     _confirmPasswordController.text != _passwordController.text) {
    //   return;
    // }

    final String username = _usernameController.text;
    final String fullname =  _fullnameController.text;
    final String email = _emailController.text;
    final String pass = _passwordController.text;
    final String confirm = _confirmPasswordController.text;

    setState( () {
      _usernameError = username.isEmpty  ? 'Tên tài khoản không được để trống' 
      : !isPasswordValid(username) ? 'Tên tài khoản có ít nhất 6 ký tự và không chứa khoảng trắng' : null;
      _fullnameError = fullname.isEmpty  ? 'Tên đầy đủ không được để trống' : null;
      _emailError = email.isEmpty  ? 'Email không được để trống' : null;
      _passwordError = pass.isEmpty  ? 'Mật khẩu không được để trống' : null;
      _confirmPasswordError = confirm .isEmpty ? 'Mật khẩu không được để trống' : null;
      _passwordError = pass.isEmpty 
      ? 'Mật khẩu không được để trống' 
      : !isPasswordValid(pass)
        ? 'Mật khẩu phải có ít nhất 6 ký tự và không chứa khoảng trắng'
        : null;
    _confirmPasswordError = confirm.isEmpty 
      ? 'Xác nhận mật khẩu không được để trống' 
      : pass != confirm
        ? 'Mật khẩu không trùng khớp'
        : null;

    });

    if (_usernameError == null && _fullnameError == null && _emailError == null && _passwordError == null && _confirmPasswordError == null) {
      setState(() {
        _isLoading = true;
      });

      try {
        bool isAvailable = await isUsernameAvailable(username);
        if (!isAvailable) {
          setState(() {
            _usernameError = 'Tên tài khoản đã được sử dụng';
            _isLoading = false;
          });
          return;
        }

        await _authService.registerUser(
          username: _usernameController.text,
          fullname: _fullnameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        SnackBarCustom.showbar(context, 'Email xác minh đã được gửi đến ${_emailController.text}');

        Navigator.pop(context);
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'email-already-in-use') {
            _emailError = 'Email đã được sử dụng';
          }
          if (e.code == 'invalid-email') {
            _emailError = 'Sai định dạng email';
          }
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Đăng ký'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 150,
                child: Image.asset('assets/logo_noback.png'),
              ),
              Text('Tham gia ngay cùng cộng đồng lớn'),
              SizedBox(
                height: 30,
              ),
              SizedBox(
                height: 10,
              ),
              InputForm(
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                errorText: _usernameError,
                label: 'Tên tài khoản',
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_emailFocusNode),
              ),
              const SizedBox(height: 10),
              InputForm(
                controller: _emailController,
                focusNode: _emailFocusNode,
                errorText: _emailError,
                label: 'Email',
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_fullnameFocusNode),
              ),
              const SizedBox(height: 10),
              InputForm(
                controller: _fullnameController,
                focusNode: _fullnameFocusNode,
                errorText: _fullnameError,
                label: 'Tên đầy đủ',
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocusNode),
              ),
              const SizedBox(height: 10),
              InputForm(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                errorText: _passwordError,
                label: 'Mật khẩu',
                isPassword: true,
                onSubmitted: (_) => FocusScope.of(context).requestFocus(_confirmPasswordFocusNode),
              ),
              const SizedBox(height: 10),
              InputForm(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocusNode,
                errorText: _confirmPasswordError,
                label: 'Nhập lại mật khẩu',
                isPassword: true,
                onSubmitted: (_) => _register(),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : _register, // Vô hiệu hóa nút khi đang loading
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: 
                         Color(0xFFFF7622),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                            color: Colors.white) // Hiển thị loading indicator
                        : Text(
                            'Đăng ký',
                            style: TextStyle(color: Colors.white),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
