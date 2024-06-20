import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';

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
      BuildContext context, String recipeId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }

    final userId = currentUser.uid;
    final favoriteRef = FirebaseFirestore.instance.collection('favorites');
    final recipeRef =
        FirebaseFirestore.instance.collection('recipes').doc(recipeId);

    final favoriteSnapshot = await favoriteRef
        .where('userId', isEqualTo: userId)
        .where('recipeId', isEqualTo: recipeId)
        .limit(1)
        .get();

    if (favoriteSnapshot.docs.isNotEmpty) {
      // Xóa khỏi danh sách yêu thích
      await favoriteRef.doc(favoriteSnapshot.docs.first.id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn đã bỏ lưu công thức',
              style: TextStyle(color: Colors.black)),
          backgroundColor: mainColorBackground,
        ),
      );

      // Xóa userId khỏi danh sách likes trong recipes
      final recipeData = await recipeRef.get();
      final likes = List<String>.from(recipeData['likes'] ?? []);
      likes.remove(userId);
      await recipeRef.update({'likes': likes});
    } else {
      // Thêm vào danh sách yêu thích
      await favoriteRef.add({
        'userId': userId,
        'recipeId': recipeId,
        'createAt': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bạn đã thêm công thức vào mục yêu thích',
              style: TextStyle(color: Colors.black)),
          backgroundColor: mainColorBackground,
        ),
      );

      // Thêm userId vào danh sách likes trong recipes
      final recipeData = await recipeRef.get();
      final likes = List<String>.from(recipeData['likes'] ?? []);
      likes.add(userId);
      await recipeRef.update({'likes': likes});
    }
  }
}
