import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class NotifyScreen extends StatefulWidget {
  const NotifyScreen({super.key});

  @override
  State<NotifyScreen> createState() => _NotifyScreenState();
}

class _NotifyScreenState extends State<NotifyScreen> {
  List<Map<String, dynamic>> notifications = List.generate(
    10,
    (index) => {
      'title': 'Thông báo ${index + 1}',
      'content': 'Nội dung thông báo ${index + 1}',
      'date': '12 tháng 6, 2023',
      'isRead': false,
    },
  );

  Future<void> _refreshNotifications() async {
    // Giả lập việc tải dữ liệu mới từ server bằng cách chờ 2 giây
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      // Thay đổi trạng thái hoặc dữ liệu của thông báo ở đây nếu cần thiết
      // Dưới đây chỉ là ví dụ cập nhật danh sách thông báo mới
      notifications = List.generate(
        10,
        (index) => {
          'title': 'Thông báo mới ${index + 1}',
          'content': 'Nội dung thông báo mới ${index + 1}',
          'date': '13 tháng 6, 2023',
          'isRead': false,
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Thông báo'),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListTile(
                  title: Text(
                    notifications[index]['title']!,
                    style: TextStyle(
                      fontWeight: notifications[index]['isRead']
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(notifications[index]['content']!),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(notifications[index]['date']!),
                      if (!notifications[index]['isRead'])
                        Icon(
                          Icons.circle,
                          color: Colors.blue,
                          size: 10,
                        ),
                    ],
                  ),
                  onTap: () {
                    setState(() {
                      notifications[index]['isRead'] = true;
                    });
                    _showNotificationDetails(notifications[index]);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showNotificationDetails(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification['title']!),
        content: Text(notification['content']!),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }
}
