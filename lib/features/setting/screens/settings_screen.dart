import 'package:chat_jyotishi/features/app_widgets/app_night_mode_overlay.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/app_background_gradient.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _darkModeEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // StarFieldBackground(),
          buildGradientBackground(),
          // Container(
          //   decoration: BoxDecoration(
          //     gradient: LinearGradient(
          //       begin: Alignment.topCenter,
          //       end: Alignment.bottomCenter,
          //       colors: [
          //         Colors.black.withOpacity(0.7),
          //         AppColors.cosmicPurple.withOpacity(0.3),
          //         Colors.black.withOpacity(0.9),
          //       ],
          //       stops: const [0.0, 0.5, 1.0],
          //     ),
          //   ),
          // ),
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
                      _buildSection('Account', [
                        _buildSettingItem(
                          icon: Icons.person_rounded,
                          title: 'Edit Profile',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/user_profile_screen',
                          ),
                        ),
                        _buildSettingItem(
                          icon: Icons.lock_rounded,
                          title: 'Change Password',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/set_password_screen',
                          ),
                        ),
                        _buildSettingItem(
                          icon: Icons.phone_rounded,
                          title: 'Phone Number',
                          trailing: const Text(
                            '+977 98XXXXXXXX',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Notifications', [
                        _buildSwitchItem(
                          icon: Icons.notifications_rounded,
                          title: 'Push Notifications',
                          value: _notificationsEnabled,
                          onChanged: (val) =>
                              setState(() => _notificationsEnabled = val),
                        ),
                        _buildSwitchItem(
                          icon: Icons.volume_up_rounded,
                          title: 'Sound',
                          value: _soundEnabled,
                          onChanged: (val) =>
                              setState(() => _soundEnabled = val),
                        ),
                        _buildSwitchItem(
                          icon: Icons.vibration_rounded,
                          title: 'Vibration',
                          value: _vibrationEnabled,
                          onChanged: (val) =>
                              setState(() => _vibrationEnabled = val),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Appearance', [
                        _buildSwitchItem(
                          icon: Icons.dark_mode_rounded,
                          title: 'Dark Mode',
                          value: _darkModeEnabled,
                          onChanged: (val) =>
                              setState(() => _darkModeEnabled = val),
                        ),
                        _buildSettingItem(
                          icon: Icons.language_rounded,
                          title: 'Language',
                          trailing: Text(
                            _language,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _showLanguageDialog(),
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Privacy & Security', [
                        _buildSettingItem(
                          icon: Icons.privacy_tip_rounded,
                          title: 'Privacy Policy',
                          onTap: () => Navigator.pushNamed(context, '/privacy'),
                        ),
                        _buildSettingItem(
                          icon: Icons.security_rounded,
                          title: 'Terms & Conditions',
                          onTap: () {},
                        ),
                        _buildSettingItem(
                          icon: Icons.shield_rounded,
                          title: 'Data & Storage',
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('Support', [
                        _buildSettingItem(
                          icon: Icons.help_rounded,
                          title: 'Help & Support',
                          onTap: () => Navigator.pushNamed(context, '/support'),
                        ),
                        _buildSettingItem(
                          icon: Icons.feedback_rounded,
                          title: 'Send Feedback',
                          onTap: () => _showFeedbackDialog(),
                        ),
                        _buildSettingItem(
                          icon: Icons.star_rounded,
                          title: 'Rate Us',
                          onTap: () {},
                        ),
                      ]),
                      const SizedBox(height: 24),
                      _buildSection('About', [
                        _buildSettingItem(
                          icon: Icons.info_rounded,
                          title: 'App Version',
                          trailing: const Text(
                            'v1.0.0',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ]),
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
            'Settings',
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppColors.cosmicHeroGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              trailing
            else if (onTap != null)
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

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: AppColors.cosmicHeroGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.cosmicPink,
            activeTrackColor: AppColors.cosmicPink.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Select Language',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('नेपाली'),
            _buildLanguageOption('हिन्दी'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    final isSelected = _language == language;
    return InkWell(
      onTap: () {
        setState(() => _language = language);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple
                : Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Text(
              language,
              style: TextStyle(
                color: isSelected
                    ? AppColors.primaryPurple
                    : AppColors.textPrimary,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryPurple,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Send Feedback',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Send feedback
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Feedback sent!')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}
