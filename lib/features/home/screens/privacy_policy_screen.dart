// lib/features/privacy/screens/privacy_policy_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_background_gradient.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      const SizedBox(height: 24),
                      _buildUpdateInfo(),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Information We Collect',
                        'We collect information that you provide directly to us, including:\n\n'
                            '• Personal information (name, email, phone number)\n'
                            '• Birth details (date, time, place of birth)\n'
                            '• Payment information\n'
                            '• Chat and consultation history\n'
                            '• Device information and usage data',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'How We Use Your Information',
                        'We use the information we collect to:\n\n'
                            '• Provide astrological consultations and services\n'
                            '• Process payments and transactions\n'
                            '• Send notifications and updates\n'
                            '• Improve our services and user experience\n'
                            '• Prevent fraud and ensure security\n'
                            '• Comply with legal obligations',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Information Sharing',
                        'We do not sell your personal information. We may share your information only in the following cases:\n\n'
                            '• With astrologers for consultation purposes\n'
                            '• With payment processors for transaction processing\n'
                            '• With service providers who assist in operations\n'
                            '• When required by law or legal process\n'
                            '• To protect rights, property, or safety',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Data Security',
                        'We implement industry-standard security measures to protect your personal information:\n\n'
                            '• End-to-end encryption for chat messages\n'
                            '• Secure SSL/TLS connections\n'
                            '• Regular security audits\n'
                            '• Access controls and authentication\n'
                            '• Secure data storage and backup',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Your Rights',
                        'You have the right to:\n\n'
                            '• Access your personal information\n'
                            '• Request correction of inaccurate data\n'
                            '• Request deletion of your data\n'
                            '• Withdraw consent for data processing\n'
                            '• Export your data in a readable format\n'
                            '• Opt-out of marketing communications',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Cookies and Tracking',
                        'We use cookies and similar technologies to:\n\n'
                            '• Remember your preferences and settings\n'
                            '• Analyze usage patterns and improve services\n'
                            '• Personalize content and recommendations\n'
                            '• Ensure security and prevent fraud\n\n'
                            'You can control cookie settings through your device settings.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Third-Party Services',
                        'Our app may contain links to third-party services. We are not responsible for the privacy practices of these services. We encourage you to review their privacy policies.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Children\'s Privacy',
                        'Our services are not intended for users under 18 years of age. We do not knowingly collect personal information from children. If you believe we have collected information from a child, please contact us immediately.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Data Retention',
                        'We retain your personal information for as long as necessary to provide our services and comply with legal obligations. You can request deletion of your data at any time through your account settings or by contacting support.',
                      ),
                      const SizedBox(height: 16),
                      _buildSection(
                        'Changes to This Policy',
                        'We may update this Privacy Policy from time to time. We will notify you of any significant changes through the app or via email. Your continued use of our services after changes indicates acceptance of the updated policy.',
                      ),
                      const SizedBox(height: 24),
                      _buildContactCard(),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Privacy Policy',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cosmicPink.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.cosmicPink.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.cosmicHeroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.update_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last Updated',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  'January 16, 2026',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cosmicPink.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cosmicPink.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.cosmicHeroGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_support_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Questions?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'If you have any questions about this Privacy Policy or how we handle your data, please contact us:',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactItem(Icons.email_rounded, 'privacy@chatjyotishi.com'),
          const SizedBox(height: 12),
          _buildContactItem(Icons.phone_rounded, '+977 01-XXXXXXX'),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.cosmicPink, size: 18),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
