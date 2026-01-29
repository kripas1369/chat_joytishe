import 'dart:math';
import 'dart:ui';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/home/widgets/rotating_question_widget.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/payment/services/coin_provider.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_bloc.dart';
import 'package:chat_jyotishi/features/chat/bloc/chat_events.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/home/screens/welcome_screen.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../constants/constant.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _pulseController;

  // Animations
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  final int notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Pulse animation
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
            const StarFieldBackground(),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryBlack,
                    AppColors.cosmicPurple.withOpacity(0.15),
                    AppColors.primaryBlack,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(),
                      const SizedBox(height: 24),
                      const RotatingQuestionsWidget(),
                      const SizedBox(height: 24),
                      _buildDailyInsightsSection(),
                      const SizedBox(height: 24),
                      _buildServicesSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
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
            GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                );
              },
            ),
            const SizedBox(width: 16),
            _buildAppLogo(),
          ],
        ),
        Row(
          children: [
            GlassIconButton(
              icon: Icons.history_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen()),
                );
              },
            ),
            const SizedBox(width: 8),
            NotificationButton(
              notificationCount: notificationCount,
              onTap: () => _navigateTo('/notification_screen'),
            ),
          ],
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

  // Services Section - Fixed overflow with better grid
  Widget _buildServicesSection() {
    final services = [
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'Chat with\nJyotish',
        'colors': [const Color(0xFF9333EA), const Color(0xFFDB2777)],
        'route': '/chat_options_screen',
      },
      {
        'icon': Icons.calendar_month_rounded,
        'title': 'Book\nAppointment',
        'colors': [const Color(0xFFDB2777), const Color(0xFFE44949)],
        'route': '/appointment_screen',
      },
      {
        'icon': Icons.person_pin_rounded,
        'title': 'Book\nPandit Ji',
        'colors': [const Color(0xFFE44949), const Color(0xFFF97316)],
        'route': '/book_pandit_screen',
      },
      {
        'icon': Icons.home_work_rounded,
        'title': 'Book Vaastu\nSastri',
        'colors': [const Color(0xFFF97316), const Color(0xFFFB923C)],
        'route': '/book_vaastu_sastri_screen',
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Katha\nVachak',
        'colors': [const Color(0xFF9333EA), const Color(0xFFDB2777)],
        'route': '/katha_vachak',
      },
      {
        'icon': Icons.favorite_rounded,
        'title': 'Kundali\nMatch',
        'colors': [const Color(0xFF64748B), const Color(0xFF475569)],
        'route': null,
        'isComingSoon': true,
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.2),
                AppColors.cosmicPink.withOpacity(0.15),
                AppColors.cosmicRed.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cosmicPurple.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.cosmicPink, AppColors.cosmicRed],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.grid_view_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
                        ).createShader(bounds),
                        child: const Text(
                          'Our Services',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: Colors.white.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Services Grid - Using Wrap for better flexibility
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16) / 2;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: services.map((service) {
                      final isComingSoon = service['isComingSoon'] as bool? ?? false;
                      return SizedBox(
                        width: itemWidth,
                        child: _buildServiceCard(
                          icon: service['icon'] as IconData,
                          title: service['title'] as String,
                          colors: service['colors'] as List<Color>,
                          isComingSoon: isComingSoon,
                          onTap: service['route'] != null
                              ? () => _navigateTo(service['route'] as String)
                              : null,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard({
    required IconData icon,
    required String title,
    required List<Color> colors,
    required bool isComingSoon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: isComingSoon ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isComingSoon
                ? LinearGradient(
                    colors: [
                      colors[0].withOpacity(0.2),
                      colors[1].withOpacity(0.15),
                    ],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(isComingSoon ? 0.05 : 0.2),
              width: 1.5,
            ),
            boxShadow: isComingSoon
                ? null
                : [
                    BoxShadow(
                      color: colors.first.withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: colors.last.withOpacity(0.2),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(isComingSoon ? 0.1 : 0.25),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isComingSoon
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  child: Icon(
                    icon,
                    color: isComingSoon ? AppColors.textGray400 : Colors.white,
                    size: 24,
                  ),
                ),
                if (isComingSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Soon',
                      style: TextStyle(
                        color: AppColors.textGray400,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withOpacity(0.6),
                    size: 14,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isComingSoon ? AppColors.textGray400 : Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Daily Insights Section
  Widget _buildDailyInsightsSection() {
    final insights = [
      {
        'icon': Icons.auto_awesome,
        'title': 'Daily Horoscope',
        'subtitle': 'Your celestial guide',
        'colors': [const Color(0xFF9333EA), const Color(0xFFDB2777)],
        'route': '/horoscope_screen',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Shubha-Ashubh Sait',
        'subtitle': 'Auspicious timings',
        'colors': [const Color(0xFFDB2777), const Color(0xFFE44949)],
        'route': '/shubha_ashubh',
      },
      {
        'icon': Icons.flight_takeoff_rounded,
        'title': 'Travel Prediction',
        'subtitle': 'Safe travel guidance',
        'colors': [const Color(0xFFE44949), const Color(0xFFF97316)],
        'route': '/travel_prediction',
      },
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cosmicPink.withOpacity(0.15),
                AppColors.cosmicRed.withOpacity(0.1),
                AppColors.cosmicPurple.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cosmicPink.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFFB923C)],
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [AppColors.pink300, AppColors.red300],
                        ).createShader(bounds),
                        child: const Text(
                          'Daily Insights',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
              // Insight cards
              ...insights.asMap().entries.map((entry) {
                final index = entry.key;
                final insight = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < insights.length - 1 ? 12 : 0),
                  child: _buildInsightCard(
                    icon: insight['icon'] as IconData,
                    title: insight['title'] as String,
                    subtitle: insight['subtitle'] as String,
                    colors: insight['colors'] as List<Color>,
                    onTap: () => _navigateTo(insight['route'] as String),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: colors.first.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: colors.last.withOpacity(0.2),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Navigation
  void _navigateTo(String route) {
    if (route == '/chat_options_screen' || route == '/chat_list_screen') {
      _handleChatNavigation();
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _handleChatNavigation() async {
    try {
      if (!coinProvider.isInitialized) {
        await coinProvider.initialize();
      } else {
        await coinProvider.refreshBalance();
      }
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }

    if (!mounted) return;

    if (coinProvider.balance > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatOptionsScreen()),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentPage()));
    }
  }
}

/// Custom painter for animated border
class AnimatedBorderPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  AnimatedBorderPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20.0;
    final w = size.width;
    final h = size.height;

    // Draw subtle base border
    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.cosmicPurple.withOpacity(0.1);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), Radius.circular(r)),
      basePaint,
    );

    // Calculate perimeter
    final perimeter = 2 * (w - 2 * r) + 2 * (h - 2 * r) + 2 * pi * r;

    // Line length
    const lineLength = 56.0;
    final startPos = animationValue * perimeter;

    // Get points along the line
    final points = <Offset>[];
    for (double d = 0; d <= lineLength; d += 2) {
      points.add(
        _getPointOnBorder((startPos + d) % perimeter, w, h, r, perimeter),
      );
    }

    if (points.length < 2) return;

    // Draw glow
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..shader = LinearGradient(
        colors: [
          AppColors.cosmicPink.withOpacity(0.0),
          AppColors.cosmicPink.withOpacity(0.25),
          AppColors.cosmicPink.withOpacity(0.25),
          AppColors.cosmicPink.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(points.first, points.last));

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, glowPaint);

    // Draw main line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [
          AppColors.cosmicPink.withOpacity(0.0),
          AppColors.cosmicPink.withOpacity(0.7),
          AppColors.cosmicPink.withOpacity(0.7),
          AppColors.cosmicPink.withOpacity(0.0),
        ],
      ).createShader(Rect.fromPoints(points.first, points.last));

    canvas.drawPath(path, linePaint);
  }

  Offset _getPointOnBorder(
    double pos,
    double w,
    double h,
    double r,
    double perimeter,
  ) {
    pos = pos % perimeter;

    final topEdge = w - 2 * r;
    final rightEdge = h - 2 * r;
    final bottomEdge = w - 2 * r;
    final leftEdge = h - 2 * r;
    final cornerArc = pi * r / 2;

    double accumulated = 0;

    // Top edge
    if (pos < (accumulated + topEdge)) {
      return Offset(r + (pos - accumulated), 0);
    }
    accumulated += topEdge;

    // Top-right corner
    if (pos < (accumulated + cornerArc)) {
      final angle = -pi / 2 + (pos - accumulated) / r;
      return Offset(w - r + r * cos(angle), r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Right edge
    if (pos < (accumulated + rightEdge)) {
      return Offset(w, r + (pos - accumulated));
    }
    accumulated += rightEdge;

    // Bottom-right corner
    if (pos < (accumulated + cornerArc)) {
      final angle = (pos - accumulated) / r;
      return Offset(w - r + r * cos(angle), h - r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Bottom edge
    if (pos < (accumulated + bottomEdge)) {
      return Offset(w - r - (pos - accumulated), h);
    }
    accumulated += bottomEdge;

    // Bottom-left corner
    if (pos < (accumulated + cornerArc)) {
      final angle = pi / 2 + (pos - accumulated) / r;
      return Offset(r + r * cos(angle), h - r + r * sin(angle));
    }
    accumulated += cornerArc;

    // Left edge
    if (pos < (accumulated + leftEdge)) {
      return Offset(0, h - r - (pos - accumulated));
    }
    accumulated += leftEdge;

    // Top-left corner
    final angle = pi + (pos - accumulated) / r;
    return Offset(r + r * cos(angle), r + r * sin(angle));
  }

  @override
  bool shouldRepaint(covariant AnimatedBorderPainter oldDelegate) {
    return animationValue != oldDelegate.animationValue;
  }
}
