import 'dart:math';

import 'package:flutter/material.dart';

class StarFieldBackground extends StatelessWidget {
  const StarFieldBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: StarPainter(),
    );
  }
}

class StarPainter extends CustomPainter {
  final Random random = Random();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050812), Color(0xFF0A0F2A)],
        ).createShader(Offset.zero & size),
    );

    for (int i = 0; i < 120; i++) {
      final offset = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      canvas.drawCircle(
        offset,
        random.nextDouble() * 1.4,
        Paint()..color = Colors.white.withOpacity(random.nextDouble()),
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
