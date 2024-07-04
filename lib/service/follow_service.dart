import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class FollowService {
  Future<void> toggleFollow(String userId, String otherUserId) async {

    DocumentReference currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
    List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

    DocumentReference otherUser =
        FirebaseFirestore.instance.collection('users').doc(otherUserId);
    DocumentSnapshot otherUserSnapshot = await otherUser.get();
    List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

    if (followings.contains(userId)) {
      // Nếu đang theo dõi, xóa userId khỏi danh sách
      followings.remove(otherUserId);
      followers.remove(userId);
    } else {
      // Nếu chưa theo dõi, thêm userId vào danh sách
      followings.add(otherUserId);
      followers.add(userId);

      await NotificationService().createNotification(
        content: 'vừa mới theo dõi mày', 
        fromUser: userId,
        userId: otherUserId,
        recipeId: '',
        screen: 'recipe'
      );
      Map<String, dynamic> currentUserInfo = await UserService().getUserInfo(userId);
      await NotificationService.sendNotification(currentUserInfo['FCM'], 'Theo dõi mới', '${currentUserInfo['fullname']} vừa theo dõi bạn ');

    }

    await currentUserRef.update({'followings': followings});
    await otherUser.update({'followers': followers});
  }
}