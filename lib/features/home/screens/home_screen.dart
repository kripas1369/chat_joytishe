import 'package:chat_jyotishi/features/auth/screens/login_screen.dart';
import 'package:chat_jyotishi/features/home/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/home/widgets/gradient_button.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/home/widgets/quick_action_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../constants/constant.dart';
import '../widgets/feature_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.backgroundDark,
      ),
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),

          Positioned(
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
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16),
                          _buildHeader(),
                          SizedBox(height: 32),
                          _buildWelcomeSection(),
                          SizedBox(height: 32),
                          _buildFeatureGrid(),
                          SizedBox(height: 32),
                          _buildQuickActions(),
                          SizedBox(height: 32),
                          _buildProfileCard(),
                          SizedBox(height: 40),
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
            SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.white, AppColors.lightPurple],
              ).createShader(bounds),
              child: RichText(
                text: TextSpan(
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
            SizedBox(width: 4),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryPurple.withOpacity(
                    _pulseAnimation.value,
                  ),
                );
              },
            ),
          ],
        ),
        NotificationButton(notificationCount: 3, onTap: () {}),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(24),
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
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 14,
                      color: AppColors.lightPurple,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Good Morning',
                      style: TextStyle(
                        color: AppColors.lightPurple,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Namaste, Praveen',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'The stars align in your favor today.\nDiscover what the cosmos has in store for you.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          SizedBox(height: 20),
          GradientButton(
            text: 'View Today\'s Horoscope',
            icon: Icons.auto_awesome,
            onTap: () {
              Navigator.of(context).pushNamed('/horoscope_screen');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Explore', 'Discover cosmic insights'),
        SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
          children: [
            FeatureCard(
              icon: Icons.chat_bubble_rounded,
              title: 'Chat',
              subtitle: 'Talk to astrologers',
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF9B4DFF), Color(0xFF6B2FD9)],
              ),
              onTap: () => Navigator.of(context).pushNamed('/chat_list_screen'),
              delay: 0,
            ),
            FeatureCard(
              icon: Icons.auto_awesome,
              title: 'Horoscope',
              subtitle: 'Daily predictions',
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF7B4DFF), Color(0xFF5B2FC9)],
              ),
              onTap: () => Navigator.of(context).pushNamed('/horoscope_screen'),
              delay: 100,
            ),
            FeatureCard(
              icon: Icons.videocam_rounded,
              title: 'Live Session',
              subtitle: '1:1 consultation',
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8B5DFF), Color(0xFF5B3FC9)],
              ),
              onTap: () {},
              delay: 200,
            ),
            FeatureCard(
              icon: Icons.self_improvement_rounded,
              title: 'Kundali',
              subtitle: 'Birth chart analysis',
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFAB6DFF), Color(0xFF7B4FD9)],
              ),
              onTap: () {},
              delay: 300,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Popular Services', 'Services we provide'),
        SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Row(
            children: [
              QuickActionChip(
                icon: Icons.favorite_rounded,
                label: 'Love',
                onTap: () {},
              ),
              QuickActionChip(
                icon: Icons.work_rounded,
                label: 'Career',
                onTap: () {},
              ),
              QuickActionChip(
                icon: Icons.attach_money_rounded,
                label: 'Finance',
                onTap: () {},
              ),
              QuickActionChip(
                icon: Icons.health_and_safety_rounded,
                label: 'Health',
                onTap: () {},
              ),
              QuickActionChip(
                icon: Icons.school_rounded,
                label: 'Education',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/user_profile_screen'),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardDark,
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.cardMedium,
                  child: Icon(
                    Icons.person_rounded,
                    color: AppColors.textSecondary,
                    size: 28,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Complete Your Profile',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add birth details for accurate readings',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  SizedBox(height: 12),
                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: 0.65,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '65% Complete',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.primaryPurple,
              ),
            ),
          ],
        ),
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          child: Text(
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.primaryGradient,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardDark,
                        ),
                        child: CircleAvatar(
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
                    SizedBox(height: 16),
                    Text(
                      'Praveen Shrestha',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'praveen@example.com',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.08)),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  children: [
                    DrawerItem(
                      icon: Icons.home_rounded,
                      title: 'Home',
                      isSelected: true,
                      onTap: () => Navigator.pop(context),
                    ),
                    DrawerItem(
                      icon: Icons.person_rounded,
                      title: 'Profile',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/user_profile_screen'),
                    ),
                    DrawerItem(
                      icon: Icons.history_rounded,
                      title: 'History',
                      onTap: () {},
                    ),
                    DrawerItem(
                      icon: Icons.settings_rounded,
                      title: 'Settings',
                      onTap: () => Navigator.of(
                        context,
                      ).pushNamed('/set_password_screen'),
                    ),
                    DrawerItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help & Support',
                      onTap: () {},
                    ),
                    DrawerItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About Us',
                      onTap: () {},
                    ),
                    DrawerItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.white.withOpacity(0.08)),

              Padding(
                padding: EdgeInsets.all(16),
                child: DrawerItem(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  isDestructive: true,
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
