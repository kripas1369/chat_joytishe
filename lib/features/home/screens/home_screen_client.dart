import 'dart:convert';
import 'dart:math';
import 'package:chat_jyotishi/features/auth/screens/login_screen.dart';
import 'package:chat_jyotishi/features/home/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/home/screens/home_dashboard_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';

/// Decode JWT token to get user info
Map<String, dynamic>? decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    switch (payload.length % 4) {
      case 1:
        payload += '===';
        break;
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }

    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

class HomeScreenClient extends StatefulWidget {
  const HomeScreenClient({super.key});

  @override
  State<HomeScreenClient> createState() => _HomeScreenClientState();
}

class _HomeScreenClientState extends State<HomeScreenClient>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CoinService _coinService = CoinService();
  final SocketService _socketService = SocketService();
  final ScrollController _scrollController = ScrollController();

  // Animation Controllers
  late AnimationController _horoscopeRotationController;
  late AnimationController _gradientShiftController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _fadeInController;
  late AnimationController _bounceController;

  // Animations
  late Animation<double> _gradientShiftAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;

  final String userName = 'Praveen';
  final String userEmail = 'praveen@example.com';
  final int notificationCount = 3;
  bool _isConnecting = false;
  double _appBarOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _scrollController.addListener(_onScroll);
  }

  void _initAnimations() {
    // Horoscope wheel rotation (60s per rotation)
    _horoscopeRotationController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();

    // Gradient shift animation (5s infinite)
    _gradientShiftController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _gradientShiftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientShiftController, curve: Curves.linear),
    );

    // Float animation (3s infinite)
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulse animation (2s infinite)
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Fade in animation
    _fadeInController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeInController.forward();

    // Bounce animation (1s infinite)
    _bounceController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (offset / 100).clamp(0.0, 1.0);
    if (_appBarOpacity != newOpacity) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _horoscopeRotationController.dispose();
    _gradientShiftController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _fadeInController.dispose();
    _bounceController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 640;
    final isTablet = screenSize.width >= 640 && screenSize.width < 1024;
    final isDesktop = screenSize.width >= 1024;

    _setSystemUIOverlay();

    return BlocProvider(
      create: (context) =>
          ChatBloc(chatRepository: ChatRepository(ChatService()))
            ..add(FetchActiveUsersEvent()),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.primaryBlack,
        drawer: _buildDrawer(),
        body: Stack(
          children: [
            // Background
            Container(color: AppColors.primaryBlack),
            // Custom Scroll View with all sections
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Navigation Bar
                _buildNavigationBar(isMobile),
                // Hero Section
                _buildHeroSection(isMobile, isTablet, isDesktop),
                // Horoscope Feature Section
                _buildHoroscopeFeatureSection(isMobile),
                // How It Works Section
                _buildHowItWorksSection(isMobile, isTablet, isDesktop),
                // Services Section
                _buildServicesSection(isMobile, isTablet, isDesktop),
                // Why Choose Us Section
                _buildWhyChooseUsSection(isMobile),
                // CTA Section
                _buildCTASection(isMobile, isTablet, isDesktop),
                // Footer
                _buildFooter(isMobile),
              ],
            ),
            if (_isConnecting)
              Container(
                color: Colors.black54,
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.cosmicPurple,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );
  }

  // Navigation Bar
  Widget _buildNavigationBar(bool isMobile) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.black.withOpacity(_appBarOpacity * 0.9),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _appBarOpacity * 10,
            sigmaY: _appBarOpacity * 10,
          ),
          child: Container(
            color: Colors.black.withOpacity(_appBarOpacity * 0.7),
          ),
        ),
      ),
      leading: GlassIconButton(
        icon: Icons.menu_rounded,
        onTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      title: _buildAppLogo(),
      actions: [
        if (!isMobile) ...[
          _buildNavLink('Home', true),
          _buildNavLink('Astrologers', false),
          _buildNavLink('Pricing', false),
          _buildNavLink('About', false),
          const SizedBox(width: 16),
        ],
        NotificationButton(
          notificationCount: notificationCount,
          onTap: () => _navigateTo('/notification_screen'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildAppLogo() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.cosmicPrimaryGradient,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.cosmicPrimaryGradient.createShader(bounds),
          child: const Text(
            'Jyotish',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavLink(String text, bool isActive) {
    return InkWell(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isActive ? AppColors.purple400 : AppColors.textGray300,
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Hero Section
  Widget _buildHeroSection(bool isMobile, bool isTablet, bool isDesktop) {
    final headingSize = isMobile ? 48.0 : (isTablet ? 56.0 : 64.0);
    final subheadingSize = isMobile ? 20.0 : (isTablet ? 24.0 : 30.0);

    return SliverToBoxAdapter(
      child: Container(
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Background with stars
            StarFieldBackground(),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    AppColors.cosmicPurple.withOpacity(0.3),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Floating Horoscope Wheel
            Center(
              child: AnimatedBuilder(
                animation: _horoscopeRotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _horoscopeRotationController.value * 2 * pi,
                    child: Container(
                      width: 800,
                      height: 800,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      child: CustomPaint(painter: HoroscopeWheelPainter()),
                    ),
                  );
                },
              ),
            ),
            // Content
            Center(
              child: FadeTransition(
                opacity: _fadeInController,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tagline
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Text(
                              'ANCIENT WISDOM • MODERN TECHNOLOGY',
                              style: TextStyle(
                                color: AppColors.purple400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Main Heading
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: AnimatedBuilder(
                              animation: _gradientShiftAnimation,
                              builder: (context, child) {
                                return ShaderMask(
                                  shaderCallback: (bounds) {
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        AppColors.purple300,
                                        AppColors.pink300,
                                        AppColors.purple300,
                                      ],
                                      stops: [
                                        _gradientShiftAnimation.value,
                                        (_gradientShiftAnimation.value + 0.5) %
                                            1.0,
                                        (_gradientShiftAnimation.value + 1.0) %
                                            1.0,
                                      ],
                                    ).createShader(bounds);
                                  },
                                  child: RichText(
                                    textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Discover Your ',
                                          style: TextStyle(
                                            fontSize: headingSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        WidgetSpan(
                                          child: ShaderMask(
                                            shaderCallback: (bounds) {
                                              return LinearGradient(
                                                colors: [
                                                  AppColors.pink400,
                                                  AppColors.red400,
                                                  AppColors.purple400,
                                                ],
                                              ).createShader(bounds);
                                            },
                                            child: Text(
                                              'Cosmic Path',
                                              style: TextStyle(
                                                fontSize: headingSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Subheading
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Text(
                              'Connect with Verified Expert Astrologers',
                              style: TextStyle(
                                color: AppColors.textGray200,
                                fontSize: subheadingSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                              ),
                              child: Text(
                                'Personalized horoscopes, real-time consultations, and cosmic insights to guide your journey.',
                                style: TextStyle(
                                  color: AppColors.textGray400,
                                  fontSize: isMobile ? 18 : 20,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    // CTA Button
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: Opacity(
                            opacity: value,
                            child: _buildHeroCTAButton(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Scroll Indicator
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: AnimatedBuilder(
                animation: _bounceAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _bounceAnimation.value),
                    child: Column(
                      children: [
                        Text(
                          'Scroll to explore',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCTAButton() {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeDashboardScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          gradient: AppColors.cosmicHeroGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cosmicRed.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // Horoscope Feature Section
  Widget _buildHoroscopeFeatureSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 80,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              AppColors.cosmicPurple.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildSpinningHoroscopeWheel(),
                  const SizedBox(height: 40),
                  _buildHoroscopeFeatureContent(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _buildSpinningHoroscopeWheel()),
                  const SizedBox(width: 60),
                  Expanded(child: _buildHoroscopeFeatureContent()),
                ],
              ),
      ),
    );
  }

  Widget _buildSpinningHoroscopeWheel() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glowing background
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 512,
              height: 512,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.cosmicPurple.withOpacity(_pulseAnimation.value),
                    AppColors.cosmicPink.withOpacity(_pulseAnimation.value),
                    AppColors.cosmicRed.withOpacity(_pulseAnimation.value),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),
        // Spinning wheel
        AnimatedBuilder(
          animation: _horoscopeRotationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _horoscopeRotationController.value * 2 * pi,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPurple.withOpacity(0.5),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: CustomPaint(painter: HoroscopeWheelPainter()),
              ),
            );
          },
        ),
        // Floating stat cards
        _buildFloatingStatCard(
          '5000+',
          'Readings',
          AppColors.cosmicPurple,
          const Offset(-100, -50),
          0,
        ),
        _buildFloatingStatCard(
          '50+',
          'Astrologers',
          AppColors.cosmicPink,
          const Offset(100, 50),
          1,
        ),
        _buildFloatingStatCard(
          '98%',
          'Accuracy',
          AppColors.cosmicRed,
          const Offset(120, -30),
          2,
        ),
      ],
    );
  }

  Widget _buildFloatingStatCard(
    String number,
    String label,
    Color color,
    Offset position,
    int delay,
  ) {
    return Positioned(
      left: position.dx,
      top: position.dy,
      child: AnimatedBuilder(
        animation: _floatController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value * (delay + 1) * 0.5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.8), color.withOpacity(0.6)],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHoroscopeFeatureContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR COSMIC BLUEPRINT',
          style: TextStyle(
            color: AppColors.purple400,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: const Text(
            'Personalized Horoscopes',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Get detailed insights into your life path, relationships, career, and more through personalized horoscope readings.',
          style: TextStyle(
            color: AppColors.textGray300,
            fontSize: 20,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(3, (index) => _buildFeatureItem(index)),
      ],
    );
  }

  Widget _buildFeatureItem(int index) {
    final features = [
      {
        'icon': Icons.stars,
        'title': 'Daily Predictions',
        'desc': 'Get your daily horoscope',
      },
      {
        'icon': Icons.favorite,
        'title': 'Love Compatibility',
        'desc': 'Find your perfect match',
      },
      {
        'icon': Icons.work,
        'title': 'Career Guidance',
        'desc': 'Navigate your career path',
      },
    ];
    final feature = features[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cosmicPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature['icon'] as IconData,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: TextStyle(
                        color: AppColors.textGray400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // How It Works Section
  Widget _buildHowItWorksSection(bool isMobile, bool isTablet, bool isDesktop) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 80,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.grey.shade900, Colors.black],
          ),
        ),
        child: Column(
          children: [
            // Section Header
            Text(
              'SIMPLE PROCESS',
              style: TextStyle(
                color: AppColors.pink400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.purple300,
                  AppColors.pink300,
                  AppColors.red300,
                ],
              ).createShader(bounds),
              child: Text(
                'How It Works',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 48 : 56,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 60),
            // Steps
            isMobile
                ? Column(
                    children: List.generate(
                      3,
                      (index) => _buildStepCard(index),
                    ),
                  )
                : Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(child: _buildStepCard(index)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(int index) {
    final steps = [
      {
        'number': '1',
        'title': 'Sign Up',
        'desc': 'Create your account in seconds',
      },
      {
        'number': '2',
        'title': 'Connect',
        'desc': 'Choose your preferred astrologer',
      },
      {
        'number': '3',
        'title': 'Transform',
        'desc': 'Get insights and guidance',
      },
    ];
    final step = steps[index];
    final gradients = [
      LinearGradient(colors: [AppColors.cosmicPurple, AppColors.cosmicPink]),
      LinearGradient(colors: [AppColors.cosmicPink, AppColors.cosmicRed]),
      LinearGradient(colors: [AppColors.cosmicRed, AppColors.cosmicPurple]),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Number badge with glow
          Stack(
            alignment: Alignment.center,
            children: [
              // Glow effect
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          gradients[index].colors.first.withOpacity(
                            _pulseAnimation.value,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Badge
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: gradients[index],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    step['number'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            step['title'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            step['desc'] as String,
            style: TextStyle(
              color: AppColors.textGray400,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Services Section
  Widget _buildServicesSection(bool isMobile, bool isTablet, bool isDesktop) {
    final crossAxisCount = isMobile ? 1 : (isTablet ? 2 : 3);

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 80,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              AppColors.cosmicRed.withOpacity(0.3),
              AppColors.cosmicPurple.withOpacity(0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            // Section Header
            Text(
              'WHAT WE OFFER',
              style: TextStyle(
                color: AppColors.purple400,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.purple300,
                  AppColors.pink300,
                  AppColors.red300,
                ],
              ).createShader(bounds),
              child: Text(
                'Our Services',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isMobile ? 48 : 56,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 60),
            // Services Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => _buildServiceCard(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(int index) {
    final services = [
      {
        'icon': Icons.chat_bubble,
        'title': 'Real-Time Chat',
        'subtitle': 'Instant messaging',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
        ),
      },
      {
        'icon': Icons.calendar_today,
        'title': 'Daily Horoscope',
        'subtitle': 'Daily predictions',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPink, AppColors.cosmicRed],
        ),
      },
      {
        'icon': Icons.people,
        'title': 'Consultations',
        'subtitle': 'Expert guidance',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicRed, AppColors.cosmicPurple],
        ),
      },
      {
        'icon': Icons.stars,
        'title': 'Birth Chart',
        'subtitle': 'Detailed analysis',
        'gradient': LinearGradient(
          colors: [Colors.blue.shade600, AppColors.cosmicPurple],
        ),
      },
      {
        'icon': Icons.favorite,
        'title': 'Love Match',
        'subtitle': 'Compatibility check',
        'gradient': LinearGradient(
          colors: [Colors.indigo.shade600, AppColors.cosmicPink],
        ),
      },
      {
        'icon': Icons.work,
        'title': 'Career Guide',
        'subtitle': 'Career insights',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPurple, AppColors.cosmicRed],
        ),
      },
    ];
    final service = services[index];

    return MouseRegion(
      onEnter: (_) {},
      onExit: (_) {},
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (service['gradient'] as LinearGradient).colors.first
                .withOpacity(0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: service['gradient'] as LinearGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    service['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service['subtitle'] as String,
                    style: TextStyle(
                      color: AppColors.textGray400,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Why Choose Us Section
  Widget _buildWhyChooseUsSection(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 80,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              AppColors.cosmicRed.withOpacity(0.3),
              AppColors.cosmicPurple.withOpacity(0.3),
            ],
          ),
        ),
        child: isMobile
            ? Column(
                children: [
                  _buildWhyChooseUsContent(),
                  const SizedBox(height: 40),
                  _buildStatsCard(),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildWhyChooseUsContent()),
                  const SizedBox(width: 40),
                  Expanded(child: _buildStatsCard()),
                ],
              ),
      ),
    );
  }

  Widget _buildWhyChooseUsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHY CHOOSE US',
          style: TextStyle(
            color: AppColors.pink300,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your Trusted Cosmic Guide',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'We combine ancient wisdom with modern technology to provide you with accurate, personalized astrological insights.',
          style: TextStyle(
            color: AppColors.textGray200,
            fontSize: 20,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),
        ...List.generate(3, (index) => _buildWhyChooseUsFeature(index)),
      ],
    );
  }

  Widget _buildWhyChooseUsFeature(int index) {
    final features = [
      {'title': 'Verified Experts', 'desc': 'All astrologers are verified'},
      {'title': '24/7 Support', 'desc': 'Available round the clock'},
      {'title': 'Privacy Guaranteed', 'desc': 'Your data is secure'},
    ];
    final feature = features[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: TextStyle(
                        color: AppColors.textGray200,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              _buildStatItem(
                'Total Consultations',
                '10,000+',
                AppColors.pink300,
              ),
              const SizedBox(height: 24),
              _buildStatItem('Expert Astrologers', '50+', AppColors.purple300),
              const SizedBox(height: 24),
              _buildStatItem('Happy Clients', '8,500+', AppColors.red300),
              const SizedBox(height: 24),
              _buildStatItem(
                'Satisfaction Rate',
                '98%',
                Colors.yellow.shade300,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // CTA Section
  Widget _buildCTASection(bool isMobile, bool isTablet, bool isDesktop) {
    final headingSize = isMobile ? 48.0 : 64.0;

    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 100,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              AppColors.cosmicRed.withOpacity(0.2),
              AppColors.cosmicPurple.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [
                  AppColors.purple300,
                  AppColors.pink300,
                  AppColors.red300,
                ],
              ).createShader(bounds),
              child: Text(
                'Ready to Discover Your Destiny?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: headingSize,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Join thousands who have found clarity and guidance through our platform.',
              style: TextStyle(color: AppColors.textGray300, fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () => _navigateTo('/chat_list_screen'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 20,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicHeroGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicRed.withOpacity(0.6),
                      blurRadius: 40,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Start Your Journey Today',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Footer
  Widget _buildFooter(bool isMobile) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 20 : 40,
          vertical: 60,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.blue.shade900.withOpacity(0.2),
              AppColors.cosmicPurple.withOpacity(0.2),
              AppColors.cosmicRed.withOpacity(0.2),
            ],
          ),
        ),
        child: Column(
          children: [
            Divider(color: Colors.grey.shade800),
            const SizedBox(height: 40),
            isMobile
                ? Column(
                    children: [
                      _buildAppLogo(),
                      const SizedBox(height: 32),
                      _buildFooterLinks(isMobile),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [_buildAppLogo(), _buildFooterLinks(isMobile)],
                  ),
            const SizedBox(height: 40),
            Text(
              '© 2026 Chat Jyotish. All rights reserved.',
              style: TextStyle(color: AppColors.textGray400, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks(bool isMobile) {
    final links = ['Home', 'Astrologers', 'Pricing', 'About', 'Contact'];
    return Wrap(
      spacing: 24,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: links.map((link) {
        return InkWell(
          onTap: () {},
          child: Text(
            link,
            style: TextStyle(color: AppColors.textGray400, fontSize: 14),
          ),
        );
      }).toList(),
    );
  }

  // Drawer
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.primaryBlack,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryBlack,
              AppColors.cosmicPurple.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Divider(color: Colors.white.withOpacity(0.08)),
              Expanded(child: _buildDrawerItems()),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildDrawerLogout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.cosmicPrimaryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlack,
              ),
              child: const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.cardMedium,
                child: Icon(
                  Icons.person_rounded,
                  color: AppColors.textSecondary,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '$userName Shrestha',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userEmail,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    final items = [
      {
        'icon': Icons.home_rounded,
        'title': 'Home',
        'selected': true,
        'route': null,
      },
      {
        'icon': Icons.person_rounded,
        'title': 'Profile',
        'route': '/user_profile_screen',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'History',
        'route': '/history_screen_client',
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'route': '/settings_screen',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'route': '/help_support_screen',
      },
      {
        'icon': Icons.info_outline_rounded,
        'title': 'About Us',
        'route': '/about_us_screen',
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'title': 'Privacy Policy',
        'route': '/privacy_policy_screen',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) {
        return DrawerItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          isSelected: item['selected'] as bool? ?? false,
          onTap: () {
            if (item['route'] != null) {
              _navigateTo(item['route'] as String);
            } else {
              Navigator.pop(context);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDrawerLogout() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DrawerItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        isDestructive: true,
        onTap: _handleLogout,
      ),
    );
  }

  // Navigation and action handlers
  void _navigateTo(String route) {
    if (route == '/chat_list_screen') {
      _handleChatNavigation();
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _handleChatNavigation() async {
    final balance = await _coinService.getBalance();

    if (!mounted) return;

    if (balance > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatOptionsScreen()),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage()));
    }
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}

// Horoscope Wheel Painter
class HoroscopeWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw wheel segments
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * pi / 12) - pi / 2;
      paint.color = [
        AppColors.cosmicPurple,
        AppColors.cosmicPink,
        AppColors.cosmicRed,
      ][i % 3].withOpacity(0.3);

      canvas.drawLine(
        center,
        Offset(
          center.dx + radius * cos(angle),
          center.dy + radius * sin(angle),
        ),
        paint,
      );
    }

    // Draw outer circle
    paint
      ..color = Colors.white.withOpacity(0.2)
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, paint);

    // Draw inner circle
    paint
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
