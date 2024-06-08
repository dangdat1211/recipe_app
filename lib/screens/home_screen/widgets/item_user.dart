import 'package:flutter/material.dart';

class ItemUser extends StatefulWidget {
  const ItemUser({super.key, required this.avatar, required this.fullname, required this.username, required this.recipe, required this.follow});

  final String avatar;
  final String fullname;
  final String username;
  final String recipe;
  final bool follow;

  @override
  State<ItemUser> createState() => _ItemUserState();
}

class _ItemUserState extends State<ItemUser> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(),
            Text((widget.fullname)),
            Text('@' + widget.username),
            Text(widget.recipe + ' công thức'),
            GestureDetector(
              child: Container(
                  height: 30,
                  width: 100,
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 206, 175),
                      borderRadius: BorderRadius.circular(10)),
                  child: Center(
                    child: widget.follow ? Text(
                      'Theo dõi ngay',
                      style: TextStyle(
                        color: Color(0xFFFF7622),
                      ),
                    )
                    :
                    Text(
                      'Đã theo dõi',
                      style: TextStyle(
                        color: Color(0xFFFF7622),
                      ),
                    )
                  )),
            )
          ],
        ),
      ),
    );
  }
}
