import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DetailReCipe extends StatefulWidget {
  const DetailReCipe({super.key});

  @override
  State<DetailReCipe> createState() => _DetailReCipeState();
}

class _DetailReCipeState extends State<DetailReCipe> {
  final String url = "https://www.youtube.com/watch?v=YMx8Bbev6T4";

  late YoutubePlayerController _controllerYoutube;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayer.convertUrlToId(url);
    _controllerYoutube = YoutubePlayerController(
        initialVideoId: videoId!, flags: YoutubePlayerFlags(autoPlay: false));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: () {}, icon: Icon(Icons.favorite)),
          IconButton(onPressed: () {}, icon: Icon(Icons.more_vert)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    child: CircleAvatar(),
                  ),
                  Column(
                    children: [Text('Phạm Duy Đạt'), Text('@user_name')],
                  )
                ],
              ),
              Center(
                child: Container(
                  height: 200,
                  width: 355, // Đặt chiều cao mong muốn cho video
                  child: YoutubePlayer(
                    controller: _controllerYoutube,
                    showVideoProgressIndicator: true,
                    onReady: () {},
                  ),
                ),
              ),
              Text('Tên món ăn : Hahasd asdiasjd sạdha'),
              Text('Mô tả món ăn : Hahasd asdiasjd sạdha'),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text('Nguyên liệu'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text('1'),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8), // Thêm padding để Text không dính sát vào viền
                    alignment:
                        Alignment.centerLeft, // Căn Text bắt đầu từ bên trái
                    child: Text(
                      '1 tỷ tiền mặt',
                      textAlign: TextAlign.left, // Đảm bảo text căn từ bên trái
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text('1'),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8), // Thêm padding để Text không dính sát vào viền
                    alignment:
                        Alignment.centerLeft, // Căn Text bắt đầu từ bên trái
                    child: Text(
                      '1 tỷ tiền mặt',
                      textAlign: TextAlign.left, // Đảm bảo text căn từ bên trái
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    child: Center(
                      child: Text('1'),
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8), // Thêm padding để Text không dính sát vào viền
                    alignment:
                        Alignment.centerLeft, // Căn Text bắt đầu từ bên trái
                    child: Text(
                      '1 tỷ tiền mặt',
                      textAlign: TextAlign.left, // Đảm bảo text căn từ bên trái
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 10,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Text('Cách làm'),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Divider(
                      color: Colors.black,
                      thickness: 1,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 166, 115),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('1'),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 200,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8), // Thêm padding để Text không dính sát vào viền
                    alignment:
                        Alignment.centerLeft, // Căn Text bắt đầu từ bên trái
                    child: Text(
                      '1 tỷ tiền mặt',
                      textAlign: TextAlign.left, // Đảm bảo text căn từ bên trái
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 1
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa các hình ảnh
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 2
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa các hình ảnh
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 3
                  ),
                ],
              ),
              SizedBox(
                height: 5,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.1,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 255, 166, 115),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text('1'),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: 200,
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 255, 166, 115),
                        borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.symmetric(
                        horizontal:
                            8), // Thêm padding để Text không dính sát vào viền
                    alignment:
                        Alignment.centerLeft, // Căn Text bắt đầu từ bên trái
                    child: Text(
                      '1 tỷ tiền mặt',
                      textAlign: TextAlign.left, // Đảm bảo text căn từ bên trái
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5,),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.blue, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 1
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa các hình ảnh
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 2
                  ),
                  SizedBox(width: 8), // Khoảng cách giữa các hình ảnh
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.green, // Thay đổi màu sắc tùy theo yêu cầu
                      borderRadius: BorderRadius.circular(16),
                    ),
                    // Widget hình ảnh 3
                  ),
                ],
              ),
              SizedBox(height: 10,),
              Center(
                child: Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width * 0.9,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(),
                      Text('Được đăng tải bởi'),
                      Text('Phạm Duy Đạt'),
                      Text('ngày 12 tháng 11 năm 2002'),
                      Container(
                        height: 40,
                        width: 100,
                        color: Colors.amber,
                      )
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
