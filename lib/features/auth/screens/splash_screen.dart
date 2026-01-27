import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../onboarding/screens/onboarding_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Key for tracking if onboarding has been shown
  static const String _onboardingCompleteKey = 'onboarding_complete';
  
  // Set to true to always show onboarding (for testing)
  // Change to false after testing to restore normal behavior
  static const bool _forceShowOnboarding = true;

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

    // Auto-navigate after 3 seconds
    _startAutoNavigation();
  }

  /// Start auto-navigation timer
  void _startAutoNavigation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _navigateToNextScreen();
      }
    });
  }

  /// Check if onboarding is complete and navigate accordingly
  Future<void> _navigateToNextScreen() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool(_onboardingCompleteKey) ?? false;

    if (!mounted) return;

    // Force show onboarding if flag is set (for testing)
    if (_forceShowOnboarding || !onboardingComplete) {
      // Navigate to onboarding screen
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const OnboardingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // User has seen onboarding, go directly to login
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  /// Reset onboarding status (for testing/debugging)
  /// Call this method to reset onboarding and show it again
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingCompleteKey);
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
        onTap: _navigateToNextScreen,
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
