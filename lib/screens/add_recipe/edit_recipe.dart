import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/user_service.dart';

class EditRecipeScreen extends StatefulWidget {
  final String recipeId;

  const EditRecipeScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  _EditRecipeScreenState createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  final List<TextEditingController> _stepsControllers = [];
  final List<List<File>> _stepsImages = [];

  User? currentUser = FirebaseAuth.instance.currentUser;

  bool _isLoading = false;
  String _selectedDifficulty = 'Trung bình';
  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _allCategories = [];
  bool _showCategories = false;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
  final categoriesSnapshot = await FirebaseFirestore.instance.collection('categories').get();
  setState(() {
    _allCategories = categoriesSnapshot.docs.map((doc) => {
      'id': doc.id,
      'name': doc['name'],
    }).toList();
  });
}

  Future<void> _loadRecipeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();

      if (recipeSnapshot.exists) {
        Map<String, dynamic> recipeData =
            recipeSnapshot.data() as Map<String, dynamic>;
        _selectedCategories = List<String>.from(recipeData['categories'] ?? []);

        _nameController.text = recipeData['namerecipe'] ?? '';
        _descriptionController.text = recipeData['description'] ?? '';
        _servingsController.text = recipeData['ration'] ?? '';
        _timeController.text = recipeData['time'] ?? '';
        _youtubeController.text = recipeData['urlYoutube'] ?? '';
        _selectedDifficulty = recipeData['level'] ?? 'Trung bình';

        List<dynamic> ingredientsList = recipeData['ingredients'] ?? [];
        for (String ingredient in ingredientsList) {
          _ingredientsControllers.add(TextEditingController(text: ingredient));
        }

        List<dynamic> stepIds = recipeData['steps'] ?? [];
        for (int i = 0; i < stepIds.length; i++) {
          String stepId = stepIds[i];
          DocumentSnapshot stepSnapshot = await FirebaseFirestore.instance
              .collection('steps')
              .doc(stepId)
              .get();

          if (stepSnapshot.exists) {
            Map<String, dynamic> stepData =
                stepSnapshot.data() as Map<String, dynamic>;
            _stepsControllers
                .add(TextEditingController(text: stepData['title'] ?? ''));

            List<dynamic> stepImageUrls = stepData['images'] ?? [];
            List<File> stepImages = [];
            for (String imageUrl in stepImageUrls) {
              File? imageFile = await _getImageFileFromUrl(imageUrl);
              if (imageFile != null) {
                stepImages.add(imageFile);
              }
            }
            _stepsImages.add(stepImages);
          }
        }

        String? imageUrl = recipeData['image'];
        if (imageUrl != null && imageUrl.isNotEmpty) {
          File? imageFile = await _getImageFileFromUrl(imageUrl);
          if (imageFile != null) {
            setState(() {
              _image = imageFile;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading recipe data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<File?> _getImageFileFromUrl(String url) async {
    try {
      final fileUrl = Uri.parse(url);
      final fileBytes = await readBytes(fileUrl);
      final fileName = path.basename(fileUrl.path);
      final file = File('${Directory.systemTemp.path}/$fileName');
      await file.writeAsBytes(fileBytes);
      return file;
    } catch (e) {
      print('Error getting image file from URL: $e');
      return null;
    }
  }

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

  Future<void> _updateRecipe() async {
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _servingsController.text.isEmpty ||
        _timeController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot recipeSnapshot = await FirebaseFirestore.instance
          .collection('recipes')
          .doc(widget.recipeId)
          .get();
      Map<String, dynamic> currentRecipeData =
          recipeSnapshot.data() as Map<String, dynamic>;

      String? mainImageUrl;
      if (_image != null) {
        mainImageUrl = await _uploadFile(_image!);
      }

      final ingredients =
          _ingredientsControllers.map((controller) => controller.text).toList();

      final recipeData = {
        'namerecipe': _nameController.text,
        'description': _descriptionController.text,
        'ration': _servingsController.text,
        'time': _timeController.text,
        'ingredients': ingredients,
        'steps': [],
        'image': mainImageUrl ?? '',
        'level': _selectedDifficulty,
        // 'likes': [],
        'rates': [],
        'comments': [],
        'status': 'Đợi phê duyệt',
        'userID': currentUser!.uid,
        'urlYoutube': _youtubeController.text,
        'updateAt': FieldValue.serverTimestamp(),
        'categories': _selectedCategories,  
      };

      DocumentReference recipeDoc =
          FirebaseFirestore.instance.collection('recipes').doc(widget.recipeId);
      await recipeDoc.update(recipeData);

      CollectionReference stepsCollection =
          FirebaseFirestore.instance.collection('steps');

      List<String> stepIds = [];

      List<dynamic>? oldStepIds = currentRecipeData['steps'] as List<dynamic>?;
      if (oldStepIds != null) {
        for (String oldStepId in oldStepIds) {
          await stepsCollection.doc(oldStepId).delete();
        }
      }

      for (int i = 0; i < _stepsControllers.length; i++) {
        final stepText = _stepsControllers[i].text;
        final stepImages = _stepsImages[i];
        final stepImageUrls = [];
        for (File image in stepImages) {
          final imageUrl = await _uploadFile(image);
          stepImageUrls.add(imageUrl);
        }

        DocumentReference? existingStepDoc;
        List<dynamic>? stepList = recipeData['steps'] as List<dynamic>?;
        if (stepList != null && i < stepList.length) {
          existingStepDoc = await stepsCollection.doc(stepList[i]);
        } else {
          existingStepDoc = stepsCollection.doc();
        }

        await existingStepDoc.set({
          'title': stepText,
          'images': stepImageUrls,
          'recipeID': widget.recipeId,
          'order': i + 1,
        });

        stepIds.add(existingStepDoc.id);
      }

      await recipeDoc.update({'steps': stepIds});

      UserService userService = UserService();
      List<Map<String, dynamic>> adminInfo =
          await userService.getAdminFCMTokens();

      for (var admin in adminInfo) {
        // Gửi thông báo trong ứng dụng
        await NotificationService().createNotification(
            content: 'Có công thức mới cần phê duyệt',
            fromUser: currentUser!.uid,
            userId: admin['userId']!,
            recipeId: widget.recipeId,
            screen: 'approve');

        // Gửi FCM notification
        if (admin['fcmToken'] != null && admin['fcmToken']!.isNotEmpty) {
          await NotificationService.sendNotification(admin['fcmToken']!,
              'Khẩn cấp', 'Có công thức mới cần bạn phê duyệt', data: {
            'screen': 'approve',
            'recipeId': widget.recipeId,
            'userId': currentUser!.uid
          });
        }
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ManageMyRecipe()),
      );

      SnackBarCustom.showbar(context, 'Công thức đã được cập nhật thành công');

    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      SnackBarCustom.showbar(context, 'Đã xảy ra lỗi: $e');

      
    }
  }

  Widget _buildCategoriesSelector() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () {
          setState(() {
            _showCategories = !_showCategories;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            // color: Colors.grey[200],
            border: Border.all(width: 1, color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chọn danh mục',
                style: TextStyle(fontSize: 16.0, ),
              ),
              Icon(_showCategories ? Icons.arrow_drop_up : Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
      if (_showCategories) ...[
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _allCategories.length,
            itemBuilder: (context, index) {
              final category = _allCategories[index];
              return CheckboxListTile(
                title: Text(category['name']),
                value: _selectedCategories.contains(category['id']),
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedCategories.add(category['id']);
                    } else {
                      _selectedCategories.remove(category['id']);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              );
            },
          ),
        ),
      ],
      SizedBox(height: 8),
      if (_selectedCategories.isNotEmpty)
        Wrap(
          spacing: 8,
          children: _selectedCategories.map((categoryId) {
            final category = _allCategories.firstWhere((cat) => cat['id'] == categoryId);
            return Chip(
              label: Text(category['name'], style: TextStyle(color: mainColor),),
              onDeleted: () {
                setState(() {
                  _selectedCategories.remove(categoryId);
                });
              },
            );
          }).toList(),
        ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chỉnh sửa công thức'),
        actions: [
          TextButton(
            onPressed: _updateRecipe,
            child: Text('Lưu'),
          ),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert))
        ],
      ),
      body: _isLoading
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
                    maxLines: null,
                    minLines: 1,
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Tên món ăn',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    minLines: 1,
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    minLines: 1,
                    controller: _servingsController,
                    decoration: InputDecoration(
                      labelText: 'Khẩu phần',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    minLines: 1,
                    controller: _timeController,
                    decoration: InputDecoration(
                      labelText: 'Thời gian nấu',
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
                        child: Text(value, style: TextStyle(fontWeight: FontWeight.normal)),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDifficulty = newValue!;
                      });
                    },
                  ),
                  SizedBox(height: 10.0),
                  _buildCategoriesSelector(),
                  SizedBox(height: 10.0),
                  TextField(
                    maxLines: null,
                    minLines: 1,
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
                                          maxLines:
                                              null, // Không giới hạn số dòng
                                          minLines:
                                              1, // Chiều cao tối thiểu là 3 dòng
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
                                        .map((image) => Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Stack(
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
                                              ),
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
