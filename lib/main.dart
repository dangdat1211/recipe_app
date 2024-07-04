import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:recipe_app/firebase_options.dart';
import 'package:recipe_app/helpers/local_storage_helper.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/notification_service.dart';

// Global instance of NotificationService
final NotificationService notificationService = NotificationService();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

Future<void> main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();
  await LocalStorageHelper.initLocalStorageHelper();
  
  notificationService.requestNotificationPermission();
  notificationService.getDeviceToken().then((value) {
    print('Token FCM : $value');
  });
  
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context)  {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
            background: Colors.grey.shade100,
            primary: Color(0xFFFF7622),
            outline: Colors.grey),
        scaffoldBackgroundColor: Colors.grey[100],
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          color: Colors.grey[100],
        ),
      ),
      home: Builder(
        builder: (BuildContext context)  {
          // Initialize firebaseInit here
          print('Đến đây thôi');
          notificationService.firebaseInit(context);
          print('Qua đây rồi');
          
          return Scaffold(
            body: Center(child: SplashScreen()),
          );
        },
      ),
    );
  }
}