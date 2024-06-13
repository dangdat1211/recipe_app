import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  String? _usernameError;

  final TextEditingController _bioController = TextEditingController();
  final FocusNode _bioFocusNode = FocusNode();
  String? _bioError;

  Uint8List? _image;
  File? selectedImage;
  String _getimage = "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png";

  User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      _fullnameController.text = userData['fullname'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _bioController.text = userData['bio'] ?? '';

      if (userData['avatar'] != null) {
        setState(() {
          _getimage = userData['avatar'];
        });
      }
    }
  }

  Future _pickImageFromGallery() async {
    try {
      final returnImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (returnImage == null) return;
      setState(() {
        selectedImage = File(returnImage.path);
        _image = File(returnImage.path).readAsBytesSync();
      });
      Navigator.of(context).pop();
    } on PlatformException catch (e) {
      print('Failed to pick image');
    }
  }

  Future _pickImageFromCamera() async {
    try {
      final returnImage =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (returnImage == null) return;
      setState(() {
        selectedImage = File(returnImage.path);
        _image = File(returnImage.path).readAsBytesSync();
      });
      Navigator.of(context).pop();
    } on PlatformException catch (e) {
      print('Failed to pick image');
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('profile_images/$fileName');
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');
      UploadTask uploadTask = storageReference.putFile(image, metadata);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => {});
      String downloadURL = await taskSnapshot.ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print('Failed to upload image: $e');
      return null;
    }
  }

  void _saveProfileData() async {
    setState(() {
      _isLoading = true;
    });

    String? imageUrl;
    if (selectedImage != null) {
      imageUrl = await _uploadImageToFirebase(selectedImage!);
    }

    String fullname = _fullnameController.text;
    String username = _usernameController.text;
    String bio = _bioController.text;

    setState(() {
      _fullnameError = fullname.isEmpty ? 'Tên hồ sơ không được để trống' : null;
      _usernameError = username.isEmpty ? 'Tên người dùng không được để trống' : null;
      _bioError = bio.isEmpty ? 'Tiểu sử không được để trống' : null;
    });

    if (_fullnameError == null && _usernameError == null && _bioError == null) {
      await FirebaseFirestore.instance.collection('users').doc(currentUser?.uid).update({
        'fullname': fullname,
        'username': username,
        'bio': bio,
        if (imageUrl != null) 'avatar': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Cập nhật hồ sơ thành công'),
      ));

      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
      });
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
                        : CircleAvatar(
                            radius: 50,
                            backgroundImage: NetworkImage( _getimage.isNotEmpty ? _getimage : "https://cdn.pixabay.com/photo/2015/10/05/22/37/blank-profile-picture-973460_960_720.png"),
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
                  controller: _usernameController, 
                  focusNode: _usernameFocusNode, 
                  errorText: _usernameError, 
                  label: 'username'
                ),
                SizedBox(height: 10,),
                InputForm(
                  controller: _bioController, 
                  focusNode: _bioFocusNode, 
                  errorText: _bioError, 
                  label: 'Tiểu sử'
                ),
                SizedBox(height: 10,),
                GestureDetector(
                  onTap: _saveProfileData,
                  child: Container(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      color: Color(0xFFFF7622),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: _isLoading
                          ? CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : Text(
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
                      onTap: _pickImageFromGallery,
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
                      onTap: _pickImageFromCamera,
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
