import 'package:flutter/material.dart';

Widget profileStatus({
  required double radius,
  required bool isActive,
  String? profileImageUrl,
}) {
  return Stack(
    children: [
      CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        backgroundImage: profileImageUrl != null
            ? NetworkImage(profileImageUrl)
            : null,
        child: profileImageUrl == null
            ? Icon(Icons.person, color: Colors.grey[700], size: radius / 1.5)
            : null,
      ),

      if (isActive)
        Positioned(
          bottom: 3,
          right: 2,
          child: Container(
            width: radius * 0.45,
            height: radius * 0.45, // keep it perfectly circular
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
    ],
  );
}
