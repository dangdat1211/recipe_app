import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/home_screen/widgets/item_user.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class ProposeScreen extends StatefulWidget {
  const ProposeScreen({super.key});

  @override
  State<ProposeScreen> createState() => _ProposeScreenState();
}

class _ProposeScreenState extends State<ProposeScreen> {
  List<Map<dynamic, dynamic>> ingredients = [
    {"name": "Cà chua", "icon": Icons.local_pizza},
    {"name": "Khoai tây", "icon": Icons.local_dining},
    {"name": "Cà rốt", "icon": Icons.restaurant},
    {"name": "Ớt", "icon": Icons.local_fire_department},
    {"name": "Bắp cải", "icon": Icons.fastfood},
    {"name": "Hành tây", "icon": Icons.no_food},
    {"name": "Tỏi", "icon": Icons.emoji_food_beverage},
    {"name": "Gừng", "icon": Icons.emoji_nature},
  ];

  List<String> recipes = ["Recipe 1", "Recipe 2", "Recipe 3", "Recipe 4"];
  Set<String> selectedIngredients = {};
  String selectedValue = 'Mới cập nhật';

  User? currentUser = FirebaseAuth.instance.currentUser;
  List<Map<String, dynamic>> recipesWithUserData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }
  
  // Get all user with id
  Future<List<Map<String, dynamic>>> fetchAllUsersWithId() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .orderBy('followers', descending: true)
        .limit(10)
        .get();

    List<Map<String, dynamic>> users = querySnapshot.docs
        .map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        })
        .where((user) => user['id'] != currentUser?.uid)
        .toList();

    return users;
  }

  Future<List<String>> fetchFollowedUsers() async {
    String currentUserId = currentUser!.uid;
    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .get();

    List<dynamic> followedUsers = docSnapshot['followings'] ?? [];
    print(followedUsers);
    return List<String>.from(followedUsers);
  }

  Future<void> toggleFollow(String userId) async {
    String currentUserId = currentUser!.uid;

    DocumentReference currentUserRef =
        FirebaseFirestore.instance.collection('users').doc(currentUserId);
    DocumentSnapshot currentUserSnapshot = await currentUserRef.get();
    List<dynamic> followings = currentUserSnapshot['followings'] ?? [];

    DocumentReference otherUser =
        FirebaseFirestore.instance.collection('users').doc(userId);
    DocumentSnapshot otherUserSnapshot = await otherUser.get();
    List<dynamic> followers = otherUserSnapshot['followers'] ?? [];

    if (followings.contains(userId)) {
      // Nếu đang theo dõi, xóa userId khỏi danh sách
      followings.remove(userId);
      followers.remove(currentUserId);
    } else {
      // Nếu chưa theo dõi, thêm userId vào danh sách
      followings.add(userId);
      followers.add(currentUserId);
    }

    await currentUserRef.update({'followings': followings});
    await otherUser.update({'followers': followers});
  }

  // Danh sách công thức
  Future<void> _fetchRecipes() async {
    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance.collection('recipes');

    query = query.where('status', isEqualTo: 'Đợi phê duyệt');



    if (selectedValue == 'Mới cập nhật') {
      query = query.orderBy('updateAt', descending: true);
    } else if (selectedValue == 'Nhiều tim nhất') {
      query = query.orderBy('likes', descending: true);
    } else if (selectedValue == 'Điểm cao nhất') {
      query = query.orderBy('star', descending: true);
    }

    final QuerySnapshot recipeSnapshot = await query.get();

    List<DocumentSnapshot> recipeDocs = recipeSnapshot.docs;

    // Clear previous data
    recipesWithUserData = [];

    for (var recipeDoc in recipeDocs) {
      var recipeData = recipeDoc.data() as Map<String, dynamic>;
      var recipeId = recipeDoc.id; 

      var userId = recipeData['userID'];

      // Fetch user data
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      var userData = userDoc.data();

      if (userData != null) {
        // Thêm recipeId vào dữ liệu recipe
        recipeData['recipeId'] = recipeId;

        recipesWithUserData.add({
          'recipe': recipeData,
          'user': userData,
        });
      }

      print(recipesWithUserData);
    }

    setState(() {
      isLoading = false;
    });
  }

  void _navigateToRecipeDetail(String recipeID, String userId,) {
    print('Click');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailReCipe(recipeId: recipeID, userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: 10,
                right: 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  Text('Bạn đang có những nguyên liệu gì?'),
                  Text('Chọn 1-2 nguyên liệu'),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 5.0,
                    runSpacing: 5.0,
                    children: ingredients.map((ingredient) {
                      bool isSelected =
                          selectedIngredients.contains(ingredient['name']);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              selectedIngredients.remove(ingredient['name']);
                            } else {
                              selectedIngredients.add(ingredient['name']);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                ingredient['icon'],
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                              SizedBox(width: 5),
                              Text(
                                ingredient['name'],
                                style: TextStyle(
                                  color:
                                      isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 20),
                  if (selectedIngredients.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Danh sách món'),
                        SizedBox(height: 10),
                        Container(
                          height: 150,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: recipes.length + 1,
                            itemBuilder: (context, index) {
                              if (index == recipes.length) {
                                return GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    width: 100,
                                    child: Center(
                                        child: Container(
                                      height: 50,
                                      width: 50,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.grey,
                                          width: 2.0,
                                        ),
                                      ),
                                      child: Icon(Icons.arrow_forward),
                                    )),
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: ItemRecipe(
                                    ontap: () {
                                      
                                    },
                                    name:
                                        'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                                    star: '4.3',
                                    favorite: '2000',
                                    avatar: '',
                                    fullname: 'Phạm Duy Đạt',
                                    image: 'assets/food_intro.jpg',
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  if (selectedIngredients.isEmpty)
                    Container(
                      height: 300,
                      width: MediaQuery.of(context).size.width * 0.9,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 150,
                            child: Image.asset('assets/logo_noback.png'),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Text(
                            'Chọn một nguyên liệu',
                            style: TextStyle(fontSize: 25),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          Container(
                            width: 200,
                            child: Text(
                              'Chọn 1 đến 2 nguyên liệu để tìm ý tưởng cho món ăn',
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    )
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('Các loại món ăn'),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.abc_rounded),
                                Text(('Xào'))
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 10,
          ),
          FutureBuilder<List<String>>(
            future: fetchFollowedUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Lỗi: ${snapshot.error}'));
              }
              List<String> followedUsers = snapshot.data ?? [];
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchAllUsersWithId(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Lỗi: ${snapshot.error}'));
                  }
                  List<Map<String, dynamic>> users = snapshot.data ?? [];
                  return Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text('Người dùng nổi bật'),
                          Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: users.length,
                              itemBuilder: (context, index) {
                                final user = users[index];
                                bool isFollowing =
                                    followedUsers.contains(user['id']);
                                return ItemUser(
                                  ontap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ProfileUser(userId: user['id'])),
                                    );
                                  },
                                  avatar: (user['avatar'] != null &&
                                          user['avatar'].isNotEmpty)
                                      ? user['avatar']
                                      : 'https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png',
                                  fullname: user['fullname'] ?? 'N/A',
                                  username: user['username'] ?? 'N/A',
                                  recipe: (user['recipes'] as List)
                                      .length
                                      .toString(),
                                  follow: isFollowing,
                                  clickFollow: () async {
                                    await toggleFollow(user['id']);
                                    // setState(
                                    //     () {});
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Danh sách công thức'),
                    DropdownButton<String>(
                      value: selectedValue,
                      items: <String>[
                        'Mới cập nhật',
                        'Nhiều tim nhất',
                        'Điểm cao nhất'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedValue = newValue!;
                        });
                        _fetchRecipes();
                      },
                    ),
                  ],
                ),
                isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: recipesWithUserData.length,
                        itemBuilder: (context, index) {
                          final recipeWithUser = recipesWithUserData[index];
                          final recipe = recipeWithUser['recipe'];
                          final user = recipeWithUser['user'];

                          return Container(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ItemRecipe(
                                  ontap: () {
                                    _navigateToRecipeDetail(recipe['recipeId'], recipe['userID']);
                                  },
                                  name: recipe['namerecipe'] ??
                                      'Không có tiêu đề',
                                  star: (recipe['rates'].isNotEmpty
                                          ? (recipe['rates']
                                                  .reduce((a, b) => a + b) /
                                              recipe['rates'].length)
                                          : 0)
                                      .toStringAsFixed(1),
                                  favorite: recipe['likes'].length.toString(),
                                  avatar: user['avatar'] ??
                                      'assets/food_intro.jpg',
                                  fullname:
                                      user['fullname'] ?? 'Không rõ tên',
                                  image: recipe['image'] ??
                                      'https://candangstudio.com/wp-content/uploads/2022/04/studio-session-040_51065362217_o.jpg',
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
