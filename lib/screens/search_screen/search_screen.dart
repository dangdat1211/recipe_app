import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> searchResults = [];
  bool showResults = false;

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      setState(() {
        showResults = true;
        searchResults = List.generate(
          10,
          (index) => {
            'title': 'Recipe $index for "$query"',
            'description': 'Description of recipe $index',
            'image': 'https://via.placeholder.com/150'
          },
        );
      });
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm...',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: _clearSearch,
            ),
          ),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                showResults = false;
              });
            }
          },
          onSubmitted: _onSearchSubmitted,
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: showResults
          ? ListView.builder(
              itemCount: searchResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.network(
                    searchResults[index]['image']!,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(searchResults[index]['title']!),
                  subtitle: Text(searchResults[index]['description']!),
                );
              },
            )
          : Center(
              child: Text('No search results'),
            ),
    );
  }
}
