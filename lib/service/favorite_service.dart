import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class FavoriteService {
  static Future<bool> isRecipeFavorite(String recipeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return false;
    }

    final favoriteSnapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: currentUser.uid)
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    return favoriteSnapshot.docs.isNotEmpty;
  }

  static Future<void> toggleFavorite(
      BuildContext context, String recipeId, String userId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final favoriteRef = FirebaseFirestore.instance.collection('favorites');
    final recipeRef =
        FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    final favoriteSnapshot = await favoriteRef
        .where('userId', isEqualTo: currentUser.uid)
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    if (favoriteSnapshot.docs.isNotEmpty) {
      // Xóa khỏi danh sách yêu thích
      await favoriteRef.doc(favoriteSnapshot.docs.first.id).delete();
      SnackBarCustom.showbar(context, 'Bạn đã bỏ yêu thích công thức công thức');
      

      final recipeData = await recipeRef.get();
      final likes = List<String>.from(recipeData['likes'] ?? []);
      likes.remove(currentUser.uid);
      await recipeRef.update({'likes': likes});
    } else {
      // Thêm vào danh sách yêu thích
      await favoriteRef.add({
        'userId': currentUser.uid,
        'recipeId': recipeId,
        'createAt': FieldValue.serverTimestamp(),
      });

      await NotificationService().createNotification(
        content: 'vừa mới thích công thức của bạn', 
        fromUser: currentUser.uid,
        userId: userId,
        recipeId: recipeId,
        screen: 'recipe'
      );
      Map<String, dynamic> currentUserInfo = await UserService().getUserInfo(userId);
      await NotificationService.sendNotification(currentUserInfo['FCM'], 'Lượt yêu thích mới từ công thức', '${currentUserInfo['fullname']} đã thích công thức của bạn ', 
      data: {'screen': 'recipe', 'recipeId': recipeId, 'userId': userId});
                                                  
      SnackBarCustom.showbar(context, 'Bạn đã thêm công thức vào yêu thích');

      // Thêm userId vào danh sách likes trong recipes
      final recipeData = await recipeRef.get();
      final likes = List<String>.from(recipeData['likes'] ?? []);
      likes.add(currentUser.uid);
      await recipeRef.update({'likes': likes});
    }
  }
}
