import 'package:chat_jyotishi/features/auth/screens/login_screen_astrologer.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_list_screen.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/chat_list_screen_astrologer.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/incoming_requests_screen.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/broadcast_messages_screen.dart';
import 'package:chat_jyotishi/features/home/screens/home_screen_client.dart'
    show HomeScreenClient;
import 'package:chat_jyotishi/features/home/screens/horroscope_screen.dart';
import 'package:chat_jyotishi/features/home_astrologer/screens/home_screen_astrologer.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';
import 'package:chat_jyotishi/features/payment/screens/broadcast_page.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/profile/screens/change_password_screen.dart';
import 'package:chat_jyotishi/features/profile/screens/set_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'features/auth/screens/login_screen.dart';

import 'features/auth/screens/splash_screen.dart';
import 'features/profile/screens/user_profile_screen.dart';

/// Global navigator key for navigation from notification service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Setup background message handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationService().initialize();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      routes: {
        '/splash_screen': (context) => SplashScreen(),
        '/login_screen': (context) => LoginScreen(),
        '/login_screen_astrologer': (context) => LoginScreenAstrologer(),
        '/home_screen_client': (context) => HomeScreenClient(),
        '/home_screen_astrologer': (context) => HomeScreenAstrologer(),
        '/user_profile_screen': (context) => UserProfileScreen(),
        '/horoscope_screen': (context) => HoroscopeScreen(),
        // '/chat_screen': (context) => ChatScreen(),
        '/set_password_screen': (context) => SetPasswordScreen(),
        '/change_password_screen': (context) => ChangePasswordScreen(),
        '/chat_list_screen': (context) => ChatListScreen(),
        '/astrologer_chat_list_screen': (context) => AstrologerChatListScreen(),
        // Astrologer incoming requests and broadcasts
        '/incoming_requests': (context) => IncomingRequestsScreen(),
        '/broadcast_messages': (context) => BroadcastMessagesScreen(),
        // Payment and broadcast routes
        '/payment_page': (context) => PaymentPage(),
        '/chat_options_page': (context) => ChatOptionsPage(),
        '/broadcast_page': (context) => BroadcastPage(),
      },
      initialRoute: '/splash_screen',
    );
  }
}
