import 'package:flutter/material.dart';

class AnimatedStarField extends StatefulWidget {
  const AnimatedStarField({super.key});

  @override
  State<AnimatedStarField> createState() => _AnimatedStarFieldState();
}

class _AnimatedStarFieldState extends State<AnimatedStarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarFieldPainter(_controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StarFieldPainter extends CustomPainter {
  final double progress;

  _StarFieldPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;

    final starPositions = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.85, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.25),
      Offset(size.width * 0.7, size.height * 0.2),
      Offset(size.width * 0.15, size.height * 0.4),
      Offset(size.width * 0.9, size.height * 0.35),
      Offset(size.width * 0.5, size.height * 0.45),
      Offset(size.width * 0.25, size.height * 0.55),
      Offset(size.width * 0.75, size.height * 0.5),
      Offset(size.width * 0.05, size.height * 0.65),
      Offset(size.width * 0.95, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.75),
      Offset(size.width * 0.2, size.height * 0.85),
      Offset(size.width * 0.8, size.height * 0.8),
      Offset(size.width * 0.45, size.height * 0.9),
    ];

    for (int i = 0; i < starPositions.length; i++) {
      final twinkle = ((progress * 2 + i * 0.15) % 1.0);
      final opacity = 0.2 + (0.6 * (twinkle > 0.5 ? 1 - twinkle : twinkle) * 2);
      final radius = 0.5 + (i % 3) * 0.5;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(starPositions[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarFieldPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
