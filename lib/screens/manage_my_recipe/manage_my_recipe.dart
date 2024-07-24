import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/add_recipe/edit_recipe.dart';
import 'package:recipe_app/screens/detail_recipe.dart/detail_recipe.dart';

class ManageMyRecipe extends StatefulWidget {
  const ManageMyRecipe({super.key});

  @override
  State<ManageMyRecipe> createState() => _ManageMyRecipeState();
}

class _ManageMyRecipeState extends State<ManageMyRecipe>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String currentSortOption = 'Mới nhất';
  TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchResults = [];
  bool isLoading = false;

  User? currentUser = FirebaseAuth.instance.currentUser;

  Map<String, List<String>> selectedFilters = {
    'difficulty': [],
    'time': [],
    'method': [],
  };

  int itemsPerPage = 10;
  int currentPage = 1;
  List<Map<String, dynamic>> paginatedResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadRecipes() async {
    setState(() {
      isLoading = true;
    });

    final snapshot = await FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: currentUser!.uid)
        .get();

    searchResults = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    _applyFiltersAndSort();

    setState(() {
      isLoading = false;
      currentPage = 1;
      updatePaginatedResults();
    });
  }

  void updatePaginatedResults() {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > searchResults.length) {
      endIndex = searchResults.length;
    }
    paginatedResults = searchResults.sublist(startIndex, endIndex);
  }

  Future<void> _fetchFilteredData() async {
    setState(() {
      isLoading = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('recipes')
        .where('userID', isEqualTo: currentUser!.uid);

    // Áp dụng các bộ lọc
    if (selectedFilters['difficulty']!.isNotEmpty) {
      query = query.where('level', whereIn: selectedFilters['difficulty']);
    }

    if (selectedFilters['time']!.isNotEmpty) {
      // Xử lý lọc thời gian (cần thêm logic phức tạp hơn)
    }

    // Lấy dữ liệu
    final snapshot = await query.get();

    searchResults = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return data;
    }).toList();

    searchResults = searchResults.where((recipe) {
    bool timeMatch = selectedFilters['time']!.isEmpty ||
        selectedFilters['time']!.any((timeFilter) {
          int recipeCookingTime = int.tryParse(
                  recipe['time'].toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
              0;
          if (timeFilter == '< 30 phút') {
            return recipeCookingTime < 30;
          } else if (timeFilter == '30-60 phút') {
            return recipeCookingTime >= 30 && recipeCookingTime <= 60;
          } else if (timeFilter == '> 60 phút') {
            return recipeCookingTime > 60;
          }
          return false;
        });

    bool methodMatch = selectedFilters['method']!.isEmpty ||
        selectedFilters['method']!.any((method) =>
            recipe['namerecipe']
                .toString()
                .toLowerCase()
                .contains(method.toLowerCase()));

    return timeMatch && methodMatch;
  }).toList();

    // Áp dụng lọc phương pháp và sắp xếp
    _applyMethodFilterAndSort();

    setState(() {
      isLoading = false;
      currentPage = 1;
      updatePaginatedResults();
    });
  }

  void _applyMethodFilterAndSort() {
    // Lọc theo phương pháp
    if (selectedFilters['method']!.isNotEmpty) {
      searchResults = searchResults.where((recipe) {
        return selectedFilters['method']!.any((method) =>
            recipe['namerecipe']
                .toString()
                .toLowerCase()
                .contains(method.toLowerCase()));
      }).toList();
    }

    // Sắp xếp kết quả
    searchResults.sort((a, b) {
      switch (currentSortOption) {
        case 'Mới nhất':
          return (b['createAt'] as Timestamp)
              .compareTo(a['createAt'] as Timestamp);
        case 'Cũ nhất':
          return (a['createAt'] as Timestamp)
              .compareTo(b['createAt'] as Timestamp);
        case 'Yêu thích nhiều':
          return (b['likes'] as List).length.compareTo((a['likes'] as List).length);
        case 'Yêu thích ít':
          return (a['likes'] as List).length.compareTo((b['likes'] as List).length);
        default:
          return 0;
      }
    });
  }

  void _applyFiltersAndSort() async {
    await _fetchFilteredData();
  }

  void _handlePopupMenuSelection(String value, String recipeId) async {
    switch (value) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EditRecipeScreen(
                    recipeId: recipeId,
                  )),
        );
        break;
      case 'delete':
        bool? confirmDelete = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Xác nhận xóa'),
              content: Text('Bạn có chắc chắn muốn xóa công thức này không?'),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                TextButton(
                  child: Text('Xóa'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                ),
              ],
            );
          },
        );

        if (confirmDelete == true) {
          await _deleteRecipe(recipeId);
        }
        break;
      case 'hide':
        await _hideRecipe(recipeId);
        break;
      case 'show':
        await _showRecipe(recipeId);
        break;
    }
  }

  Future<void> _deleteRecipe(String recipeId) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      batch.delete(
          FirebaseFirestore.instance.collection('recipes').doc(recipeId));

      QuerySnapshot rateSnapshots = await FirebaseFirestore.instance
          .collection('rates')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in rateSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot commentSnapshots = await FirebaseFirestore.instance
          .collection('comments')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in commentSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot favoriteSnapshots = await FirebaseFirestore.instance
          .collection('favorites')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in favoriteSnapshots.docs) {
        batch.delete(doc.reference);
      }

      QuerySnapshot stepSnapshots = await FirebaseFirestore.instance
          .collection('steps')
          .where('recipeId', isEqualTo: recipeId)
          .get();
      for (var doc in stepSnapshots.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      SnackBarCustom.showbar(context, 'Xóa thành công');

      _loadRecipes();
    } catch (e) {
      print('Lỗi khi xóa công thức và dữ liệu liên quan: $e');
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi xóa công thức và dữ liệu liên quan');
    }
  }

  Future<void> _hideRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': true,
      });
      SnackBarCustom.showbar(context, 'Công thức đã được ẩn');
      _loadRecipes();
    } catch (e) {
      print('Lỗi khi ẩn công thức: $e');
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi ẩn công thức');
    }
  }

  Future<void> _showRecipe(String recipeId) async {
    try {
      await FirebaseFirestore.instance
          .collection('recipes')
          .doc(recipeId)
          .update({
        'hidden': false,
      });
      SnackBarCustom.showbar(context, 'Công thức đã được hiện');
      _loadRecipes();
    } catch (e) {
      print('Lỗi khi hiện công thức: $e');
      SnackBarCustom.showbar(context, 'Có lỗi xảy ra khi hiện công thức');
    }
  }

  Widget buildRecipeList(String status) {
    var filteredRecipes = paginatedResults.where((recipe) {
      return status.isEmpty || recipe['status'] == status;
    }).toList();

    if (filteredRecipes.isEmpty) {
      return Center(child: Text('Không có công thức nào'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: filteredRecipes.length,
            itemBuilder: (context, index) {
              var recipe = filteredRecipes[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailReCipe(
                          recipeId: recipe['id'], userId: currentUser!.uid),
                    ),
                  );
                },
                child: ListTile(
                  leading: Container(
                    width: 80,
                    height: 80,
                    child: Image.network(
                      recipe['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.error);
                        },
                    ),
                  ),
                  title: Text(
                    recipe['namerecipe'],
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['description'],
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      Text(
                        'Trạng thái: ${recipe['status']}',
                        style: TextStyle(
                          color: getStatusColor(recipe['status']),
                        ),
                      ),
                      Text(
                        recipe['hidden'] ? 'Đang ẩn' : '',
                        style: TextStyle(
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) =>
                        _handlePopupMenuSelection(value, recipe['id']),
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Sửa'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('Xóa'),
                      ),
                      PopupMenuItem<String>(
                        value: recipe['hidden'] ? 'show' : 'hide',
                        child: Text(recipe['hidden'] ? 'Hiện' : 'Ẩn'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        buildPaginationControls(),
      ],
    );
  }

  Widget buildPaginationControls() {
    int totalPages = (searchResults.length / itemsPerPage).ceil();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left),
          onPressed: currentPage > 1
              ? () {
                  setState(() {
                    currentPage--;
                    updatePaginatedResults();
                  });
                }
              : null,
        ),
        Text('Trang $currentPage / $totalPages'),
        IconButton(
          icon: Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () {
                  setState(() {
                    currentPage++;
                    updatePaginatedResults();
                  });
                }
              : null,
        ),
      ],
    );
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'Đợi phê duyệt':
        return Colors.orange;
      case 'Đã được phê duyệt':
        return Colors.green;
      case 'Bị từ chối':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Lọc và Sắp xếp', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Container(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _buildSortingSection(setState),
                    _buildFilterSection('Độ khó', 'difficulty', ['Dễ', 'Trung bình', 'Khó'], setState),
                    _buildFilterSection('Thời gian', 'time', ['< 30 phút', '30-60 phút', '> 60 phút'], setState),
                    _buildFilterSection('Phương pháp', 'method', ['Rán', 'Xào', 'Nướng', 'Hấp'], setState),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Hủy', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  child: Text('Áp dụng'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applyFiltersAndSort();
                  },
                ),
              ],
            );
          },
        );
      },
      );
  }

  Widget _buildSortingSection(StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sắp xếp theo:', style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: DropdownButton<String>(
            value: currentSortOption,
            onChanged: (String? newValue) {
              setState(() => currentSortOption = newValue!);
            },
            items: ['Mới nhất', 'Cũ nhất', 'Yêu thích nhiều', 'Yêu thích ít']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            isExpanded: true,
            underline: SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(String title, String filterType, List<String> options, StateSetter setState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: options.map((option) {
            bool isSelected = selectedFilters[filterType]!.contains(option);
            return FilterChip(
              showCheckmark: false,
              label: Text(option),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedFilters[filterType]!.add(option);
                  } else {
                    selectedFilters[filterType]!.remove(option);
                  }
                });
              },
              backgroundColor: Colors.grey[200],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
            );
          }).toList(),
        ),
        SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý công thức'),
        centerTitle: true,
        bottom: TabBar(
          dividerColor: Colors.transparent,
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
                  child: Container(
                    height: 40,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchResults = searchResults.where((recipe) {
                            return recipe['namerecipe']
                                .toString()
                                .toLowerCase()
                                .contains(value.toLowerCase());
                          }).toList();
                          currentPage = 1;
                          updatePaginatedResults();
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                IconButton(
                  icon: Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      buildRecipeList(''),
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