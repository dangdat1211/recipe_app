import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
                            height: 100,
                            child: Image.asset('assets/food_intro.jpg'),
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
                  Text('Người dùng nổi bật'),
                  Container(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: recipes.length,
                      itemBuilder: (context, index) {
                        return Card(
                          color: Colors.white,
                          child: Container(
                            width: 130,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(),
                                Text(('Phạm Duy Đạt')),
                                Text('@user_name'),
                                Text('10000 công thức'),
                                GestureDetector(
                                  child: Container(
                                      height: 30,
                                      width: 100,
                                      decoration: BoxDecoration(
                                          color: Color.fromARGB(
                                              255, 255, 206, 175),
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                      child: Center(
                                        child: Text(
                                          'Theo dõi ngay',
                                          style: TextStyle(
                                            color: Color(0xFFFF7622),
                                          ),
                                        ),
                                      )),
                                )
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
          Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedValue), // Text thay đổi theo selectedValue
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
                      },
                    ),
                  ],
                ),
                GridView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    childAspectRatio: 2.7,
                  ),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    return ItemRecipe(
                      name:
                          'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                      star: '4.3',
                      favorite: '2000',
                      avatar: '',
                      fullname: 'Phạm Duy Đạt',
                      image: 'assets/food_intro.jpg',
                    );
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: Text('Propose Screen')),
      body: ProposeScreen(),
    ),
  ));
}
