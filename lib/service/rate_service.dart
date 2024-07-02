import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';

class RateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static Future<double> getAverageRating(String recipeId) async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('recipeId', isEqualTo: recipeId)
        .get();

    List<DocumentSnapshot> rateDocuments = querySnapshot.docs;

    if (rateDocuments.isEmpty) {
      return 0.0; // Nếu không có đánh giá, trả về 0.0
    }

    double totalRating = 0.0;
    for (var rateDoc in rateDocuments) {
      double star =
          rateDoc.get('star') ?? 0.0; // Lấy giá trị star từ mỗi bản ghi
      totalRating += star;
    }

    double averageRating = totalRating / rateDocuments.length;
    return averageRating;
  }

  static Future<Map<String, dynamic>> fetchAverageRating(String recipeId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    final ratingsSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('recipeId', isEqualTo: recipeId)
        .get();

    final ratings =
        ratingsSnapshot.docs.map((doc) => doc.data()['star'] as num).toList();

    final userRatingSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .doc('${currentUser?.uid}_${recipeId}')
        .get();

    final hasRated = userRatingSnapshot.exists;

    if (ratings.isEmpty) {
      return {'avgRating': 0.0, 'ratingCount': 0, 'hasRated': hasRated};
    }

    final avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
    final ratingCount = ratings.length;

    return {
      'avgRating': avgRating.toDouble(),
      'ratingCount': ratingCount,
      'hasRated': hasRated
    };
  }

  Future<double> getUserRating(String userid, String ricipeId) async {

    final ratingSnapshot = await FirebaseFirestore.instance
        .collection('rates')
        .where('userId', isEqualTo: userid)
        .where('recipeId', isEqualTo: ricipeId)
        .get();

    if (ratingSnapshot.docs.isNotEmpty) {
      final ratingData = ratingSnapshot.docs.first.data();
      return ratingData['star']?.toDouble() ?? 0.0;
    }

    return 0.0;
  }

  Future<void> updateRating(String userId, String recipeId, double rating) async {
    final userRatingRef = _firestore.collection('rates').doc('${userId}_$recipeId');

    try {
      final docSnapshot = await userRatingRef.get();
      
      if (docSnapshot.exists) {
        await userRatingRef.update({'star': rating});
      } else {
        await userRatingRef.set({
          'userId': userId,
          'recipeId': recipeId,
          'star': rating,
          'createAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating rating: $e');
      throw e;
    }
  }
}
