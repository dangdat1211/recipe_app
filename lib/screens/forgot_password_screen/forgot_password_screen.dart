import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {

  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Forgot Pass'),
      ),
        body: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
                'Quên mật khẩu',
                style: TextStyle(
                  fontSize: 40,
                ),
              ),
              SizedBox(
                height: 50,
              ),
            TextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              decoration: InputDecoration(
                labelText: 'email',
                border: OutlineInputBorder(),
                errorText: _emailError,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                labelStyle: TextStyle(fontSize: 16),
                errorStyle: TextStyle(fontSize: 14),
              ),
              obscureText: true,
            ),
            SizedBox(height: 10,),
            GestureDetector(
                onTap: () {
                },
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF7622),
                    borderRadius:
                        BorderRadius.circular(20), 
                  ),
                  child: Center(
                    child: Text(
                      'Gửi lại mật khẩu',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
  }
}
