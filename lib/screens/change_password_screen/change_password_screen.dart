import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/widgets/input_form.dart';
import 'package:recipe_app/widgets/ui_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _currentPasswordFocusNode = FocusNode();
  final _newPasswordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  Future<void> _showChangePasswordDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Change Password'),
          content: Text('Are you sure you want to change your password?'),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _changePassword();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword() async {
    setState(() {
      // Reset error messages
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;

      // Validate current password
      if (_currentPasswordController.text.isEmpty) {
        _currentPasswordError = 'Current password is required';
      }

      // Validate new password
      if (_newPasswordController.text.isEmpty) {
        _newPasswordError = 'New password is required';
      } else if (_newPasswordController.text != _confirmPasswordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      }
    });

    if (_currentPasswordError == null && _newPasswordError == null && _confirmPasswordError == null) {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) {
          return AlertDialog(
            title: Text('Changing Password'),
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Please wait...'),
              ],
            ),
          );
        },
      );

      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Reauthenticate the user
          AuthCredential credential = EmailAuthProvider.credential(
            email: user.email!,
            password: _currentPasswordController.text,
          );

          await user.reauthenticateWithCredential(credential);

          // Update the password
          await user.updatePassword(_newPasswordController.text);

          Navigator.of(context).pop(); // Close the progress dialog

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Password Changed'),
                content: Text('Your password has been successfully changed.'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('OK'),
                  ),
                ],
              );
            },
          );
        }
      } catch (error) {
        Navigator.of(context).pop(); // Close the progress dialog

        setState(() {
          _currentPasswordError = 'Current password is incorrect';
        });
      }
    }
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentPasswordFocusNode.dispose();
    _newPasswordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            InputForm(
              controller: _currentPasswordController,
              focusNode: _currentPasswordFocusNode,
              errorText: _currentPasswordError,
              isPassword: true,
              label: 'Current Password',
            ),
            SizedBox(height: 16),
            InputForm(
              controller: _newPasswordController,
              focusNode: _newPasswordFocusNode,
              errorText: _newPasswordError,
              isPassword: true,
              label: 'New Password',
            ),
            SizedBox(height: 16),
            InputForm(
              controller: _confirmPasswordController,
              focusNode: _confirmPasswordFocusNode,
              errorText: _confirmPasswordError,
              isPassword: true,
              label: 'Confirm Password',
            ),
            SizedBox(height: 20),
            UiButton(
              ontap: _showChangePasswordDialog, 
              title: 'Đổi mật khẩu', 
              weightBT: MediaQuery.of(context).size.width*0.9, 
              color: mainColor
            ),
          ],
        ),
      ),
    );
  }
}
