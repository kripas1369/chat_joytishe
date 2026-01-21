import 'package:flutter/material.dart';

void showTopSnackBar({
  required BuildContext context,
  required String message,
  IconData icon = Icons.check_circle,
  Color backgroundColor = const Color(0xFF063E2E),
  Duration duration = const Duration(seconds: 2),
}) {
  if (!context.mounted) return;

  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      return Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 18,
        right: 18,
        child: Material(
          color: Colors.transparent,
          child: Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  Future.delayed(duration, () {
    entry.remove();
  });
}
