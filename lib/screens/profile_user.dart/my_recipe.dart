import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/profile_user.dart/widgets/view_item.dart';

class MyRecipe extends StatefulWidget {
  final String userId;
  const MyRecipe({super.key, required this.userId});

  @override
  State<MyRecipe> createState() => _MyRecipeState();
}

class _MyRecipeState extends State<MyRecipe> {
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('recipes');

  Future<List<Map<String, dynamic>>> _getData() async {
    QuerySnapshot querySnapshot =
        await _collectionRef.where('userID', isEqualTo: widget.userId).get();
    return querySnapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
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
                List<String> likedList = List<String>.from(item['liked'] ?? []);
                return ViewItem(
                  image: item['image'] ??
                      'https://static.vinwonders.com/production/mon-ngon-ha-dong-4.jpeg',
                  rate: item['rate'] ?? '0.0',
                  like: likedList.length.toString(),
                  date: item['date'] ?? '12/11/2002',
                  title: item['name'] ?? 'Com ngon',
                  onTap: () {
                    // Xử lý khi người dùng nhấn vào
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
