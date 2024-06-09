import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  List<Map<String, String>> comments = List.generate(
    10,
    (index) => {
      'author': 'Phạm Duy Đạt $index',
      'date': '12 tháng 6, 2023',
      'content': 'Nội dung ở đây $index'
    },
  );

  TextEditingController _commentController = TextEditingController();

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
            child: ListView.builder(
              itemCount: comments.length,
              itemBuilder: (context, index) {
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
                              Text(comments[index]['author']!),
                              Text(comments[index]['date']!),
                              Text(comments[index]['content']!),
                            ],
                          ),
                        ),
                      ),
                      PopupMenuButton<int>(
                        icon: Icon(Icons.more_vert),
                        onSelected: (item) => _onSelected(context, item, index),
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
                          contentPadding:
                              EdgeInsets.fromLTRB(20, 10, 10, 10),
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

  void _onSelected(BuildContext context, int item, int index) {
    switch (item) {
      case 0:
        _confirmDeleteComment(context, index);
        break;
    }
  }

  void _confirmDeleteComment(BuildContext context, int index) {
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
              _deleteComment(index);
              Navigator.of(context).pop();
            },
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _deleteComment(int index) {
    setState(() {
      comments.removeAt(index);
    });
  }

  void _addComment() {
    final newComment = _commentController.text;
    if (newComment.isNotEmpty) {
      setState(() {
        comments.add({
          'author': 'Phạm Duy Đạt',
          'date': '12 tháng 6, 2023',
          'content': newComment,
        });
        _commentController.clear();
      });
    }
  }
}
