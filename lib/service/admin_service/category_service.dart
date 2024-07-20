import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryService {
  final CollectionReference _categoriesCollection = 
      FirebaseFirestore.instance.collection('categories');

  // Create
  Future<void> addCategory(String name, String description, String imageUrl) async {
    if (name.isEmpty) {
      throw ArgumentError('Tên danh mục không được để trống');
    }
    
    try {
      await _categoriesCollection.add({
        'name': name,
        'description': description.isEmpty ? null : description,
        'image': imageUrl.isEmpty ? null : imageUrl,
        'createAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi khi thêm danh mục: $e');
    }
  }

  // Read
  Stream<QuerySnapshot> getCategories({
    required String sortBy,
    required bool sortAscending,
  }) {
    if (sortBy.isEmpty) {
      throw ArgumentError('Tiêu chí sắp xếp không được để trống');
    }
    
    try {
      return _categoriesCollection
          .orderBy(sortBy, descending: !sortAscending)
          .snapshots();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách danh mục: $e');
    }
  }

  Future<DocumentSnapshot> getCategoryById(String categoryId) {
    if (categoryId.isEmpty) {
      throw ArgumentError('ID danh mục không được để trống');
    }
    
    try {
      return _categoriesCollection.doc(categoryId).get();
    } catch (e) {
      throw Exception('Lỗi khi lấy thông tin danh mục: $e');
    }
  }

  // Update
  Future<void> updateCategory(String categoryId, String name, String description, String imageUrl) async {
    if (categoryId.isEmpty) {
      throw ArgumentError('ID danh mục không được để trống');
    }
    if (name.isEmpty) {
      throw ArgumentError('Tên danh mục không được để trống');
    }
    
    try {
      await _categoriesCollection.doc(categoryId).update({
        'name': name,
        'description': description.isEmpty ? null : description,
        if (imageUrl.isNotEmpty) 'image': imageUrl,
        'updateAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Lỗi khi cập nhật danh mục: $e');
    }
  }

  // Delete
  Future<void> deleteCategory(String categoryId) async {
    if (categoryId.isEmpty) {
      throw ArgumentError('ID danh mục không được để trống');
    }
    
    try {
      await _categoriesCollection.doc(categoryId).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa danh mục: $e');
    }
  }
}