import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  final List<TextEditingController> _ingredientsControllers = [];
  final List<TextEditingController> _stepsControllers = [];
  final List<List<File?>> _stepsImages = [];

  Future<void> _pickImage(int stepIndex, int imageIndex) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _stepsImages[stepIndex][imageIndex] = File(pickedFile.path);
      });
    }
  }

  void _removeImage(int stepIndex, int imageIndex) {
    setState(() {
      _stepsImages[stepIndex][imageIndex] = null;
    });
  }

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

  void _addStepField() {
    setState(() {
      _stepsControllers.add(TextEditingController());
      _stepsImages.add(List<File?>.filled(3, null));
    });
  }

  void _removeStepField(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
      _stepsImages.removeAt(index);
    });
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
            onPressed: () {},
            child: Text('Đăng tải'),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _image == null
                ? GestureDetector(
                    onTap: () async {
                      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
            SizedBox(height: 16.0),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên món ăn',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Mô tả',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _servingsController,
              decoration: InputDecoration(
                labelText: 'Khẩu phần',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _timeController,
              decoration: InputDecoration(
                labelText: 'Thời gian nấu',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              'Nguyên liệu',
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Column(
              children: _ingredientsControllers
                  .asMap()
                  .map((index, controller) => MapEntry(
                        index,
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Nguyên liệu ${index + 1}',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeIngredientField(index),
                              icon: Icon(Icons.remove_circle),
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
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Column(
              children: _stepsControllers
                  .asMap()
                  .map((index, controller) => MapEntry(
                        index,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: controller,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Bước ${index + 1}',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(3, (imageIndex) {
                                return Stack(
                                  children: [
                                    _stepsImages[index][imageIndex] == null
                                        ? GestureDetector(
                                            onTap: () => _pickImage(index, imageIndex),
                                            child: Container(
                                              height: 100,
                                              width: 100,
                                              color: Colors.grey[300],
                                              child: Icon(
                                                Icons.add_a_photo,
                                                color: Colors.white,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : Image.file(
                                            _stepsImages[index][imageIndex]!,
                                            height: 100,
                                            width: 100,
                                            fit: BoxFit.cover,
                                          ),
                                    _stepsImages[index][imageIndex] != null
                                        ? Positioned(
                                            top: 8,
                                            right: 8,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index, imageIndex),
                                              child: Container(
                                                color: Colors.black54,
                                                child: Icon(
                                                  Icons.delete,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(),
                                  ],
                                );
                              }),
                            ),
                            SizedBox(height: 8.0),
                            IconButton(
                              onPressed: () => _removeStepField(index),
                              icon: Icon(Icons.remove_circle),
                            ),
                            Divider(),
                          ],
                        ),
                      ))
                  .values
                  .toList(),
            ),
            SizedBox(height: 16.0),
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
