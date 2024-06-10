import 'package:flutter/material.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/widgets/item_recipe.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String dropdownValue = 'Option 1';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Khám phá'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SearchScreen()),
                );
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: MediaQuery.of(context).size.width * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    width: 1,
                    color: Colors.grey,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8.0),
                    Text('Search...'),
                  ],
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Recipes'),
              Tab(text: 'Users'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildRecipeList(),
                buildUserList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRecipeList() {
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

  Widget buildUserList() {
    // Replace this with your actual user list implementation
    return Center(child: Text('User List'));
  }
}

void main() {
  runApp(MaterialApp(
    home: RankingScreen(),
  ));
}
