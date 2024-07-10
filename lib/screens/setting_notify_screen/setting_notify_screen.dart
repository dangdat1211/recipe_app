import 'package:flutter/material.dart';
import 'package:recipe_app/screens/user_screen/widgets/ui_container.dart';
import 'package:recipe_app/service/notification_service.dart';

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
      body: Center(
        child: UIContainer(
            ontap: () async {
              String? notify = await NotificationService().getDeviceToken();

              NotificationService.sendNotification(
                  notify!, "Alo", "Nội dung thông báo",
                  data: {'screen': 'home', 'value': 'novalue'});
            },
            color: Colors.red,
            title: 'Gửi thông báo'),
      ),
    );
  }
}
