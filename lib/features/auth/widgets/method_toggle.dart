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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.cosmicPurple.withOpacity(0.2),
            width: 1,
          ),
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
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.cosmicPrimaryGradient : null,
          color: enabled ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.cosmicPurple.withOpacity(0.4),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: enabled ? Colors.white : AppColors.textGray400,
            ),
            SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: enabled ? Colors.white : AppColors.textGray300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
