import 'package:chat_jyotishi/features/app_widgets/app_button.dart';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../auth/widgets/input_field.dart';
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
          Stack(
            alignment: Alignment.centerRight,
            children: [
              InputField(
                label: 'Password',
                obscure: !passwordVisible,
                prefixIcon: Icons.lock_outline,
              ),
              Positioned(
                bottom: 5,
                child: IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white70,
                  ),
                  onPressed: () {
                    setState(() => passwordVisible = !passwordVisible);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 16),
          Stack(
            alignment: Alignment.centerRight,
            children: [
              InputField(
                label: 'Confirm Password',
                obscure: !confirmVisible,
                prefixIcon: Icons.lock_outline,
              ),
              Positioned(
                bottom: 6,
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
