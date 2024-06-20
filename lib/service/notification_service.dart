import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path/path.dart';

class NotificationService {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  void requestNotificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Notification permission granted.');
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('Notification permission denied.');
    } else {
      print('Notification permission not determined.');
    }
  }

  Future<String?> getDeviceToken() async {
    String? token = await messaging.getToken();
    return token;
  }

  void isTokenRefresh() {
    messaging.onTokenRefresh.listen((newToken) {
      // Handle token refresh logic
      print('Token refreshed: $newToken');
    });
  }

  void initLocalNotification(BuildContext context) async {
    var android = AndroidInitializationSettings('@mipmap/ic_launcher');
    var ios = DarwinInitializationSettings();

    var initSetting = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSetting,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tapped logic here
      },
    );
  }

  void firebaseInit(BuildContext context) {
    FirebaseMessaging.onMessage.listen((message) {
      print('Title: ' + (message.notification?.title ?? 'No Title'));
      print('Body: ' + (message.notification?.body ?? 'No Body'));
      if (Platform.isAndroid) {
        initLocalNotification(context);
        showNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Handle the notification tapped logic here if the app was opened from a notification
    });
  }

  Future<void> showNotification(RemoteMessage message) async {
    AndroidNotificationChannel channel = AndroidNotificationChannel(
      Random.secure().nextInt(100000).toString(),
      'High Importance Notifications',
      importance: Importance.max,
    );

    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    DarwinNotificationDetails darwinNotificationDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? 'No Title',
      message.notification?.body ?? 'No Body',
      notificationDetails,
    );
  }
}
