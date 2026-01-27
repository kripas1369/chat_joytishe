import 'package:chat_jyotishi/constants/constant.dart';
import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscure;
  final IconData? suffixIcon;
  final IconData? prefixIcon;
  final TextEditingController? controller;

  const InputField({
    super.key,
    required this.label,
    this.hint,
    this.obscure = false,
    this.suffixIcon,
    this.prefixIcon,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white, fontSize: 12)),
        SizedBox(height: 6),
        TextFormField(
          controller: controller,
          cursorColor: AppColors.cosmicPurple,
          cursorWidth: 2,
          obscureText: obscure,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.white70)
                : null,
            suffixIcon: suffixIcon != null
                ? Icon(suffixIcon, color: Colors.white)
                : null,
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textGray400),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.5),
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
