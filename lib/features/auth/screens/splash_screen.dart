import 'dart:math';
import 'package:chat_jyotishi/features/auth/widgets/app_button_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/constant.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: BoxDecoration(color: Colors.black)),

          // Opacity(
          //   opacity: 0.4,
          //   child: ClipOval(
          //     child: Image.asset(
          //       'assets/logo/logo.png',
          //       width: screenWidth,
          //       height: screenWidth,
          //       fit: BoxFit.contain,
          //     ),
          //   ),
          // ),
          Center(
            child: AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: Opacity(
                    opacity: 0.15,
                    child: ClipOval(
                      child: Image.asset(
                        'assets/image/splash_image1.webp',
                        width: screenWidth,
                        height: screenWidth,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Twinkling stars
          const TwinklingStars(starCount: 3),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 50, left: 16, right: 16),
                child: Image.asset(
                  'assets/logo/name_logo.png',
                  fit: BoxFit.contain,
                  width: screenWidth * 0.6,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: 66),
              child: SizedBox(
                width: 240,
                child: AppButton(
                  title: 'Get Started',
                  suffixIcon: Icon(Icons.arrow_forward, color: Colors.white70),
                  onTap: _onGetStarted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

class TwinklingStars extends StatefulWidget {
  final int starCount;

  const TwinklingStars({super.key, this.starCount = 3});

  @override
  State<TwinklingStars> createState() => _TwinklingStarsState();
}

class _TwinklingStarsState extends State<TwinklingStars>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Star> _stars;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();

    _stars = List.generate(
      widget.starCount,
      (index) => Star(random: Random(index)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: StarsPainter(stars: _stars, animation: _controller.value),
          child: Container(),
        );
      },
    );
  }
}

class Star {
  late double y;
  late double size;
  late double twinkleSpeed;
  late double delay;

  Star({required Random random}) {
    y = random.nextDouble() * 0.6 + 0.2;
    size = random.nextDouble() * 2 + 1.5;
    twinkleSpeed = random.nextDouble() * 2 + 1;
    delay = random.nextDouble();
  }
}

class StarsPainter extends CustomPainter {
  final List<Star> stars;
  final double animation;

  StarsPainter({required this.stars, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (var star in stars) {
      double adjustedAnimation = (animation + star.delay) % 1.0;
      double x = adjustedAnimation * size.width;

      final opacity = (sin(animation * star.twinkleSpeed * 2 * pi) + 1) / 2;
      paint.color = Colors.white.withOpacity(opacity * 0.9);

      canvas.drawCircle(Offset(x, star.y * size.height), star.size, paint);

      paint.color = Colors.white.withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, star.y * size.height), star.size * 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) {
    return animation != oldDelegate.animation;
  }
}
