import 'package:flutter/material.dart';

Widget buildNightModeOverlay() {
  return Positioned.fill(
    child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.orange.withOpacity(0.03),
            Colors.deepOrange.withOpacity(0.05),
            Colors.amber.withOpacity(0.04),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.02)),
      ),
    ),
  );
}
