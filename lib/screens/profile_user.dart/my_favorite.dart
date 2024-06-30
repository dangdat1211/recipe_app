import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';
import 'package:recipe_app/screens/profile_user.dart/widgets/view_item.dart';

class MyFavorite extends StatefulWidget {
  final String userId;
  const MyFavorite({super.key, required this.userId});

  @override
  State<MyFavorite> createState() => _MyFavoriteState();
}

class _MyFavoriteState extends State<MyFavorite> {
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('favorites');

  Future<List<Map<String, dynamic>>> _getData() async {
    QuerySnapshot querySnapshot =
        await _collectionRef.where('userId', isEqualTo: widget.userId).get();
    List<String> favoriteRecipeIds = querySnapshot.docs
        .map((doc) => (doc.data() as Map<String, dynamic>)['recipeId'] as String)
        .toList();
    
    List<Map<String, dynamic>> recipes = [];
    for (String recipeId in favoriteRecipeIds) {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .get();
      if (doc.exists) {
        Map<String, dynamic> recipeData = doc.data() as Map<String, dynamic>;
        recipeData['id'] = doc.id; // Add the document ID to the data
        recipes.add(recipeData);
      }
    }

    return recipes;
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy').format(dateTime); 
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: FutureBuilder(
          future: _getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Lỗi: ${snapshot.error}'));
            }
            List<Map<String, dynamic>> data = snapshot.data ?? [];
            return GridView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 5,
              ),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                List<String> likedList = List<String>.from(item['likes'] ?? []);
                List<String> ratelist = List<String>.from(item['rates'] ?? []);
                return ViewItem(
                  image: item['image'] ??
                      'https://static.vinwonders.com/production/mon-ngon-ha-dong-4.jpeg',
                  rate: ratelist.length.toString(),
                  like: likedList.length.toString(),
                  date: _formatTimestamp(item['createAt']),
                  title: item['namerecipe'] ?? 'Com ngon',
                  onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailReCipe(
                            recipeId: item['id'], 
                            userId: item['userID'],
                          ),
                        ),
                      );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
