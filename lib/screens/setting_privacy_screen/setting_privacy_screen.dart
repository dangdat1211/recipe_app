import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/constants/colors.dart';

class SettingPrivacyScreen extends StatefulWidget {
  const SettingPrivacyScreen({super.key});

  @override
  State<SettingPrivacyScreen> createState() => _SettingPrivacyScreenState();
}

class _SettingPrivacyScreenState extends State<SettingPrivacyScreen> {
  String _selectedPrivacy = 'public';

  @override
  void initState() {
    super.initState();
    _loadCurrentPrivacy();
  }

  Future<void> _loadCurrentPrivacy() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (docSnapshot.exists) {
        setState(() {
          _selectedPrivacy = docSnapshot.data()?['privacy'] ?? 'public';
        });
      }
    }
  }

  Future<void> _updatePrivacy(String privacy) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'privacy': privacy});
      
      setState(() {
        _selectedPrivacy = privacy;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quyền riêng tư'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ai có thể xem trang cá nhân của bạn?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          _buildPrivacyOption(
            title: 'Công khai',
            subtitle: 'Mọi người trên ứng dụng',
            value: 'public',
            icon: Icons.public,
          ),
          _buildPrivacyOption(
            title: 'Người theo dõi',
            subtitle: 'Những người đã theo dõi bạn',
            value: 'friends',
            icon: Icons.group,
          ),
          _buildPrivacyOption(
            title: 'Chỉ mình tôi',
            subtitle: 'Chỉ bạn',
            value: 'private',
            icon: Icons.lock,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyOption({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
  }) {
    return ListTile(
      leading: Icon(icon, color: mainColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Radio<String>(
        value: value,
        groupValue: _selectedPrivacy,
        onChanged: (newValue) => _updatePrivacy(newValue!),
        activeColor: mainColor,
      ),
      onTap: () => _updatePrivacy(value),
    );
  }
}