import 'package:chat_jyotishi/constants/constant.dart';
import 'package:flutter/material.dart';

Widget buildAppLogo() {
  return Column(
    children: [
      Container(
        height: 150,
        width: 150,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPurple.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.asset('assets/logo/logo.png', fit: BoxFit.cover),
        ),
      ),
      const SizedBox(height: 20),
      ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Colors.white, AppColors.lightPurple],
        ).createShader(bounds),
        child: const Text(
          'ChatJyotishi',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Your Cosmic Guide to Life',
        style: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );
}
