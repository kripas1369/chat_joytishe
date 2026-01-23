import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Divine Guidance',
      description:
          'Connect with expert astrologers who illuminate your path through ancient Vedic wisdom',
      icon: '🪔',
      gradient: [Color(0xFFFF6B35), Color(0xFFFF9068), Color(0xFFFFB49A)],
      accentColor: Color(0xFFFFD4C4),
    ),
    OnboardingPage(
      title: 'Cosmic Insights',
      description:
          'Discover your destiny through personalized horoscopes and birth chart analysis',
      icon: '⭐',
      gradient: [Color(0xFF6A1B9A), Color(0xFF9C4DCC), Color(0xFFCE93D8)],
      accentColor: Color(0xFFE1BEE7),
    ),
    OnboardingPage(
      title: '24/7 Support',
      description:
          'Get instant answers to life\'s questions anytime, anywhere through chat or call',
      icon: '💬',
      gradient: [Color(0xFF0288D1), Color(0xFF29B6F6), Color(0xFF81D4FA)],
      accentColor: Color(0xFFB3E5FC),
    ),
    OnboardingPage(
      title: 'Sacred Rituals',
      description:
          'Access ancient puja services and spiritual remedies for prosperity and peace',
      icon: '🕉️',
      gradient: [Color(0xFFD32F2F), Color(0xFFEF5350), Color(0xFFE57373)],
      accentColor: Color(0xFFFFCDD2),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _navigateToHome() {
    Navigator.pushReplacementNamed(context, '/login_screen');
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // Animated Background
          AnimatedContainer(
            duration: Duration(milliseconds: 600),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _pages[_currentPage].gradient,
              ),
            ),
          ),

          // Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 600),
              opacity: 0.1,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -150,
            left: -150,
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 600),
              opacity: 0.08,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jyotish',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      if (_currentPage < _pages.length - 1)
                        TextButton(
                          onPressed: _navigateToHome,
                          child: Text(
                            'SKIP',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Page Indicator
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index),
                    ),
                  ),
                ),

                // Next/Get Started Button
                Padding(
                  padding: EdgeInsets.fromLTRB(40, 0, 40, 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < _pages.length - 1) {
                          _pageController.nextPage(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          _navigateToHome();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _pages[_currentPage].gradient[0],
                        elevation: 8,
                        shadowColor: Colors.black.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage < _pages.length - 1
                                ? 'NEXT'
                                : 'GET STARTED',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            _currentPage < _pages.length - 1
                                ? Icons.arrow_forward_rounded
                                : Icons.auto_awesome,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: _currentPage == index ? 1.0 : 0.0,
                    ),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) {
                      final safeValue = value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.6 + (safeValue * 0.4),
                        child: Opacity(opacity: safeValue, child: child),
                      );
                    },
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(page.icon, style: TextStyle(fontSize: 90)),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Title
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: _currentPage == index ? 1.0 : 0.0,
                    ),
                    duration: Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      final safeValue = value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - safeValue)),
                        child: Opacity(opacity: safeValue, child: child),
                      );
                    },
                    child: Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ),

                  SizedBox(height: 16),

                  // Description
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0.0,
                      end: _currentPage == index ? 1.0 : 0.0,
                    ),
                    duration: Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      final safeValue = value.clamp(0.0, 1.0);
                      return Transform.translate(
                        offset: Offset(0, 16 * (1 - safeValue)),
                        child: Opacity(opacity: safeValue, child: child),
                      );
                    },
                    child: Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.95),
                        height: 1.6,
                      ),
                    ),
                  ),

                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIndicator(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String icon;
  final List<Color> gradient;
  final Color accentColor;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });
}
