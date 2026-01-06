import 'package:chat_jyotishi/constants/constant.dart';
import 'package:flutter/material.dart';

Widget profileStatus({
  required double radius,
  required bool isActive,
  String name = '',
  String profileImageUrl = '',
}) {
  return Stack(
    children: [
      Container(
        padding: EdgeInsets.all(radius * 0.08),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isActive
              ? LinearGradient(colors: [Colors.green, Colors.greenAccent])
              : LinearGradient(colors: [Colors.grey, Colors.grey.shade600]),
        ),
        child: Container(
          padding: EdgeInsets.all(radius * 0.08),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.backgroundDark,
          ),
          child: CircleAvatar(
            radius: radius,
            backgroundColor: AppColors.cardMedium,
            backgroundImage: profileImageUrl.isNotEmpty
                ? NetworkImage(profileImageUrl)
                : null,
            child: profileImageUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: radius * 0.8,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),
      ),
      if (isActive)
        Positioned(
          bottom: radius * 0.1,
          right: radius * 0.1,
          child: Container(
            width: radius * 0.5,
            height: radius * 0.5,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,

              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: Colors.greenAccent.withOpacity(0.5),
                        blurRadius: radius * 0.4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
    ],
  );
}
