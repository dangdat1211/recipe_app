import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/service/favorite_service.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> recipesWithUserData = [];
  bool isLoading = false;
  bool isInitialLoading = true;  // Thêm biến này
  DocumentSnapshot? lastDocument;
  bool hasMoreRecipes = true;
  bool isFollowingAnyone = false;

  @override
  void initState() {
    super.initState();
    fetchRecipes();
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showLoginDialog();
      });
    }
  }

  Future<void> fetchRecipes() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    List<String> followingUserIds = await getFollowingUserIds();
    
    isFollowingAnyone = followingUserIds.isNotEmpty;

    if (!isFollowingAnyone) {
      setState(() {
        isLoading = false;
        isInitialLoading = false;  // Thêm dòng này
      });
      return;
    }

    Query query = FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', whereIn: followingUserIds)
        .orderBy('updateAt', descending: true)
        .limit(10);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;

      for (var recipeDoc in querySnapshot.docs) {
        var recipeData = recipeDoc.data() as Map<String, dynamic>;
        var recipeId = recipeDoc.id;

        var userId = recipeData['userID'];

        var userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        var userData = userDoc.data();

        if (userData != null) {
          recipeData['recipeId'] = recipeId;

          bool isFavorite = await FavoriteService.isRecipeFavorite(recipeId);

          recipesWithUserData.add({
            'recipe': recipeData,
            'user': userData,
            'isFavorite': isFavorite,
          });
        }
      }
    } else {
      hasMoreRecipes = false;
    }

    setState(() {
      isLoading = false;
      isInitialLoading = false;  // Thêm dòng này
    });
  }

  Future<List<String>> getFollowingUserIds() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      return List<String>.from(userDoc['followings'] ?? []);
    }
    return [];
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Bạn chưa đăng nhập'),
          content: Text('Vui lòng đăng nhập để tiếp tục.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                );
              },
              child: Text('Đăng nhập'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: currentUser != null
          ? isInitialLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Text(
                            'Công thức từ người bạn theo dõi',
                            textAlign: TextAlign.start,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(height: 10),
                        if (!isFollowingAnyone)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'Bạn chưa theo dõi ai.',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: recipesWithUserData.length + 1,
                            itemBuilder: (context, index) {
                              if (index == recipesWithUserData.length) {
                                if (hasMoreRecipes) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : fetchRecipes,
                                      child: isLoading ? CircularProgressIndicator() : Text('Xem thêm'),
                                    ),
                                  );
                                } else {
                                  return Container();
                                }
                              }

                              final recipeWithUser = recipesWithUserData[index];
                              final recipe = recipeWithUser['recipe'];
                              final user = recipeWithUser['user'];
                              final isFavorite = recipeWithUser['isFavorite'];

                              return Container(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ItemRecipe(
                                      ontap: () {},
                                      name: recipe['namerecipe'] ?? '',
                                      star: recipe['rate']?.toString() ?? '0',
                                      favorite: recipe['liked']?.length.toString() ?? '0',
                                      avatar: user['avatar'] ?? '',
                                      fullname: user['fullname'] ?? '',
                                      image: recipe['image'] ?? '',
                                      isFavorite: isFavorite,
                                      onFavoritePressed: () => FavoriteService.toggleFavorite(context, recipe['recipeID'], recipe['userId']),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                )
          : Container(
              height: MediaQuery.of(context).size.height * .8,
              width: MediaQuery.of(context).size.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 150,
                    child: Image.asset('assets/logo_noback.png'),
                  ),
                  Text('Tham gia ngay cùng cộng đồng lớn'),
                  SizedBox(height: 30),
                  GestureDetector(
                    onTap: () {},
                    child: Text('Đăng nhập ngay'),
                  )
                ],
              ),
            ),
    );
  }
}