import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:recipe_app/screens/onbroading_screen/onbroading_screen.dart';
import 'package:recipe_app/screens/ranking_screen/ranking_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RankingScreen()),
      );
        },
        child: Text('Search Screen')),

    );
  }
}