import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DetailReCipe extends StatefulWidget {
  const DetailReCipe({super.key});

  @override
  State<DetailReCipe> createState() => _DetailReCipeState();
}

class _DetailReCipeState extends State<DetailReCipe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.favorite)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
    );
  }
}