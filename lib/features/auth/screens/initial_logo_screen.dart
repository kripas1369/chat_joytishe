import 'dart:math';

import 'package:chat_jyotishi/features/auth/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'login_screen.dart';

class InitialLogoScreen extends StatefulWidget {
  const InitialLogoScreen({super.key});

  @override
  State<InitialLogoScreen> createState() => _InitialLogoScreenState();
}

class _InitialLogoScreenState extends State<InitialLogoScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onGetStarted,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(decoration: BoxDecoration(color: Colors.black)),
            Center(
              child: ScaleTransition(
                scale: _pulseAnimation,
                child: Image.asset(
                  'assets/logo/logo.png',
                  width: screenWidth,
                  fit: BoxFit.contain,
                ),
              ),
            ),

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
                          width: screenWidth * 0.65,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Twinkling stars
            const TwinklingStars(starCount: 3),
          ],
        ),
      ),
    );
  }

  void _onGetStarted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const SplashScreen()),
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
