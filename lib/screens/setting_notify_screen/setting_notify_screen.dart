import 'package:flutter/material.dart';

class SettingNotifyScreen extends StatefulWidget {
  const SettingNotifyScreen({super.key});

  @override
  State<SettingNotifyScreen> createState() => _SettingNotifyScreenState();
}

class _SettingNotifyScreenState extends State<SettingNotifyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cài đặt thông báo'),
      ),
    );
  }
}