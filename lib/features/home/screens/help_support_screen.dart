// lib/features/support/screens/help_support_screen.dart

import 'package:chat_jyotishi/features/app_widgets/app_night_mode_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_background_gradient.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqs = [
    FAQItem(
      question: 'How do I purchase coins?',
      answer:
          'You can purchase coins by going to the Payment section. We accept various payment methods including eSewa, Khalti, and other digital wallets. Simply select your desired coin package and complete the payment.',
    ),
    FAQItem(
      question: 'How much do astrologers charge?',
      answer:
          'Astrologers charge varies based on their experience and expertise. Typically, chat consultations range from 50-200 coins per session, while video calls may range from 200-500 coins. You can see the exact rate on each astrologer\'s profile.',
    ),
    FAQItem(
      question: 'Can I get a refund for unused coins?',
      answer:
          'Coins purchased are non-refundable. However, if you encounter any technical issues during a session, please contact our support team within 24 hours and we\'ll review your case.',
    ),
    FAQItem(
      question: 'How do I book an appointment?',
      answer:
          'Go to the Appointment section, select your preferred astrologer, choose an available time slot, and confirm your booking. You\'ll receive a notification before your scheduled session.',
    ),
    FAQItem(
      question: 'What if an astrologer doesn\'t respond?',
      answer:
          'If an astrologer doesn\'t respond within 5 minutes of your message, your coins will be automatically refunded. You can also report the issue to our support team.',
    ),
    FAQItem(
      question: 'Is my personal information secure?',
      answer:
          'Yes, we take your privacy seriously. All your personal information, birth details, and conversations are encrypted and stored securely. We never share your data with third parties without your consent.',
    ),
    FAQItem(
      question: 'Can I chat with multiple astrologers?',
      answer:
          'Yes, you can consult with multiple astrologers. Each consultation is independent and you can choose different experts for different aspects of your life.',
    ),
    FAQItem(
      question: 'How do broadcast messages work?',
      answer:
          'Broadcast messages allow you to send your query to all available astrologers. The first astrologer to accept will start the consultation with you. This is useful when you need quick assistance.',
    ),
  ];

  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          buildGradientBackground(),
          buildNightModeOverlay(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 24),
                      _buildContactCards(),
                      const SizedBox(height: 32),
                      _buildFAQSection(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Text(
            'Help & Support',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Get in Touch',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _buildContactCard(
          icon: Icons.email_rounded,
          title: 'Email Support',
          subtitle: 'support@chatjyotishi.com',
          gradient: AppColors.cosmicCardGradient,
          // onTap: () => _launchEmail(),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.phone_rounded,
          title: 'Call Us',
          subtitle: '+977 01-XXXXXXX',
          gradient: AppColors.cosmicCardGradient,
          // onTap: () => _launchPhone(),
          onTap: () {},
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.chat_bubble_rounded,
          title: 'Live Chat',
          subtitle: 'Chat with our support team',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.withOpacity(0.3),
              Colors.teal.withOpacity(0.2),
            ],
          ),
          onTap: () => _openLiveChat(),
        ),
        const SizedBox(height: 12),
        _buildContactCard(
          icon: Icons.share_rounded,
          title: 'Social Media',
          subtitle: 'Follow us on Facebook, Instagram',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.pink.withOpacity(0.3),
              Colors.purple.withOpacity(0.2),
            ],
          ),
          onTap: () => _showSocialMedia(),
        ),
      ],
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8, bottom: 16),
          child: Text(
            'Frequently Asked Questions',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ..._faqs.asMap().entries.map((entry) {
          final index = entry.key;
          final faq = entry.value;
          return _buildFAQItem(faq, index);
        }).toList(),
      ],
    );
  }

  Widget _buildFAQItem(FAQItem faq, int index) {
    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cosmicPink.withOpacity(0.5),
            AppColors.deepPurple.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? AppColors.primaryPurple.withOpacity(0.3)
              : Colors.white.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _expandedIndex = isExpanded ? null : index;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          faq.question,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: isExpanded
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: isExpanded ? AppColors.cosmicPink : Colors.white,
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardDark.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        faq.answer,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _launchEmail() async {
  //   final Uri emailUri = Uri(
  //     scheme: 'mailto',
  //     path: 'support@chatjyotishi.com',
  //     query: 'subject=Support Request',
  //   );
  //   if (await canLaunchUrl(emailUri)) {
  //     await launchUrl(emailUri);
  //   }
  // }

  // void _launchPhone() async {
  //   final Uri phoneUri = Uri(scheme: 'tel', path: '+97701XXXXXXX');
  //   if (await canLaunchUrl(phoneUri)) {
  //     await launchUrl(phoneUri);
  //   }
  // }

  void _openLiveChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Live Chat',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Live chat feature coming soon! Please use email or phone support for now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  void _showSocialMedia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Follow Us',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            _buildSocialButton(
              icon: Icons.facebook,
              label: 'Facebook',
              color: const Color(0xFF1877F2),
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              icon: Icons.camera_alt,
              label: 'Instagram',
              color: const Color(0xFFE4405F),
              onTap: () {},
            ),
            const SizedBox(height: 12),
            _buildSocialButton(
              icon: Icons.telegram,
              label: 'Telegram',
              color: const Color(0xFF0088CC),
              onTap: () {},
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this.question, required this.answer});
}
