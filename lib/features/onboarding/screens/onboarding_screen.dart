import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';
import '../../auth/screens/login_screen.dart';

/// Data model for onboarding page content
class OnboardingData {
  final String imageUrl;
  final String title;
  final String description;
  final IconData? icon;
  final bool isNetworkImage;

  const OnboardingData({
    required this.imageUrl,
    required this.title,
    required this.description,
    this.icon,
    this.isNetworkImage = true,
  });
}

/// Main Onboarding Screen with horizontal swipeable pages
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // Page controller for managing page transitions
  late PageController _pageController;

  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Current page index
  int _currentPage = 0;

  // Onboarding content - customize these for your app
  // Using network images for astrology/jyotishi theme
  final List<OnboardingData> _pages = [
    OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1532968961962-8a0cb3a2d4f5?w=400&h=400&fit=crop',
      title: 'Welcome to ChatJyotishi',
      description:
          'Connect with experienced astrologers and discover the wisdom of the stars. Your cosmic journey begins here.',
      icon: Icons.auto_awesome,
    ),
    OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1614732414444-096e5f1122d5?w=400&h=400&fit=crop',
      title: 'Expert Consultations',
      description:
          'Get personalized readings from certified astrologers. Chat, call, or video consult at your convenience.',
      icon: Icons.chat_bubble_outline,
    ),
    OnboardingData(
      imageUrl:
          'https://images.unsplash.com/photo-1419242902214-272b3f66ee7a?w=400&h=400&fit=crop',
      title: 'Your Cosmic Guide',
      description:
          'Receive daily horoscopes, kundali readings, and life guidance aligned with celestial movements.',
      icon: Icons.stars_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Pulse animation for decorative elements
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  /// Navigate to the auth/login screen
  Future<void> _navigateToAuth() async {
    // Mark onboarding as complete
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (!mounted) return;

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

  /// Skip to the last page
  void _onSkip() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  /// Handle next button press
  void _onNext() {
    if (_currentPage == _pages.length - 1) {
      _navigateToAuth();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Star field background (matching homepage)
          const StarFieldBackground(),

          // Cosmic gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  AppColors.cosmicPurple.withOpacity(0.3),
                  AppColors.cosmicPink.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Top bar with indicators and skip button
                _buildTopBar(),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], index);
                    },
                  ),
                ),

                // Bottom navigation button
                _buildBottomButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build top bar with page indicators and skip button
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page indicators
          Row(
            children: List.generate(
              _pages.length,
              (index) => _buildIndicator(index),
            ),
          ),

          // Skip button (hidden on last page)
          AnimatedOpacity(
            opacity: _currentPage == _pages.length - 1 ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _currentPage == _pages.length - 1 ? null : _onSkip,
              child: Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textGray300,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual page indicator dot
  Widget _buildIndicator(int index) {
    final isActive = index == _currentPage;
    final gradients = [
      LinearGradient(colors: [AppColors.cosmicPurple, AppColors.cosmicPink]),
      LinearGradient(colors: [AppColors.cosmicPink, AppColors.cosmicRed]),
      LinearGradient(colors: [AppColors.cosmicRed, AppColors.cosmicPurple]),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: isActive ? gradients[index % gradients.length] : null,
        color: isActive ? null : AppColors.textMuted.withOpacity(0.4),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: gradients[index % gradients.length].colors.first
                      .withOpacity(0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }

  /// Build individual onboarding page
  Widget _buildPage(OnboardingData data, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated image container (Circular)
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _getPageGradient(index).colors.first.withOpacity(0.3),
                    _getPageGradient(index).colors.last.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: _getPageGradient(index).colors.first.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getPageGradient(
                      index,
                    ).colors.first.withOpacity(0.4),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: ClipOval(
                child: data.isNetworkImage
                    ? Image.network(
                        data.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.black.withOpacity(0.3),
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: _getPageGradient(index).colors.first,
                                strokeWidth: 3,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return _buildFallbackImage(data.icon, index);
                        },
                      )
                    : Image.asset(
                        data.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildFallbackImage(data.icon, index);
                        },
                      ),
              ),
            ),
          ),

          const SizedBox(height: 48),

          // Icon indicator
          if (data.icon != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: _getPageGradient(index),
                boxShadow: [
                  BoxShadow(
                    color: _getPageGradient(
                      index,
                    ).colors.first.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(data.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 24),
          ],

          // Title with cosmic gradient
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.purple300,
                AppColors.pink300,
                AppColors.red300,
              ],
            ).createShader(bounds),
            child: Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textGray200,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  /// Get gradient for specific page index
  LinearGradient _getPageGradient(int index) {
    final gradients = [
      LinearGradient(colors: [AppColors.cosmicPurple, AppColors.cosmicPink]),
      LinearGradient(colors: [AppColors.cosmicPink, AppColors.cosmicRed]),
      LinearGradient(colors: [AppColors.cosmicRed, AppColors.cosmicPurple]),
    ];
    return gradients[index % gradients.length];
  }

  /// Build fallback image when network image fails to load
  Widget _buildFallbackImage(IconData? icon, int index) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _getPageGradient(index),
      ),
      child: Center(
        child: Icon(icon ?? Icons.auto_awesome, size: 100, color: Colors.white),
      ),
    );
  }

  /// Build bottom navigation button
  Widget _buildBottomButton() {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.cosmicHeroGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.cosmicRed.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isLastPage ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLastPage ? Icons.rocket_launch : Icons.arrow_forward,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
