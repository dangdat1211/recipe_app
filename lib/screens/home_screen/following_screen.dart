import 'package:flutter/material.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({super.key});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Danh sách công thức'),
                ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    return Container(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ItemRecipe(
                            name:
                                'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                            star: '4.3',
                            favorite: '2000',
                            avatar: '',
                            fullname: 'Phạm Duy Đạt',
                            image: 'assets/food_intro.jpg',
                          ),
                        )
                      ),
                    );
                  },
                ),
              ],
            )
          )
        );
  }
}
