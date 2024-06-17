import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:recipe_app/screens/sign_in_screen/sign_in_screen.dart';

class CommentScreen extends StatefulWidget {
  final String recipeId;
  final String userId;
  final bool autoFocus;

  const CommentScreen(
      {Key? key,
      required this.recipeId,
      required this.userId,
      this.autoFocus = false})
      : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();
  User? currentUser = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? currentUserData;
  bool isLoadingComments = true;
  bool isLoadingUser = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadComments();
    _loadCurrentUser();

    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_focusNode);
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      if (currentUser != null) {
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser!.uid)
            .get();
        setState(() {
          currentUserData = userSnapshot.data() as Map<String, dynamic>?;
          isLoadingUser = false; // Set to false when loading is complete
        });
      } else {
        setState(() {
          isLoadingUser = false; // Set to false if no current user
        });
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        isLoadingUser = false; // Set to false in case of error
      });
    }
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('recipeID', isEqualTo: widget.recipeId)
          .orderBy('createdAt', descending: false)
          .get();

      List<Map<String, dynamic>> loadedComments = [];
      for (var doc in snapshot.docs) {
        var commentData = doc.data();
        var userId = commentData['userId'];
        var userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        var userData = userSnapshot.data();
        if (userData != null) {
          loadedComments.add({
            'author': userData['fullname'],
            'avatarUrl': userData['avatar'],
            'date': commentData['createdAt'],
            'content': commentData['content'],
            'id': doc.id,
            'userId': commentData['userId']
          });
        }
      }

      setState(() {
        comments = loadedComments;
        isLoadingComments = false; // Set to false when loading is complete
      });
    } catch (e) {
      print('Error loading comments: $e');
      setState(() {
        isLoadingComments = false; // Set to false in case of error
      });
    }
  }

  void _addComment() async {
    if (currentUser != null) {
      final newComment = _commentController.text.trim();
      if (newComment.isNotEmpty) {
        try {
          await FirebaseFirestore.instance.collection('comments').add({
            'recipeID': widget.recipeId,
            'userId': currentUser?.uid,
            'createdAt': DateTime.now().toString(),
            'content': newComment,
          });

          _loadComments();
          _commentController.clear();
        } catch (e) {
          print('Error adding comment: $e');
        }
      }
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Bạn chưa đăng nhập'),
            content: Text('Vui lòng đăng nhập để tiếp tục.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()),
                  );
                },
                child: Text('Đăng nhập'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Hủy'),
              ),
            ],
          );
        },
      );
    }
  }

  void _deleteComment(String commentId, int index) async {
    try {
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();

      setState(() {
        comments.removeAt(index);
      });
    } catch (e) {
      print('Error deleting comment: $e');
    }
  }

  void _confirmDeleteComment(
      BuildContext context, String commentId, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa bình luận'),
        content: Text('Bạn có chắc chắn muốn xóa bình luận này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              _deleteComment(commentId, index);
              Navigator.of(context).pop();
            },
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Cơm rượu nếp than'),
      ),
      body: Stack(
        children: [
          if (isLoadingComments)
            Center(child: CircularProgressIndicator())
          else
            Padding(
              padding: EdgeInsets.only(bottom: 80.0),
              child: comments.isEmpty
                  ? Center(
                      child: Text('Không có bình luận nào.'),
                    )
                  : ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final DateTime createdAt =
                            DateTime.parse(comment['date']);
                        final String formattedDate =
                            DateFormat('dd/MM/yyyy HH:mm').format(createdAt);

                        return Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                backgroundImage:
                                    NetworkImage(comment['avatarUrl'] ?? ''),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(comment['author'] ?? 'Unknown'),
                                      Text(formattedDate),
                                      Text(comment['content'] ?? ''),
                                    ],
                                  ),
                                ),
                              ),
                              PopupMenuButton<int>(
                                icon: Icon(Icons.more_vert),
                                onSelected: (item) =>
                                    _onSelected(context, item, comment, index),
                                itemBuilder: (context) => [
                                  PopupMenuItem<int>(
                                      value: 0, child: Text('Xóa')),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          if (currentUser != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    isLoadingUser
                        ? CircularProgressIndicator()
                        : CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                NetworkImage(currentUserData?['avatar'] ?? ''),
                          ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 40,
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'Bình luận ngay',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide(),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.fromLTRB(20, 10, 10, 10),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _addComment,
                    ),
                  ],
                ),
              ),
            ),
          if (currentUser == null) 
            Align(
              alignment: Alignment.bottomCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen()));
                },
                child: Container(
                  height: 100,
                  child: Center(child: Text('Đăng nhập ngay để bình luận . Tại đây'))),
              ),
            )
        ],
      ),
    );
  }

  void _onSelected(
      BuildContext context, int item, Map<String, dynamic> comment, int index) {
    switch (item) {
      case 0:
        if (currentUser?.uid == comment['userId'] ||
            currentUser?.uid == widget.userId) {
          _confirmDeleteComment(context, comment['id'], index);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Không đủ thẩm quyền'),
              content: Text(
                  'Bạn chỉ có thể xóa bình luận của bạn hoặc bình luận từ công thức của bạn'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
        break;
    }
  }
}
