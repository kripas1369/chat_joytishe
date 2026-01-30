import 'package:chat_jyotishi/constants/constant.dart';
import 'package:flutter/material.dart';

class PasswordTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isVisible;
  final VoidCallback onVisibilityToggle;

  const PasswordTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.isVisible,
    required this.onVisibilityToggle,
  });

  @override
  State<PasswordTextField> createState() => _PasswordTextFieldState();
}

class _PasswordTextFieldState extends State<PasswordTextField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: AnimatedContainer(
        height: 72,
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hasFocus
                ? AppColors.cosmicPink.withOpacity(0.5)
                : Colors.white.withOpacity(0.08),
            width: _hasFocus ? 1.5 : 1,
          ),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.cosmicPink.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: TextFormField(
          controller: widget.controller,
          obscureText: !widget.isVisible,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            labelStyle: TextStyle(
              color: _hasFocus ? AppColors.cosmicPink : AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                Icons.lock_outline,
                color: _hasFocus ? AppColors.cosmicPink : AppColors.textMuted,
                size: 22,
              ),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                widget.isVisible ? Icons.visibility : Icons.visibility_off,
                color: _hasFocus
                    ? AppColors.cosmicPink.withOpacity(0.7)
                    : Colors.white70,
              ),
              onPressed: widget.onVisibilityToggle,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 50),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ),
    );
  }
}
