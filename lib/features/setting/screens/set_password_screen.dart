import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/setting/widgets/password_text_field.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';
import '../../app_widgets/star_field_background.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  bool passwordVisible = false;
  bool confirmVisible = false;

  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  @override
  void dispose() {
    passwordController.dispose();
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
            top: 78,
            left: 24,
            child: GlassIconButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: _card(context),
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
            controller: passwordController,
            label: 'Password',
            hint: 'Enter your password',
            isVisible: passwordVisible,
            onVisibilityToggle: () {
              setState(() => passwordVisible = !passwordVisible);
            },
          ),
          SizedBox(height: 16),

          // Confirm Password Field
          PasswordTextField(
            controller: confirmController,
            label: 'Confirm Password',
            hint: 'Re-enter your password',
            isVisible: confirmVisible,
            onVisibilityToggle: () {
              setState(() => confirmVisible = !confirmVisible);
            },
          ),
          SizedBox(height: 28),

          SizedBox(
            child: AppButton(title: 'SET PASSWORD', onTap: () {}),
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
