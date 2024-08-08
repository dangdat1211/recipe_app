import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:recipe_app/constants/colors.dart';
import 'package:recipe_app/helpers/snack_bar_custom.dart';
import 'package:recipe_app/models/recipe_model.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:recipe_app/service/notification_service.dart';
import 'package:recipe_app/service/recipe_service.dart';
import 'package:recipe_app/service/user_service.dart';

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String _selectedDifficulty = 'Trung bình';

  String _selectedPrivacy = 'public';

  List<String> _selectedCategories = [];
  List<Map<String, dynamic>> _allCategories = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _servingsController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _youtubeController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _servingsFocus = FocusNode();
  final FocusNode _timeFocus = FocusNode();
  final FocusNode _youtubeFocus = FocusNode();

  final List<TextEditingController> _stepsControllers = [];
  final List<List<File>> _stepsImages = [];
  final List<FocusNode> _stepsFocusNodes = [];

  User? currentUser = FirebaseAuth.instance.currentUser;

  RecipeService _recipeService = RecipeService();

  bool _isLoading = false;
  bool _showCategories = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _addStepField() {
    setState(() {
      _stepsControllers.add(TextEditingController());
      _stepsImages.add([]);
      _stepsFocusNodes.add(FocusNode());
    });
  }

  Future<void> _loadCategories() async {
    final categoriesSnapshot =
        await FirebaseFirestore.instance.collection('categories').get();
    setState(() {
      _allCategories = categoriesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc['name'],
              })
          .toList();
    });
  }

  void _removeStepField(int index) {
    setState(() {
      _stepsControllers.removeAt(index);
      _stepsImages.removeAt(index);
      _stepsFocusNodes[index].dispose();
      _stepsFocusNodes.removeAt(index);
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
  final List<TextEditingController> _ingredientQuantityControllers = [];

  final List<FocusNode> _ingredientsFocusNodes = [];

  void _addIngredientField() {
    setState(() {
      _ingredientsControllers.add(TextEditingController());
      _ingredientQuantityControllers.add(TextEditingController());
      _ingredientsFocusNodes.add(FocusNode());
    });
  }

  void _removeIngredientField(int index) {
    setState(() {
      _ingredientsControllers.removeAt(index);
      _ingredientsFocusNodes[index].dispose();
      _ingredientsFocusNodes.removeAt(index);
      _ingredientQuantityControllers.removeAt(index);
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

    if ( _image == null) {
      SnackBarCustom.showbar(context,
          'Chưa chọn ảnh bìa cho công thức');
      return;
    }
    if (_nameController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _servingsController.text.isEmpty ||
        _timeController.text.isEmpty ||
        _ingredientsControllers.any((controller) => controller.text.isEmpty) ||
        _stepsControllers.any((controller) => controller.text.isEmpty)) {
      SnackBarCustom.showbar(context,
          'Vui lòng điền đầy đủ tất cả các trường bắt buộc và chọn ảnh chính.');
      return;
    }

    if (_ingredientsControllers.isEmpty || 
      _stepsControllers.isEmpty) {
        SnackBarCustom.showbar(context,
          'Công thức phải có nguyên liệu và các bước thực hiện');
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

      final steps =
          _stepsControllers.map((controller) => controller.text).toList();

      final ingredients = List.generate(
        _ingredientsControllers.length,
        (index) => {
          'name': _ingredientsControllers[index].text,
          'quality': _ingredientQuantityControllers[index].text,
        },
      );

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
          categories: _selectedCategories,
          area: _selectedPrivacy,
          level: _selectedDifficulty);
          

      String recipeId = await _recipeService.uploadRecipe(
          recipe, mainImageUrl, stepImageUrls);

      UserService userService = UserService();
      List<Map<String, dynamic>> adminInfo =
          await userService.getAdminFCMTokens();

      for (var admin in adminInfo) {
        // Gửi thông báo trong ứng dụng
        await NotificationService().createNotification(
            content: 'Có công thức mới cần phê duyệt',
            fromUser: currentUser!.uid,
            userId: admin['userId']!,
            recipeId: recipeId,
            screen: 'approve');

        // Gửi FCM notification
        if (admin['fcmToken'] != null && admin['fcmToken']!.isNotEmpty) {
          await NotificationService.sendNotification(admin['fcmToken']!,
              'Khẩn cấp', 'Có công thức mới cần bạn phê duyệt', data: {
            'screen': 'approve',
            'recipeId': recipeId,
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
              border: Border.all(width: 1, color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chọn danh mục',
                  style: TextStyle(
                    fontSize: 16.0,
                  ),
                ),
                Icon(_showCategories
                    ? Icons.arrow_drop_up
                    : Icons.arrow_drop_down),
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
                  title: Text(
                    category['name'],
                  ),
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
              final category =
                  _allCategories.firstWhere((cat) => cat['id'] == categoryId);
              return Chip(
                label: Text(
                  category['name'],
                  style: TextStyle(color: mainColor),
                ),
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

  Widget requiredLabel(String label) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(color: Colors.black87),
        children: [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _descriptionFocus.dispose();
    _servingsFocus.dispose();
    _timeFocus.dispose();
    _youtubeFocus.dispose();
    for (var focus in _stepsFocusNodes) {
      focus.dispose();
    }
    for (var focus in _ingredientsFocusNodes) {
      focus.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Xác nhận'),
            content: Text('Khi bạn quay lại dữ liệu của bạn không được lưu lại!!! Bạn có chắc muốn quay lại ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Không'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Có'),
              ),
            ],
          ),
        );

        if (result ?? false) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        
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
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      textAlign: TextAlign.left,
                      'Các trường có dấu (*) là bắt buộc',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
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
                  DropdownButtonFormField<String>(
                    value: _mapPrivacyToLabel(_selectedPrivacy),
                    decoration: InputDecoration(
                      labelText: 'Quyền riêng tư',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    items: <String>['Công khai', 'Người theo dõi']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(fontWeight: FontWeight.normal),
                        ),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPrivacy = _mapLabelToPrivacy(newValue!);
                      });
                    },
                  ),
                    SizedBox(height: 10.0),
                    TextField(
                      focusNode: _nameFocus,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_descriptionFocus),
                      decoration: InputDecoration(
                          labelText: 'Tên món ăn',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(
                                top:
                                    10), // Thêm padding bên phải để tránh quá sát với viền
                            child: Text(
                              '    *',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          )),
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      focusNode: _descriptionFocus,
                      controller: _descriptionController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_servingsFocus),
                      maxLines: null,
                      minLines: 1,
                      decoration: InputDecoration(
                          labelText: 'Mô tả',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(
                                top:
                                    10), // Thêm padding bên phải để tránh quá sát với viền
                            child: Text(
                              '    *',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          )),
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      focusNode: _servingsFocus,
                      controller: _servingsController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_timeFocus),
                      decoration: InputDecoration(
                        labelText: 'Khẩu phần',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        suffixIcon: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Text(
                            '    *',
                            style: TextStyle(color: Colors.red, fontSize: 16),
                          ),
                        ),
                        suffixText: 'người',
                      ),
                    ),
                    SizedBox(height: 10.0),
                    DropdownButtonFormField<String>(
                      value: _selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Độ khó',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: <String>['Dễ', 'Trung bình', 'Khó']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(fontWeight: FontWeight.normal),
                          ),
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
                      focusNode: _timeFocus,
                      controller: _timeController,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_youtubeFocus),
                      decoration: InputDecoration(
                          labelText: 'Thời gian nấu (phút)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                          suffixIcon: Padding(
                            padding: EdgeInsets.only(
                                top:
                                    10), // Thêm padding bên phải để tránh quá sát với viền
                            child: Text(
                              '    *',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          )),
                    ),
                    SizedBox(height: 10.0),
                    TextField(
                      focusNode: _youtubeFocus,
                      controller: _youtubeController,
                      textInputAction: TextInputAction.done,
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
                      children:
                          List.generate(_ingredientsControllers.length, (index) {
                        return Column(
                          children: [
                            SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _ingredientsControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Tên nguyên liệu ${index + 1}',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: TextField(
                                    controller:
                                        _ingredientQuantityControllers[index],
                                    decoration: InputDecoration(
                                      labelText: 'Định lượng',
                                      border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () => _removeIngredientField(index),
                                ),
                              ],
                            ),
                          ],
                        );
                      }),
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
                                            focusNode: _stepsFocusNodes[index],
                                            controller: controller,
                                            textInputAction: TextInputAction.next,
                                            onSubmitted: (_) {
                                              if (index ==
                                                  _stepsControllers.length - 1) {
                                                _addStepField();
                                              } else {
                                                FocusScope.of(context)
                                                    .requestFocus(
                                                        _stepsFocusNodes[
                                                            index + 1]);
                                              }
                                            },
                                            maxLines: null,
                                            minLines: 1,
                                            decoration: InputDecoration(
                                                labelText: 'Bước ${index + 1}',
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10)),
                                                suffixIcon: Padding(
                                                  padding: EdgeInsets.only(
                                                      top:
                                                          10), // Thêm padding bên phải để tránh quá sát với viền
                                                  child: Text(
                                                    '    *',
                                                    style: TextStyle(
                                                        color: Colors.red,
                                                        fontSize: 16),
                                                  ),
                                                )),
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
                                                padding:
                                                    const EdgeInsets.all(8.0),
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
      ),
    );
  }

  String _mapLabelToPrivacy(String label) {
    switch (label) {
      case 'Công khai':
        return 'public';
      case 'Người theo dõi':
        return 'follower';
      default:
        return 'public';
    }
  }

  String _mapPrivacyToLabel(String privacy) {
    switch (privacy) {
      case 'public':
        return 'Công khai';
      case 'follower':
        return 'Người theo dõi';
      default:
        return 'Công khai';
    }
  }
}
