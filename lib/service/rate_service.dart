import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/constants/colors.dart';

class RateService {
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
}
