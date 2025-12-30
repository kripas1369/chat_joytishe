import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final List<Color>? gradientColors;
  final Widget? prefixIcon;
  final double? height;
  final Widget? suffixIcon;

  const AppButton({
    super.key,
    required this.title,
    required this.onTap,
    this.gradientColors,
    this.prefixIcon,
    this.height,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ?? [Color(0xFF460C68), Color(0xFF8309CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (prefixIcon != null) ...[prefixIcon!, SizedBox(width: 8)],
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(width: 8),
              if (suffixIcon != null) ...[suffixIcon!],
            ],
          ),
        ),
      ),
    );
  }
}
