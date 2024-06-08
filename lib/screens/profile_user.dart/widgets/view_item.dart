import 'package:flutter/material.dart';

class ViewItem extends StatefulWidget {
  const ViewItem(
      {super.key,
      required this.image,
      required this.rate,
      required this.like,
      required this.date,
      required this.title,
      required this.onTap});

  final String image;
  final String rate;
  final String like;
  final String date;
  final String title;
  final Function onTap;

  @override
  State<ViewItem> createState() => _ViewItemState();
}

class _ViewItemState extends State<ViewItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap(),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(
              ),
              image: DecorationImage(
                  image: NetworkImage(widget.image), fit: BoxFit.cover),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Positioned(
            top: 3,
            left: 3,
            child: Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.white,
                ),
                Text(
                  widget.rate,
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: Colors.white,
                ),
                Text(
                  widget.like,
                  style: TextStyle(color: Colors.white),
                )
              ],
            ),
          ),
          Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 172, 128),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.date,
                        // style: TextStyle(color: Colors.white),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.46,
                        child: Text(
                          widget.title,
                          // style: TextStyle(color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),
              ))
        ],
      ),
    );
  }
}
