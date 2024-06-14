import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/detail_recipe.dart/widgets/item_detail_recipe.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/item_recipe.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class DetailReCipe extends StatefulWidget {
  final String recipeId;
  final String userId;

  const DetailReCipe({
    super.key,
    required this.recipeId,
    required this.userId,
  });

  @override
  State<DetailReCipe> createState() => _DetailReCipeState();
}

class _DetailReCipeState extends State<DetailReCipe> {
  final String url = "https://www.youtube.com/watch?v=YMx8Bbev6T4";

  late Future<DocumentSnapshot<Map<String, dynamic>>> _recipeFuture;
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();

    _recipeFuture = FirebaseFirestore.instance
        .collection('recipes')
        .doc(widget.recipeId)
        .get();
    _userFuture =
        FirebaseFirestore.instance.collection('users').doc(widget.userId).get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.favorite)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: FutureBuilder(
          future: Future.wait([_recipeFuture, _userFuture]),
          builder: (BuildContext context,
              AsyncSnapshot<List<DocumentSnapshot<Map<String, dynamic>>>>
                  snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.length != 2) {
              return Center(child: Text('Data not available'));
            }

            var recipeSnapshot = snapshot.data![0];
            var userSnapshot = snapshot.data![1];

            var recipeData = recipeSnapshot.data();
            var userData = userSnapshot.data();

            if (recipeData == null || userData == null) {
              return Center(child: Text('Data not available'));
            }
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Container(
                        height: 200,
                        width: 355,
                        child: YoutubePlayer(
                          controller: YoutubePlayerController(
                              initialVideoId: YoutubePlayer.convertUrlToId(
                                      recipeData['urlYoutube'])
                                  .toString(),
                              flags: YoutubePlayerFlags(autoPlay: false)),
                          showVideoProgressIndicator: true,
                          onReady: () {},
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Center(
                      child: Text(
                        'Tên món ăn :' + recipeData['namerecipe'],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Text(
                      'Mô tả món ăn :' + recipeData['description'],
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Center(
                            child: Text(
                              'Nguyên liệu',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: (recipeData['ingredients'] as List<dynamic>)
                          .map((ingredient) {
                        return ItemDetailRecipe(
                          index: ((recipeData['ingredients'] as List<dynamic>)
                              .indexOf(ingredient).toInt()
                               + 1).toString() ,
                          title: ingredient.toString(),
                        );
                      }).toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Center(
                            child: Text(
                              'Cách làm',
                              style: TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Divider(
                            color: Colors.black,
                            thickness: 1,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    ItemDetailRecipe(
                      index: '2',
                      title:
                          '1 tỷ tiền mặt 123123 123123 123123 123123 123123 123123 123123 123123 123123 123123 123123 123123 213123 123123 ',
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: MediaQuery.of(context).size.width * 0.25,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(
                                    'https://giadinh.mediacdn.vn/296230595582509056/2022/12/21/an-gi-102-16715878746102005998080.jpg',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Divider(),
                    SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: Container(
                        height: 60,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(
                          child: Column(
                            children: [
                              SizedBox(
                                width: 10,
                              ),
                              RatingBar.builder(
                                initialRating: 0,
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: true,
                                itemCount: 5,
                                itemPadding:
                                    EdgeInsets.symmetric(horizontal: 4.0),
                                itemBuilder: (context, _) => Icon(
                                  Icons.star,
                                  color: Colors.amber,
                                ),
                                onRatingUpdate: (rating) {
                                  print(rating);
                                },
                              ),
                              Text(
                                'Đánh giá 4.5/5 từ 100 thành viên',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Divider(),
                    SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: Container(
                        height: 180,
                        width: MediaQuery.of(context).size.width * 0.9,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.comment),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Bình luận'),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('4')
                                ],
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const CommentScreen()),
                                    );
                                  },
                                  child: Text('Xem tất cả bình luận')),
                              SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Phạm Duy Đạt'),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Text('Ngon quá')
                                ],
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                  ),
                                  SizedBox(
                                    width: 10,
                                  ),
                                  Container(
                                    height: 40,
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: TextField(
                                      decoration: InputDecoration(
                                        hintText: 'Bình luận ngay',
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          borderSide: BorderSide(),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding:
                                            EdgeInsets.fromLTRB(20, 10, 10, 10),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Divider(),
                    SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          height: 250,
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              SizedBox(
                                height: 20,
                              ),
                              CircleAvatar(
                                radius:
                                    50, // Đặt giá trị bạn muốn cho chiều cao
                                backgroundImage: NetworkImage(
                                    'https://giadinh.mediacdn.vn/296230595582509056/2022/12/21/an-gi-102-16715878746102005998080.jpg'),
                              ),
                              Text('Được đăng tải bởi'),
                              Text('Phạm Duy Đạt'),
                              Text('ngày 12 tháng 11 năm 2002'),
                              Container(
                                height: 40,
                                width: 100,
                                color: Colors.amber,
                                child: Center(child: Text('Theo dõi ngay')),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Divider(),
                    SizedBox(
                      height: 5,
                    ),
                    Center(
                      child: Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10)),
                          child: Column(
                            children: [
                              Text(
                                'Các món mới từ Phạm Duy Đạt',
                                textAlign: TextAlign.start,
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(
                                height: 5,
                              ),
                              ListView.builder(
                                physics: NeverScrollableScrollPhysics(),
                                shrinkWrap: true,
                                itemCount: 4,
                                itemBuilder: (context, index) {
                                  return Container(
                                    child: Center(
                                        child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: ItemRecipe(
                                        ontap: () {},
                                        name:
                                            'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                                        star: '4.3',
                                        favorite: '2000',
                                        avatar: '',
                                        fullname: 'Phạm Duy Đạt',
                                        image: 'assets/food_intro.jpg',
                                      ),
                                    )),
                                  );
                                },
                              ),
                            ],
                          )),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
