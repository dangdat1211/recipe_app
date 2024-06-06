import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:recipe_app/widgets/input_form.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final TextEditingController _fullnameController = TextEditingController();
  final FocusNode _fullnameFocusNode = FocusNode();

  String? _fullnameError;


  Uint8List? _image;
  File? selectedIMage;

  Future _pickImageFromGallery() async {
    try {
      final returnImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (returnImage == null) return;
      setState(() {
        selectedIMage = File(returnImage.path);
        _image = File(returnImage.path).readAsBytesSync();
      });
      Navigator.of(context).pop();
    } on PlatformException catch (e) {
      print('Faile to pick image');
    }
  }

//Camera
  Future _pickImageFromCamera() async {
    try {
      final returnImage =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (returnImage == null) return;
      setState(() {
        selectedIMage = File(returnImage.path);
        _image = File(returnImage.path).readAsBytesSync();
      });
      Navigator.of(context).pop();
    } on PlatformException catch (e) {
      print('Faile to pick image');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sửa hồ sơ'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    _image != null
                        ? CircleAvatar(
                            radius: 50, backgroundImage: MemoryImage(_image!))
                        : const CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage(
                                "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png"),
                          ),
                    Positioned(
                        bottom: -4,
                        left: 60,
                        child: IconButton(
                            onPressed: () {
                              showImagePickerOption(context);
                            },
                            icon: const Icon(Icons.add_a_photo)))
                  ],
                ),
                SizedBox(height: 10,),
                Text('Thay đổi ảnh hồ sơ'),
                SizedBox(height: 20,),
                InputForm(
                  controller: _fullnameController, 
                  focusNode: _fullnameFocusNode, 
                  errorText: _fullnameError, 
                  label: 'Tên hồ sơ'
                ),
                SizedBox(height: 10,),
                InputForm(
                  controller: _fullnameController, 
                  focusNode: _fullnameFocusNode, 
                  errorText: _fullnameError, 
                  label: 'username'
                ),
                SizedBox(height: 10,),
                InputForm(
                  controller: _fullnameController, 
                  focusNode: _fullnameFocusNode, 
                  errorText: _fullnameError, 
                  label: 'Tiểu sử'
                ),
                SizedBox(height: 10,),
                GestureDetector(
                onTap: () {
                  String email = _fullnameController.text;

                  setState(() {
                    _fullnameError =
                        email.isEmpty ? 'Email cannot be empty' : null;
                  });

                  if (_fullnameError == null ) {
                    
                  }
                },
                child: Container(
                  height: 50,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Color(0xFFFF7622),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'Lưu cập nhật',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showImagePickerOption(BuildContext context) {
    showModalBottomSheet(
        backgroundColor: Colors.blue[100],
        context: context,
        builder: (builder) {
          return Padding(
            padding: const EdgeInsets.all(18.0),
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 4.5,
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _pickImageFromGallery();
                      },
                      child: const SizedBox(
                        child: Column(
                          children: [
                            Icon(
                              Icons.image,
                              size: 70,
                            ),
                            Text("Gallery")
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        _pickImageFromCamera();
                      },
                      child: const SizedBox(
                        child: Column(
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 70,
                            ),
                            Text("Camera")
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
