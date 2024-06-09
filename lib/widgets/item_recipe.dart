import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/screens.dart';

class ItemRecipe extends StatefulWidget {
  const ItemRecipe({
    super.key,
    required this.name,
    required this.star,
    required this.favorite,
    required this.avatar,
    required this.fullname,
    required this.image,
  });

  final String name;
  final String star;
  final String favorite;
  final String avatar;
  final String fullname;
  final String image;

  @override
  State<ItemRecipe> createState() => _ItemRecipeState();
}

class _ItemRecipeState extends State<ItemRecipe> {

  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DetailReCipe()),
        );
      },
      child: Container(
        width: MediaQuery.of(context).size.width*0.8,
        child: Row(
          children: [
            Container(
              width: MediaQuery.of(context).size.width*0.55,
              height: 142,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 248, 243),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.name,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: TextStyle(fontSize: 15),
                    ),
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.star),
                                Text(widget.star),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(Icons.favorite),
                                Text(widget.favorite),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: AssetImage(widget.avatar),
                            ),
                            SizedBox(
                              width: 5,
                            ),
                            Text(widget.fullname),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width*0.25,
              height: 142,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(10),
                        bottomRight: Radius.circular(10),
                      ),
                      child: Image.network(
                        'https://giadinh.mediacdn.vn/296230595582509056/2022/12/21/an-gi-102-16715878746102005998080.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          isFavorite = !isFavorite; // Đổi trạng thái yêu thích
                        });
                      },
                      child: Icon(
                        Icons.favorite,
                        size: 36.0, 
                        color: isFavorite ? Colors.red : Colors.white, // Đổi màu dựa trên trạng thái
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
