import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/app_button.dart';
import '../../auth/widgets/input_field.dart';
import '../../app_widgets/star_field_background.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient.withOpacity(0.9)),
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
          // Current Password
          Stack(
            alignment: Alignment.centerRight,
            children: [
              InputField(
                label: 'Current Password',
                obscure: !currentVisible,
                prefixIcon: Icons.lock_outline,
              ),
            ],
          ),
          SizedBox(height: 16),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              InputField(
                label: 'New Password',
                obscure: !newVisible,
                prefixIcon: Icons.lock_outline,
              ),
              Positioned(
                bottom: 5,
                child: IconButton(
                  icon: Icon(
                    newVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() => newVisible = !newVisible);
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Confirm New Password
          Stack(
            alignment: Alignment.centerRight,
            children: [
              InputField(
                label: 'Confirm New Password',

                obscure: !confirmVisible,
                prefixIcon: Icons.lock_outline,
              ),
              Positioned(
                bottom: 5,
                child: IconButton(
                  icon: Icon(
                    confirmVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() => confirmVisible = !confirmVisible);
                  },
                ),
              ),
            ],
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
