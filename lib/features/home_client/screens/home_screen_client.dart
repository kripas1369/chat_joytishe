import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_background_gradient.dart';
import 'package:chat_jyotishi/features/app_widgets/app_night_mode_overlay.dart';
import 'package:chat_jyotishi/features/auth/screens/login_screen.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_options_screen.dart';
import 'package:chat_jyotishi/features/home_client/bloc/home_client_bloc.dart';
import 'package:chat_jyotishi/features/home_client/bloc/home_client_events.dart';
import 'package:chat_jyotishi/features/home_client/repository/home_client_repository.dart';
import 'package:chat_jyotishi/features/home_client/service/home_client_service.dart';
import 'package:chat_jyotishi/features/home_client/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/home_client/widgets/feature_card.dart';
import 'package:chat_jyotishi/features/home_client/widgets/gradient_button.dart';
import 'package:chat_jyotishi/features/home_client/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/home_client/widgets/quick_action_chip.dart';
import 'package:chat_jyotishi/features/home_client/widgets/rotating_question_widget.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeScreenClient extends StatelessWidget {
  const HomeScreenClient({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          HomeClientBloc(repository: HomeClientRepository(HomeClientService()))
            ..add(LoadRotatingQuestionsEvent()),
      child: const HomeScreenClientContent(),
    );
  }
}

class HomeScreenClientContent extends StatefulWidget {
  const HomeScreenClientContent({super.key});

  @override
  State<HomeScreenClientContent> createState() =>
      _HomeScreenClientContentState();
}

class _HomeScreenClientContentState extends State<HomeScreenClientContent>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final CoinService _coinService = CoinService();
  final ScrollController _scrollController = ScrollController();
  bool _welcomeVisible = true;

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final String userName = 'Praveen';
  final String userEmail = 'praveen@example.com';
  final int profileCompletion = 65;
  final int notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
  }

  double _welcomeOpacity = 1.0;
  double _welcomeTranslateX = 0.0;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _welcomeTranslateX += details.delta.dx;
      _welcomeOpacity = (200 - _welcomeTranslateX.abs()).clamp(0, 200) / 200;
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_welcomeOpacity < 0.3) {
      // Remove the welcome section
      setState(() {
        _welcomeVisible = false;
      });

      // Scroll the remaining content to top
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    } else {
      // Snap back if swipe was not enough
      setState(() {
        _welcomeOpacity = 1.0;
        _welcomeTranslateX = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          buildGradientBackground(),
          _buildPulsingEffect(),
          // buildNightModeOverlay(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 16),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: _welcomeVisible
                                ? GestureDetector(
                                    onHorizontalDragUpdate:
                                        _onHorizontalDragUpdate,
                                    onHorizontalDragEnd: _onHorizontalDragEnd,
                                    child: _buildWelcomeSection(
                                      opacity: _welcomeOpacity,
                                      translateX: _welcomeTranslateX,
                                    ),
                                  )
                                : const SizedBox.shrink(), // collapses to 0 height when removed
                          ),

                          const SizedBox(height: 24),
                          const RotatingQuestionsWidget(),
                          const SizedBox(height: 32),
                          _buildQuickActions(),
                          const SizedBox(height: 32),
                          _buildFeatureGrid(),
                          const SizedBox(height: 32),
                          _buildProfileCard(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.backgroundDark,
      ),
    );
  }

  Widget _buildPulsingEffect() {
    return Positioned(
      top: -100,
      left: -50,
      right: -50,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            height: 350,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(
                    0.15 * _pulseAnimation.value,
                  ),
                  Colors.transparent,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 16),
            _buildAppLogo(),
          ],
        ),
        NotificationButton(
          notificationCount: notificationCount,
          onTap: () => _navigateTo('/notification_screen'),
        ),
      ],
    );
  }

  Widget _buildAppLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, AppColors.lightPurple],
          ).createShader(bounds),
          child: RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'Chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'Jyotishi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.primaryPurple.withOpacity(_pulseAnimation.value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection({double opacity = 1.0, double translateX = 0.0}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(translateX, 0),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primaryPurple.withOpacity(0.2),
                AppColors.deepPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingBadge(),
              const SizedBox(height: 16),
              Text(
                'Namaste, $userName',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The stars align in your favor today.\nDiscover what the cosmos has in store for you.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: 'View Today\'s Horoscope',
                icon: Icons.auto_awesome,
                onTap: () => _navigateTo('/horoscope_screen'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingBadge() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.lightPurple),
          const SizedBox(width: 6),
          Text(
            greeting,
            style: const TextStyle(
              color: AppColors.lightPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.favorite_rounded, 'label': 'Love'},
      {'icon': Icons.work_rounded, 'label': 'Career'},
      {'icon': Icons.attach_money_rounded, 'label': 'Finance'},
      {'icon': Icons.health_and_safety_rounded, 'label': 'Health'},
      {'icon': Icons.school_rounded, 'label': 'Education'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions', 'Services we provide'),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: actions.map((action) {
              return QuickActionChip(
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                onTap: () => _handleQuickAction(action['label'] as String),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid() {
    final features = [
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'Chat',
        'subtitle': 'Talk to astrologers',
        'gradient': AppColors.featureCardGradient1,
        'route': '/chat_list_screen',
        'delay': 0,
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'Horoscope',
        'subtitle': 'Daily predictions',
        'gradient': AppColors.featureCardGradient2,
        'route': '/horoscope_screen',
        'delay': 100,
      },
      {
        'icon': Icons.videocam_rounded,
        'title': 'Live Session',
        'subtitle': '1:1 consultation',
        'gradient': AppColors.featureCardGradient2,
        'route': '/live_session',
        'delay': 200,
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Appointment',
        'subtitle': 'Book a session',
        'gradient': AppColors.featureCardGradient1,
        'route': '/appointment_screen',
        'delay': 300,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Explore', 'Discover cosmic insights'),
        const SizedBox(height: 20),
        GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return FeatureCard(
              icon: feature['icon'] as IconData,
              title: feature['title'] as String,
              subtitle: feature['subtitle'] as String,
              gradient: feature['gradient'] as LinearGradient,
              onTap: () => _navigateTo(feature['route'] as String),
              delay: feature['delay'] as int,
            );
          },
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => _navigateTo('/user_profile_screen'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildProfileAvatar(),
            const SizedBox(width: 16),
            Expanded(child: _buildProfileInfo()),
            const SizedBox(width: 12),
            _buildArrowButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.cardDark,
        ),
        child: const CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.cardMedium,
          child: Icon(
            Icons.person_rounded,
            color: AppColors.textSecondary,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Complete Your Profile',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add birth details for accurate readings',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        _buildProgressBar(),
        const SizedBox(height: 6),
        Text(
          '$profileCompletion% Complete',
          style: const TextStyle(
            color: AppColors.primaryPurple,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return Stack(
      children: [
        Container(
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: profileCompletion / 100,
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArrowButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppColors.primaryPurple,
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        TextButton(
          onPressed: () => _handleSeeAll(title),
          child: const Text(
            'See All',
            style: TextStyle(
              color: AppColors.primaryPurple,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
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
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardDark,
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
    // Special handling for chat - check coins first
    if (route == '/chat_list_screen') {
      _handleChatNavigation();
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  /// Handle chat navigation with coin check
  Future<void> _handleChatNavigation() async {
    final balance = await _coinService.getBalance();

    if (!mounted) return;

    if (balance > 0) {
      // User has coins, go to chat options
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatOptionsScreen()),
      );
    } else {
      // No coins, go to payment page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaymentPage()),
      );
    }
  }

  void _handleQuickAction(String action) {
    debugPrint('Quick action tapped: $action');
  }

  void _handleSeeAll(String section) {
    debugPrint('See all tapped for: $section');
  }

  void _handleLogout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
