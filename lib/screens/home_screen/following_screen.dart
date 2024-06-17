import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> recipes = [];
  bool isLoading = false;
  DocumentSnapshot? lastDocument;
  bool hasMoreRecipes = true;

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

    Query query = FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', whereIn: await getFollowingUserIds())
        .orderBy('updateAt', descending: true)
        .limit(10);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!);
    }

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      lastDocument = querySnapshot.docs.last;
      recipes.addAll(querySnapshot.docs);
    } else {
      hasMoreRecipes = false;
    }

    setState(() {
      isLoading = false;
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
            ? Container(
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
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: 10),
                      ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recipes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == recipes.length) {
                            if (hasMoreRecipes) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : fetchRecipes,
                                  child: isLoading
                                      ? CircularProgressIndicator()
                                      : Text('Load More'),
                                ),
                              );
                            } else {
                              return Container();
                            }
                          }

                          DocumentSnapshot recipe = recipes[index];
                          Map<String, dynamic> recipeData =
                              recipe.data() as Map<String, dynamic>;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(recipeData['userID'])
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Container();
                              }

                              if (snapshot.hasError || !snapshot.hasData) {
                                return Container();
                              }

                              DocumentSnapshot userDoc = snapshot.data!;
                              Map<String, dynamic> userData =
                                  userDoc.data() as Map<String, dynamic>;

                              return Container(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: ItemRecipe(
                                      ontap: () {},
                                      name: recipeData['namerecipe'] ?? '',
                                      star:
                                          recipeData['rate']?.toString() ?? '0',
                                      favorite: recipeData['liked']
                                              ?.length
                                              .toString() ??
                                          '0',
                                      avatar: userData['avatar'] ?? '',
                                      fullname: userData['fullname'] ?? '',
                                      image: recipeData['image'] ?? '',
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            : Container(
                height: MediaQuery.of(context).size.height*.8,
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
                    SizedBox(
                      height: 30,
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Text('Đăng nhập ngay'),
                    )
                  ],
                ),
              ));
  }
}
