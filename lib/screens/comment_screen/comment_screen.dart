import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CommentScreen extends StatefulWidget {
  final String recipeId;

  const CommentScreen({Key? key, required this.recipeId}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<Map<String, dynamic>> comments = [];

  TextEditingController _commentController = TextEditingController();

  User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('comments')
          .where('recipeID', isEqualTo: widget.recipeId)
          .get();

      setState(() {
        comments = snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      print('Error loading comments: $e');
      // Handle error loading comments from Firebase
    }
  }

  void _addComment() async {
    final newComment = _commentController.text.trim();
    if (newComment.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('comments').add({
          'recipeID': widget.recipeId, // Replace with actual title
          'userId': currentUser?.uid, // Replace with actual user ID
          'createdAt': DateTime.now().toString(),
          'content': newComment,
        });

        setState(() {
          comments.add({
            'author': currentUser?.email, // Replace with actual author
            'date': '12 tháng 6, 2023', // Replace with actual date format
            'content': newComment,
          });
          _commentController.clear();
        });
      } catch (e) {
        print('Error adding comment: $e');
        // Handle error adding comment to Firebase
      }
    }
  }

  void _deleteComment(String commentId, int index) async {
    try {
      await FirebaseFirestore.instance.collection('comments').doc(commentId).delete();

      setState(() {
        comments.removeAt(index);
      });
    } catch (e) {
      print('Error deleting comment: $e');
      // Handle error deleting comment from Firebase
    }
  }

  void _confirmDeleteComment(BuildContext context, String commentId, int index) {
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
          Padding(
            padding: const EdgeInsets.only(bottom: 80.0),
            child: comments.isEmpty
                ? Center(
                    child: Text('Không có bình luận nào.'),
                  )
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final comment = comments[index];
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(),
                            SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment['author'] ?? 'Unknown'),
                                    Text(comment['date'] ?? ''),
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
                                PopupMenuItem<int>(value: 0, child: Text('Xóa')),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(radius: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      child: TextField(
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
        ],
      ),
    );
  }

  void _onSelected(
      BuildContext context, int item, Map<String, dynamic> comment, int index) {
    switch (item) {
      case 0:
        _confirmDeleteComment(context, comment['id'], index);
        break;
    }
  }
}
