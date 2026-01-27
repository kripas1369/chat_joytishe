import 'package:chat_jyotishi/features/app_widgets/app_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/home/screens/home_dashboard_screen.dart';
import 'package:chat_jyotishi/features/home/screens/home_screen_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/app_background_gradient.dart';
import '../../app_widgets/glass_icon_button.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Ordinary', 'Professional', 'Premium'];

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
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // buildGradientBackground(),
          StarFieldBackground(),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildAstrologersList()),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeDashboardScreen()),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Connect with expert astrologers',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((filter) {
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedFilter = filter;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? AppColors.cosmicHeroGradient
                      : LinearGradient(
                          colors: [
                            AppColors.cardDark.withOpacity(0.5),
                            AppColors.cardMedium.withOpacity(0.3),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryPurple.withOpacity(0.5)
                        : Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAstrologersList() {
    final astrologers = _getFilteredAstrologers();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: astrologers.length,
      itemBuilder: (context, index) {
        return _buildAstrologerCard(astrologers[index], index);
      },
    );
  }

  Widget _buildAstrologerCard(Map<String, dynamic> astrologer, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TweenAnimationBuilder(
        duration: Duration(milliseconds: 300 + (index * 100)),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Opacity(opacity: value, child: child),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.cardDark.withOpacity(0.8),
                AppColors.cardMedium.withOpacity(0.4),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAstrologerAvatar(astrologer),
                  const SizedBox(width: 16),
                  Expanded(child: _buildAstrologerInfo(astrologer)),
                ],
              ),
              const SizedBox(height: 16),
              _buildAstrologerActions(astrologer),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAstrologerAvatar(Map<String, dynamic> astrologer) {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _getTierGradient(astrologer['tier']),
          ),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardDark,
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.cardMedium,
              backgroundImage: astrologer['image'] != null
                  ? AssetImage(astrologer['image'])
                  : null,
              child: astrologer['image'] == null
                  ? const Icon(
                      Icons.person_rounded,
                      color: AppColors.textSecondary,
                      size: 36,
                    )
                  : null,
            ),
          ),
        ),
        if (astrologer['isOnline'] ?? false)
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardDark, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAstrologerInfo(Map<String, dynamic> astrologer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                astrologer['name'],
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _buildTierBadge(astrologer['tier']),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          astrologer['specialization'],
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildInfoChip(
              Icons.star_rounded,
              astrologer['rating'].toString(),
              Colors.amber,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.access_time_rounded,
              '${astrologer['experience']} yrs',
              AppColors.primaryPurple,
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.people_rounded,
              '${astrologer['consultations']}+',
              AppColors.lightPurple,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.language_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              astrologer['languages'].join(', '),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTierBadge(String tier) {
    Color color;
    String label;

    switch (tier.toLowerCase()) {
      case 'premium':
        color = Colors.pinkAccent;
        label = 'Premium';
        break;
      case 'professional':
        color = gold;
        label = 'Pro';
        break;
      default:
        color = AppColors.textSecondary;
        label = 'Standard';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAstrologerActions(Map<String, dynamic> astrologer) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'View Profile',
            Icons.person_outline_rounded,
            false,
            () => _handleViewProfile(astrologer),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            'Book Now',
            Icons.calendar_today_rounded,
            true,
            () => _handleBookAppointment(astrologer),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    bool isPrimary,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? AppColors.cosmicHeroGradient
              : LinearGradient(
                  colors: [
                    AppColors.cardDark.withOpacity(0.6),
                    AppColors.cardMedium.withOpacity(0.4),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary
                ? AppColors.primaryPurple.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isPrimary
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: isPrimary
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getTierGradient(String tier) {
    switch (tier.toLowerCase()) {
      case 'premium':
        return AppColors.cosmicHeroGradient;
      case 'professional':
        return AppColors.professionalGradient;
      default:
        return AppColors.standardGradient;
    }
  }

  List<Map<String, dynamic>> _getFilteredAstrologers() {
    final allAstrologers = [
      {
        'name': 'Dr. Ravi Sharma',
        'specialization': 'Vedic Astrology & Palmistry',
        'tier': 'Premium',
        'rating': 4.9,
        'experience': 15,
        'consultations': 5000,
        'languages': ['Hindi', 'English', 'Sanskrit'],
        'isOnline': true,
        'image': null,
      },
      {
        'name': 'Priya Devi',
        'specialization': 'Numerology & Tarot Reading',
        'tier': 'Professional',
        'rating': 4.8,
        'experience': 10,
        'consultations': 3500,
        'languages': ['Hindi', 'English'],
        'isOnline': true,
        'image': null,
      },
      {
        'name': 'Acharya Suresh',
        'specialization': 'Kundli Analysis & Gemstones',
        'tier': 'Premium',
        'rating': 4.9,
        'experience': 20,
        'consultations': 8000,
        'languages': ['Hindi', 'English', 'Bengali'],
        'isOnline': false,
        'image': null,
      },
      {
        'name': 'Meera Joshi',
        'specialization': 'Love & Relationship',
        'tier': 'Ordinary',
        'rating': 4.6,
        'experience': 5,
        'consultations': 1200,
        'languages': ['Hindi', 'English'],
        'isOnline': true,
        'image': null,
      },
      {
        'name': 'Pt. Ramesh Tiwari',
        'specialization': 'Career & Finance Astrology',
        'tier': 'Professional',
        'rating': 4.7,
        'experience': 12,
        'consultations': 4200,
        'languages': ['Hindi', 'English', 'Marathi'],
        'isOnline': true,
        'image': null,
      },
      {
        'name': 'Anjali Verma',
        'specialization': 'Health & Wellness',
        'tier': 'Ordinary',
        'rating': 4.5,
        'experience': 6,
        'consultations': 1800,
        'languages': ['Hindi', 'English'],
        'isOnline': false,
        'image': null,
      },
      {
        'name': 'Dr. Vikram Rao',
        'specialization': 'Marriage Compatibility',
        'tier': 'Premium',
        'rating': 4.9,
        'experience': 18,
        'consultations': 6500,
        'languages': ['Hindi', 'English', 'Telugu'],
        'isOnline': true,
        'image': null,
      },
      {
        'name': 'Sanjay Gupta',
        'specialization': 'Business Astrology',
        'tier': 'Professional',
        'rating': 4.8,
        'experience': 11,
        'consultations': 3800,
        'languages': ['Hindi', 'English', 'Punjabi'],
        'isOnline': false,
        'image': null,
      },
    ];

    if (selectedFilter == 'All') {
      return allAstrologers;
    }

    return allAstrologers
        .where(
          (astrologer) =>
              astrologer['tier'].toString().toLowerCase() ==
              selectedFilter.toLowerCase(),
        )
        .toList();
  }

  void _handleViewProfile(Map<String, dynamic> astrologer) {
    debugPrint('View profile: ${astrologer['name']}');
    // Navigate to astrologer profile screen
    // Navigator.pushNamed(context, '/astrologer_profile', arguments: astrologer);
  }

  void _handleBookAppointment(Map<String, dynamic> astrologer) {
    debugPrint('Book appointment with: ${astrologer['name']}');
    // Show booking dialog or navigate to booking screen
    _showBookingDialog(astrologer);
  }

  void _showBookingDialog(Map<String, dynamic> astrologer) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.backgroundGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryPurple.withOpacity(0.2),
                  AppColors.deepPurple.withOpacity(0.1),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 48,
                  color: AppColors.primaryPurple,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Book Appointment',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'with ${astrologer['name']}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Are you sure !',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                AppButton(
                  title: 'Book Now',
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
