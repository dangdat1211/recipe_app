import 'dart:async';
import 'package:flutter/material.dart';
import 'package:recipe_app/screens/screens.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final StreamController<int> _streamController = StreamController<int>.broadcast();

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      _streamController.add(_pageController.page!.toInt());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              _buildOnboardingPage(
                'assets/food_intro.jpg',
                'Khám phá công thức mới',
                'Hàng ngàn công thức nấu ăn đang chờ bạn khám phá',
              ),
              _buildOnboardingPage(
                'assets/food_intro.jpg',
                'Nấu ăn cùng nhau',
                'Chia sẻ niềm đam mê nấu ăn với cộng đồng',
              ),
              _buildOnboardingPage(
                'assets/food_intro.jpg',
                'Ăn uống lành mạnh',
                'Tìm kiếm các công thức phù hợp với chế độ ăn của bạn',
              ),
            ],
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 50,
            child: Column(
              children: [
                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const ExpandingDotsEffect(
                    dotWidth: 10,
                    dotHeight: 10,
                    activeDotColor: Color(0xFFFF7622),
                  ),
                ),
                const SizedBox(height: 30),
                StreamBuilder<int>(
                  stream: _streamController.stream,
                  builder: (context, snapshot) {
                    return ElevatedButton(
                      onPressed: () {
                        if (_pageController.page != 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const NavigateScreen()),
                          );
                        }
                      },
                      child: Text(
                        snapshot.data != 2 ? 'Tiếp tục' : 'Bắt đầu nào',
                        style: const TextStyle(fontSize: 18),
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const NavigateScreen()),
                    );
                  },
                  child: const Text(
                    'Bỏ qua',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage(String image, String title, String description) {
    return Stack(
      children: [
        // Lớp hình nền
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(image),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6), // Tăng độ mờ
                BlendMode.darken,
              ),
            ),
          ),
        ),
        // Lớp nội dung
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset('assets/logo_noback.png', height: 300),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      offset: Offset(2.0, 2.0),
                      blurRadius: 3.0,
                      color: Colors.black,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    shadows: [
                      Shadow(
                        offset: Offset(1.0, 1.0),
                        blurRadius: 2.0,
                        color: Colors.black,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _streamController.close();
    super.dispose();
  }
}