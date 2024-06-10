import 'package:flutter/material.dart';

class ManageMyRecipe extends StatefulWidget {
  const ManageMyRecipe({super.key});

  @override
  State<ManageMyRecipe> createState() => _ManageMyRecipeState();
}

class _ManageMyRecipeState extends State<ManageMyRecipe>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;
  String sortOption = 'Newest';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildRecipeList(String status) {
    // Dummy data for demonstration
    final recipes = List.generate(10, (index) => {
      'name': 'Recipe $index',
      'description': 'Description for Recipe $index',
      'cover': 'https://via.placeholder.com/150',
    });

    return ListView.builder(
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Image.network(recipes[index]['cover']!),
          title: Text(recipes[index]['name']!),
          subtitle: Text(recipes[index]['description']!),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý công thức'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tất cả'),
            Tab(text: 'Đợi phê duyệt'),
            Tab(text: 'Đã được phê duyệt'),
            Tab(text: 'Bị từ chối'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to search screen
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                SizedBox(width: 8.0),
                DropdownButton<String>(
                  value: sortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      sortOption = newValue!;
                    });
                  },
                  items: <String>['Newest', 'Oldest', 'Most Popular', 'Least Popular']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildRecipeList('Tất cả'),
                buildRecipeList('Đợi phê duyệt'),
                buildRecipeList('Đã được phê duyệt'),
                buildRecipeList('Bị từ chối'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}