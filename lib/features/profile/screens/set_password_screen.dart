import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../auth/widgets/input_field.dart';
import '../../auth/widgets/star_field_background.dart';
import '../../home/screens/home_screen.dart';

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
        color: cardColor,
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
                bottom: 6,
                child: IconButton(
                  icon: Icon(
                    passwordVisible ? Icons.visibility : Icons.visibility_off,
                    color: gold,
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
                    color: gold,
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
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                // Optional: check if password matches confirm
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => HomeScreen()),
                );
              },
              child: Text(
                'SET PASSWORD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
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
