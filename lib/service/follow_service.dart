import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleFollow(String userId, String otherUserId) async {

    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return;
    }

    DocumentReference currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
    List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

    DocumentReference otherUser =
        FirebaseFirestore.instance.collection('users').doc(otherUserId);
    DocumentSnapshot otherUserSnapshot = await otherUser.get();
    List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

    if (followings.contains(otherUserId)) {
      // Nếu đang theo dõi, xóa userId khỏi danh sách
      followings.remove(otherUserId);
      followers.remove(userId);
    } else {
      // Nếu chưa theo dõi, thêm userId vào danh sách
      followings.add(otherUserId);
      followers.add(userId);

      await NotificationService().createNotification(
        content: 'vừa mới theo dõi bạn', 
        fromUser: userId,
        userId: otherUserId,
        recipeId: '',
        screen: 'user'
      );
      Map<String, dynamic> currentUserInfo = await UserService().getUserInfo(otherUserId);
      await NotificationService.sendNotification(currentUserInfo['FCM'], 'Theo dõi mới', '${currentUserInfo['fullname']} vừa theo dõi bạn ',
      data: {'screen': 'user', 'userId': otherUserId});

    }

    await currentUserRef.update({'followings': followings});
    await otherUser.update({'followers': followers});
    
  }
}