import 'package:chat_jyotishi/features/app_widgets/app_logo.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/setting/widgets/password_text_field.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool currentVisible = false;
  bool newVisible = false;
  bool confirmVisible = false;

  final TextEditingController currentController = TextEditingController();
  final TextEditingController newController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(0.9),
            ),
          ),
          Positioned(
            top: 60,
            left: 24,
            child: GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  buildAppLogo(),
                  SizedBox(height: 24),
                  _card(context),
                ],
              ),
            ),
          ),
          _footer(),
        ],
      ),
    );
  }

  Widget _card(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.15),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PasswordTextField(
            controller: currentController,
            label: 'Current Password',
            hint: 'Enter your current password',
            isVisible: currentVisible,
            onVisibilityToggle: () {
              setState(() => currentVisible = !currentVisible);
            },
          ),
          SizedBox(height: 16),

          PasswordTextField(
            controller: newController,
            label: 'New Password',
            hint: 'Enter your new password',
            isVisible: newVisible,
            onVisibilityToggle: () {
              setState(() => newVisible = !newVisible);
            },
          ),
          SizedBox(height: 16),

          PasswordTextField(
            controller: confirmController,
            label: 'Confirm New Password',
            hint: 'Re-enter your new password',
            isVisible: confirmVisible,
            onVisibilityToggle: () {
              setState(() => confirmVisible = !confirmVisible);
            },
          ),
          SizedBox(height: 28),

          SizedBox(
            child: AppButton(title: 'CHANGE PASSWORD', onTap: () {}),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Positioned(
      bottom: 30,
      left: 1,
      right: 1,
      child: Text(
        'Securing your celestial access…',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.white70),
      ),
    );
  }
}
