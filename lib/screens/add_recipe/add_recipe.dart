import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/recipe_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _selectedDifficulty = 'Trung bình';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  final List<TextEditingController> _stepsControllers = [];
  final List<List<File>> _stepsImages = [];

  User? currentUser = FirebaseAuth.instance.currentUser;

  RecipeService _recipeService = RecipeService();

  bool _isLoading = false; 

  void _addStepField() {
    setState(() {
      _stepsControllers.add(TextEditingController());
      _stepsImages.add([]);
    });
  }

  void _removeStepField(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
      _stepsImages.removeAt(index);
    });
  }

  Future<void> _pickStepImages(int index) async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _stepsImages[index] = pickedFiles.map((e) => File(e.path)).toList();
      });
    }
  }

  final List<TextEditingController> _ingredientsControllers = [];
  void _addIngredientField() {
    setState(() {
      _ingredientsControllers.add(TextEditingController());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredientsControllers.removeAt(index);
    });
  }

  Future<String> _uploadFile(File file) async {
    String fileName = path.basename(file.path) +
        '_' +
        DateTime.now().millisecondsSinceEpoch.toString();
    Reference storageReference =
        FirebaseStorage.instance.ref().child('recipes/$fileName');
    SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
    UploadTask uploadTask = storageReference.putFile(file, metadata);
    await uploadTask.whenComplete(() => null);
    return await storageReference.getDownloadURL();
  }

  Future<void> _uploadRecipe() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _servingsController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _image == null ||
        _ingredientsControllers.any((controller) => controller.text.isEmpty) ||
        _stepsControllers.any((controller) => controller.text.isEmpty)) {
      SnackBarCustom.showbar(context, 'Vui lòng điền đầy đủ tất cả các trường bắt buộc và chọn ảnh chính.');
      return;
    }

  setState(() {
    _isLoading = true;
  });

  try {
    String? mainImageUrl;
    if (_image != null) {
      mainImageUrl = await _uploadFile(_image!);
    }

    List<List<String>> stepImageUrls = [];
    for (var stepImages in _stepsImages) {
      List<String> urls = [];
      for (var image in stepImages) {
        String url = await _uploadFile(image);
        urls.add(url);
      }
      stepImageUrls.add(urls);
    }

    final ingredients = _ingredientsControllers.map((controller) => controller.text).toList();
    final steps = _stepsControllers.map((controller) => controller.text).toList();

    final recipe = RecipeModel(
      namerecipe: _nameController.text,
      description: _descriptionController.text,
      ration: _servingsController.text,
      time: _timeController.text,
      ingredients: ingredients,
      steps: steps,
      image: mainImageUrl ?? '',
      userID: currentUser!.uid,
      urlYoutube: _youtubeController.text,
    );

    await _recipeService.uploadRecipe(recipe, mainImageUrl, stepImageUrls);

    setState(() {
      _isLoading = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ManageMyRecipe()),
    );
  } catch (e) {
    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã xảy ra lỗi: $e')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Lưu'),
          ),
          TextButton(
            onPressed: _uploadRecipe,
            child: Text('Đăng tải'),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))
        ],
      ),
      body: _isLoading // Hiển thị vòng tròn xoay khi đang tải lên
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _image == null
                      ? GestureDetector(
                          onTap: () async {
                            final pickedFile = await _picker.pickImage(
                                source: ImageSource.gallery);
                            if (pickedFile != null) {
                              setState(() {
                                _image = File(pickedFile.path);
                              });
                            }
                          },
                          child: Container(
                            height: 200,
                            width: double.infinity,
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.add_a_photo,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        )
                      : Stack(
                          children: [
                            Image.file(
                              _image!,
                              height: 200,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _image = null;
                                  });
                                },
                                child: Container(
                                  color: Colors.black54,
                                  child: Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null, // Không giới hạn số dòng
                    minLines: 1, // Chiều cao tối thiểu là 3 dòng
                    
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên món ăn',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    controller: _descriptionController,
                    maxLines: null, // Không giới hạn số dòng
                    minLines: 1, // Chiều cao tối thiểu là 3 dòng
                    
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null, // Không giới hạn số dòng
                    minLines: 1, // Chiều cao tối thiểu là 3 dòng
                    
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Khẩu phần',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  DropdownButtonFormField<String>(
                    value: _selectedDifficulty,
                    decoration: InputDecoration(
                      labelText: 'Độ khó',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: <String>['Dễ', 'Trung bình', 'Khó']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDifficulty = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null, // Không giới hạn số dòng
                    minLines: 1, // Chiều cao tối thiểu là 3 dòng
                    
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Thời gian nấu',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null, // Không giới hạn số dòng
                    minLines: 1, // Chiều cao tối thiểu là 3 dòng
                    
                    controller: _youtubeController,
                    decoration: InputDecoration(
                      labelText: 'Video youtube hướng dẫn',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Nguyên liệu',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: _ingredientsControllers
                        .asMap()
                        .map((index, controller) => MapEntry(
                              index,
                              Column(
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          maxLines:
                                              null, // Không giới hạn số dòng
                                          minLines:
                                              1, // Chiều cao tối thiểu là 3 dòng
                                          
                                          controller: controller,
                                          decoration: InputDecoration(
                                            labelText:
                                                'Nguyên liệu ${index + 1}',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeIngredientField(index),
                                        icon: Icon(Icons.remove_circle),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ))
                        .values
                        .toList(),
                  ),
                  SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _addIngredientField,
                    child: Text('Thêm nguyên liệu'),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Cách làm',
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  Column(
                    children: _stepsControllers
                        .asMap()
                        .map((index, controller) => MapEntry(
                              index,
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          maxLines: null, // Không giới hạn số dòng
                                          minLines: 1, // Chiều cao tối thiểu là 3 dòng
                                          
                                          controller: controller,
                                          decoration: InputDecoration(
                                            labelText: 'Bước ${index + 1}',
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeStepField(index),
                                        icon: Icon(Icons.remove_circle),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.0),
                                  Wrap(
                                    children: _stepsImages[index]
                                        .map((image) => Stack(
                                              children: [
                                                Image.file(
                                                  image,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                                Positioned(
                                                  top: 0,
                                                  right: 0,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        _stepsImages[index]
                                                            .remove(image);
                                                      });
                                                    },
                                                    child: Container(
                                                      color: Colors.black54,
                                                      child: Icon(
                                                        Icons.delete,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ))
                                        .toList(),
                                  ),
                                  TextButton(
                                    onPressed: () => _pickStepImages(index),
                                    child:
                                        Text('Chọn ảnh cho bước ${index + 1}'),
                                  ),
                                  SizedBox(height: 16.0),
                                ],
                              ),
                            ))
                        .values
                        .toList(),
                  ),
                  ElevatedButton(
                    onPressed: _addStepField,
                    child: Text('Thêm bước'),
                  ),
                ],
              ),
            ),
    );
  }
}
