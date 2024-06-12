import 'package:flutter/material.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class RecipeRanking extends StatefulWidget {
  const RecipeRanking({super.key});

  @override
  State<RecipeRanking> createState() => _RecipeRankingState();
}

class _RecipeRankingState extends State<RecipeRanking> {
  String dropdownValue = 'Option 1';
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                width: MediaQuery.of(context).size.width*0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      onChanged: (String? newValue) {
                        setState(() {
                          dropdownValue = newValue!;
                        });
                      },
                      items: <String>[
                        'Option 1',
                        'Option 2 21312312321321',
                        'Option 3',
                        'Option 4'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Text(value),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: 20,
                    itemBuilder: (context, index) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index + 1 == 1
                                  ? Colors.amber
                                  : index + 1 == 2
                                      ? Colors.grey
                                      : Colors.brown,
                            ),
                            child: Center(
                              child: Text(
                                (index + 1).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            width: 30,
                            height: 30,
                          ),
                          SizedBox(width: 10),
                          Container(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ItemRecipe(
                                  name:
                                      'Cà tím nhồi thịt asdbasd asdbasd asdhgashd ádhaskd',
                                  star: '4.3',
                                  favorite: '2000',
                                  avatar: 'assets/food_intro.jpg',
                                  fullname: 'Phạm Duy Đạt',
                                  image: 'assets/food_intro.jpg',
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
    );
  }
}