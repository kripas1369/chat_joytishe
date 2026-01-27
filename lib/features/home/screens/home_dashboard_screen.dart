import 'dart:convert';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/home/widgets/rotating_question_widget.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_states.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/home/screens/welcome_screen.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  final CoinService _coinService = CoinService();
  final SocketService _socketService = SocketService();

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final String userName = 'Praveen';
  final String userEmail = 'praveen@example.com';
  final int notificationCount = 3;
  bool _isConnecting = false;

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

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return BlocProvider(
      create: (context) =>
          ChatBloc(chatRepository: ChatRepository(ChatService()))
            ..add(FetchActiveUsersEvent()),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // Background
            StarFieldBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlack,
                    AppColors.cosmicPurple.withOpacity(0.1),
                    AppColors.primaryBlack,
                  ],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            _buildHeader(),
                            const SizedBox(height: 20),
                            const RotatingQuestionsWidget(),
                            const SizedBox(height: 24),
                            _buildLiveJyotishSection(),
                            const SizedBox(height: 28),
                            _buildDailyFeaturesSection(),
                            const SizedBox(height: 28),
                            _buildServicesGrid(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const WelcomeScreen(),
                  ),
                );
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicPrimaryGradient,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cosmicPurple.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
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
          shaderCallback: (bounds) =>
              AppColors.cosmicPrimaryGradient.createShader(bounds),
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
              color: AppColors.cosmicPurple.withOpacity(_pulseAnimation.value),
            );
          },
        ),
      ],
    );
  }

  // Live Active Jyotish Section - Messenger Style
  Widget _buildLiveJyotishSection() {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isLoading = state is ActiveUsersLoading;
        final astrologers = state is ActiveUsersLoaded
            ? state.astrologers.where((a) => a.isOnline).toList()
            : <ActiveAstrologerModel>[];

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.5),
                AppColors.cosmicPurple.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.cosmicPrimaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.sensors,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Live Jyotish',
                                style: TextStyle(
                                  color: AppColors.textWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(
                                            0.5,
                                          ),
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${astrologers.length} Online',
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (isLoading)
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cosmicPurple,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => context.read<ChatBloc>().add(
                            RefreshActiveUsersEvent(),
                          ),
                          icon: Icon(
                            Icons.refresh,
                            color: AppColors.textGray300,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: astrologers.isEmpty && !isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person_off_outlined,
                                  color: AppColors.textGray400,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'No Jyotish online right now',
                                  style: TextStyle(
                                    color: AppColors.textGray400,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: astrologers.length,
                            itemBuilder: (context, index) {
                              final astrologer = astrologers[index];
                              return _buildJyotishCard(astrologer);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJyotishCard(ActiveAstrologerModel astrologer) {
    final String imageUrl = astrologer.profilePhoto.startsWith('http')
        ? astrologer.profilePhoto
        : '${ApiEndpoints.socketUrl}${astrologer.profilePhoto}';

    return GestureDetector(
      onTap: () => _handleJyotishTap(astrologer),
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar with animated border
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.cosmicPurple,
                        AppColors.cosmicPink,
                        AppColors.cosmicPurple,
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryBlack,
                    ),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.cardMedium,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? Text(
                              astrologer.name.isNotEmpty
                                  ? astrologer.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
                // Online indicator
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryBlack,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.greenAccent.withOpacity(0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              astrologer.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textWhite,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Daily Features Section
  Widget _buildDailyFeaturesSection() {
    final dailyFeatures = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Daily Horoscope',
        'subtitle': 'Your daily celestial guide',
        'color': AppColors.cosmicPurple,
        'route': '/horoscope_screen',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Shubha-Ashubh Sait',
        'subtitle': 'Auspicious timings today',
        'color': AppColors.cosmicPink,
        'route': '/shubha_ashubh',
      },
      {
        'icon': Icons.flight_takeoff_rounded,
        'title': 'Travel Prediction',
        'subtitle': 'Safe travel guidance',
        'color': AppColors.cosmicRed,
        'route': '/travel_prediction',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.5),
            AppColors.cosmicPink.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cosmicPink.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.cosmicPink, AppColors.cosmicRed],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Insights',
                        style: TextStyle(
                          color: AppColors.textWhite,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Updated every day',
                        style: TextStyle(
                          color: AppColors.textGray400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...dailyFeatures.map(
                (feature) => _buildDailyFeatureCard(
                  icon: feature['icon'] as IconData,
                  title: feature['title'] as String,
                  subtitle: feature['subtitle'] as String,
                  color: feature['color'] as Color,
                  onTap: () => _navigateTo(feature['route'] as String),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.7)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textGray400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: color,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Services Grid
  Widget _buildServicesGrid() {
    final services = [
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'Chat with Jyotish',
        'subtitle': 'Instant',
        'features': ['Verified Jyotish', 'Secure chat & fast replies'],
        'cta': 'Start Chatting',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
        ),
        'route': '/chat_list_screen',
        'isComingSoon': false,
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Book Appointment',
        'subtitle': 'Full kundali review',
        'features': ['Detailed analysis', '1:1 consultation slots'],
        'cta': 'Book Now',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPink, AppColors.cosmicRed],
        ),
        'route': '/appointment',
        'isComingSoon': false,
      },
      {
        'icon': Icons.person_pin_rounded,
        'title': 'Book Pandit Ji',
        'subtitle': 'Rituals & puja',
        'features': ['Puja & rituals booking', 'Verified pandit network'],
        'cta': 'Book Now',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicRed, AppColors.cosmicPurple],
        ),
        'route': '/book_pandit',
        'isComingSoon': false,
      },
      {
        'icon': Icons.home_work_rounded,
        'title': 'Book Vaastu Sastri',
        'subtitle': 'Home & office vaastu',
        'features': ['Vastu guidance', 'Home & office remedies'],
        'cta': 'Book Now',
        'gradient': LinearGradient(
          colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
        ),
        'route': '/vastustra',
        'isComingSoon': false,
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Katha Vachak',
        'subtitle': 'Events & programs',
        'features': ['कथा वाचन booking', 'Events & programs'],
        'cta': 'Book Now',
        'gradient': LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        'route': '/katha_vachak',
        'isComingSoon': false,
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Kundali Match',
        'subtitle': 'Compatibility insights',
        'features': ['Dosha & remedies', 'Match analysis'],
        'cta': 'Coming Soon',
        'gradient': LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569)],
        ),
        'route': null,
        'isComingSoon': true,
      },
      {
        'icon': Icons.flight_takeoff_rounded,
        'title': 'Travel Prediction',
        'subtitle': 'Auspicious dates',
        'features': ['Safe travel guidance', 'Best travel times'],
        'cta': 'Coming Soon',
        'gradient': LinearGradient(
          colors: [Color(0xFF64748B), Color(0xFF475569)],
        ),
        'route': null,
        'isComingSoon': true,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.black.withOpacity(0.5),
            AppColors.cosmicRed.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.cosmicRed.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.cosmicRed.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(21),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enhanced Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: AppColors.cosmicPrimaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cosmicPurple.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Our Services',
                            style: TextStyle(
                              color: AppColors.textWhite,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.textGray400.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Explore all features',
                                style: TextStyle(
                                  color: AppColors.textGray400,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Optional Filter/View Toggle
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.textWhite.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.textWhite.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: AppColors.textGray400,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Enhanced Grid with staggered animations
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 400 + (index * 80)),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * value),
                        child: Opacity(opacity: value, child: child),
                      );
                    },
                    child: _buildServiceCard(
                      icon: service['icon'] as IconData,
                      title: service['title'] as String,
                      subtitle: service['subtitle'] as String,
                      gradient: service['gradient'] as LinearGradient,
                      isComingSoon: service['isComingSoon'] as bool,
                      onTap: service['route'] != null
                          ? () => _navigateTo(service['route'] as String)
                          : null,
                      index: index,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Service Card Builder
  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required bool isComingSoon,
    VoidCallback? onTap,
    required int index,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      tween: Tween(begin: 1.0, end: 1.0),
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: GestureDetector(
        onTapDown: (_) {
          // Add haptic feedback for better UX
          HapticFeedback.lightImpact();
        },
        onTap: isComingSoon ? null : onTap,
        child: AnimatedContainer(
          height: 400,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isComingSoon
                  ? [
                      const Color(0xFF1E293B).withOpacity(0.6),
                      const Color(0xFF0F172A).withOpacity(0.8),
                    ]
                  : [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.03),
                    ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isComingSoon
                  ? Colors.white.withOpacity(0.05)
                  : Colors.white.withOpacity(0.12),
              width: 1.5,
            ),
            boxShadow: [
              if (!isComingSoon)
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Stack(
                children: [
                  // Gradient Accent Line (Top)
                  if (!isComingSoon)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(gradient: gradient),
                      ),
                    ),

                  // Main Content
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Container with Gradient
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isComingSoon
                                    ? LinearGradient(
                                        colors: [
                                          const Color(
                                            0xFF64748B,
                                          ).withOpacity(0.3),
                                          const Color(
                                            0xFF475569,
                                          ).withOpacity(0.3),
                                        ],
                                      )
                                    : gradient,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  if (!isComingSoon)
                                    BoxShadow(
                                      color: gradient.colors.first.withOpacity(
                                        0.4,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 24),
                            ),

                            // Coming Soon Badge or Status Indicator
                            if (isComingSoon)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF64748B,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF64748B,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Soon',
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: gradient.colors.first.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    gradient: gradient,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: gradient.colors.first
                                            .withOpacity(0.6),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Title
                        Text(
                          title,
                          style: TextStyle(
                            color: isComingSoon
                                ? AppColors.textGray400
                                : AppColors.textWhite,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        // Subtitle
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isComingSoon
                                ? AppColors.textGray400.withOpacity(0.6)
                                : AppColors.textGray400,
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            letterSpacing: 0.1,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // Action Button/Indicator
                        Row(
                          children: [
                            if (!isComingSoon) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: gradient.colors.first.withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: gradient.colors.first.withOpacity(
                                      0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Explore',
                                      style: TextStyle(
                                        color: gradient.colors.first
                                            .withOpacity(0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: gradient.colors.first.withOpacity(
                                        0.8,
                                      ),
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Icon(
                                Icons.lock_outline_rounded,
                                color: AppColors.textGray400.withOpacity(0.4),
                                size: 16,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Shimmer effect for coming soon cards
                  if (isComingSoon)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.02),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
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

  Future<void> _handleJyotishTap(ActiveAstrologerModel astrologer) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      final decodedToken = decodeJwt(accessToken);
      final currentUserId = decodedToken?['id'] ?? '';

      if (currentUserId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid token. Please login again.'),
              backgroundColor: AppColors.error,
            ),
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: '',
            otherUserId: astrologer.id,
            otherUserName: astrologer.name,
            otherUserPhoto: astrologer.profilePhoto,
            currentUserId: currentUserId,
            accessToken: accessToken,
            refreshToken: refreshToken,
            isOnline: astrologer.isOnline,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to connect. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

}

// Service Card Widget
class _ServiceCardWidget extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final bool isComingSoon;
  final VoidCallback? onTap;
  final Animation<double> pulseAnimation;

  const _ServiceCardWidget({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.isComingSoon,
    this.onTap,
    required this.pulseAnimation,
  });

  @override
  State<_ServiceCardWidget> createState() => _ServiceCardWidgetState();
}

class _ServiceCardWidgetState extends State<_ServiceCardWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isComingSoon ? null : widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(_isPressed && !widget.isComingSoon ? 1.02 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.black.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isPressed && !widget.isComingSoon
                ? widget.gradient.colors.first.withOpacity(0.6)
                : widget.gradient.colors.first.withOpacity(0.3),
            width: _isPressed && !widget.isComingSoon ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _isPressed && !widget.isComingSoon
                  ? widget.gradient.colors.first.withOpacity(0.4)
                  : widget.gradient.colors.first.withOpacity(0.2),
              blurRadius: _isPressed && !widget.isComingSoon ? 30 : 20,
              spreadRadius: _isPressed && !widget.isComingSoon ? 2 : 0,
              offset: Offset(0, _isPressed && !widget.isComingSoon ? 12 : 8),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Animated gradient glow
              AnimatedBuilder(
                animation: widget.pulseAnimation,
                builder: (context, child) {
                  return Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topRight,
                          radius: 1.5,
                          colors: [
                            widget.gradient.colors.first.withOpacity(
                              (_isPressed ? 0.25 : 0.15) *
                                  widget.pulseAnimation.value,
                            ),
                            widget.gradient.colors.last.withOpacity(
                              (_isPressed ? 0.15 : 0.08) *
                                  widget.pulseAnimation.value,
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Backdrop filter
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: widget.gradient,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.gradient.colors.first
                                      .withOpacity(_isPressed ? 0.7 : 0.5),
                                  blurRadius: _isPressed ? 25 : 18,
                                  spreadRadius: _isPressed ? 3 : 2,
                                  offset: Offset(0, _isPressed ? 10 : 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: _isPressed ? 36 : 34,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Title
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: _isPressed ? 21 : 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Subtitle
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: AppColors.textGray300,
                              fontSize: 13,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      // Bottom section with arrow
                      if (!widget.isComingSoon)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  color: widget.gradient.colors.first,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                transform: Matrix4.identity()
                                  ..translate(_isPressed ? 4.0 : 0.0, 0.0),
                                child: Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: widget.gradient.colors.first,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.amber.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule_rounded,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Soon',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Coming Soon overlay
              if (widget.isComingSoon)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
