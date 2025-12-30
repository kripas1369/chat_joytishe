import 'package:chat_jyotishi/constants/constant.dart';
import 'package:flutter/material.dart';

class MethodToggle extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const MethodToggle({super.key, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Color(0xFF10162E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _tab('OTP - LOGIN', Icons.phone_android, !active),
            _tab('PASSWORD', Icons.lock, active),
          ],
        ),
      ),
    );
  }

  Widget _tab(String text, IconData icon, bool enabled) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primaryPurple.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? Colors.white : Colors.white54,
            ),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
