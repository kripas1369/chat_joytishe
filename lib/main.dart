import 'package:chat_jyotishi/features/chat/screens/chat_list_screen.dart';
import 'package:chat_jyotishi/features/home/screens/horroscope_screen.dart';
import 'package:chat_jyotishi/features/profile/screens/change_password_screen.dart';
import 'package:chat_jyotishi/features/profile/screens/set_password_screen.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/profile/screens/user_profile_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/splash_screen': (context) => SplashScreen(),
        '/login_screen': (context) => LoginScreen(),
        '/home_screen': (context) => HomeScreen(),
        '/user_profile_screen': (context) => UserProfileScreen(),
        '/horoscope_screen': (context) => HoroscopeScreen(),
        '/chat_screen': (context) => ChatScreen(),
        '/set_password_screen': (context) => SetPasswordScreen(),
        '/change_password_screen': (context) => ChangePasswordScreen(),
        '/chat_list_screen': (context) => ChatListScreen(),
      },
      initialRoute: '/splash_screen',
    );
  }
}
