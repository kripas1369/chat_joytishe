import 'package:flutter/material.dart';

const Color gold = Color(0xFFF5C84C);
const Color cardColor = Color(0xFF0A1025);

class AppColors {
  static const Color primaryPurple = Color(0xFF9B4DFF);
  static const Color deepPurple = Color(0xFF7B2FD9);
  static const Color lightPurple = Color(0xFFB76EFF);
  static const Color accentPurple = Color(0xFFAA5DFF);

  static const Color backgroundDark = Color(0xFF0A0A0F);
  static const Color backgroundMedium = Color(0xFF12121A);
  static const Color cardDark = Color(0xFF1A1A25);
  static const Color cardMedium = Color(0xFF222233);
  static const Color inputField = Color(0xFF1E1E2E);
  static const Color inputFieldColor = Color(0xFF0A1025);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8B8C8);
  static const Color textMuted = Color(0xFF6B6B80);
  static const Color textHint = Color(0xFF4A4A5A);

  static const Color starWhite = Color(0xFFE8E8FF);
  static const Color glowPurple = Color(0x409B4DFF);

  static const Color success = Color(0xFF19611C);
  static const Color error = Color(0xFFA51010);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, deepPurple],
  );
  static const LinearGradient featureCardGradient2 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7B4DFF), Color(0xFF5B2FC9)],
  );
  static const LinearGradient featureCardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF9B4DFF), Color(0xFF6B2FD9)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A3D), Color(0xFF1A1A28)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF15152A), Color(0xFF0A0A12), Color(0xFF050508)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x20FFFFFF), Color(0x00FFFFFF)],
  );

  static const LinearGradient cardGradient1 = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primaryPurple, AppColors.deepPurple],
    //.withOpacity 0.15,0.08
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF61198C), Color(0xFF8309CC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
