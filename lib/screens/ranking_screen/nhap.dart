import 'package:flutter/material.dart';

class Recipe {
  final String name;
  final double rating;
  final int hearts;
  final String author;
  final String avatar;

  Recipe({
    required this.name,
    required this.rating,
    required this.hearts,
    required this.author,
    required this.avatar,
  });
}

class RankingScreen extends StatefulWidget {
  const RankingScreen({Key? key}) : super(key: key);

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  List<Recipe> recipes = [
    Recipe(
      name: 'Recipe 1',
      rating: 4.5,
      hearts: 100,
      author: 'Author 1',
      avatar: 'avatar1.jpg',
    ),
    Recipe(
      name: 'Recipe 2',
      rating: 4.3,
      hearts: 95,
      author: 'Author 2',
      avatar: 'avatar2.jpg',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ranking'),
      ),
      body: ListView.builder(
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          final rank = index + 1;

          return ListTile(
            leading: rank <= 3
                ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: rank == 1
                          ? Colors.amber
                          : rank == 2
                              ? Colors.grey
                              : Colors.brown,
                    ),
                    child: Center(
                      child: Text(
                        rank.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    width: 30,
                    height: 30,
                  )
                : null,
            title: Text(recipe.name),
            subtitle: Text('Rating: ${recipe.rating.toString()} Hearts: ${recipe.hearts.toString()}'),
            trailing: CircleAvatar(
              backgroundImage: AssetImage(recipe.avatar),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: RankingScreen(),
  ));
}
