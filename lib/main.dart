import 'package:chat_jyotishi/features/appointment/screens/appointment_screen.dart';
import 'package:chat_jyotishi/features/auth/screens/login_screen_astrologer.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_list_screen.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/chat_list_screen_astrologer.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/incoming_requests_screen.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/broadcast_messages_screen.dart';
import 'package:chat_jyotishi/features/history_client/screens/history_screen_client.dart';
import 'package:chat_jyotishi/features/home/screens/about_us_screen.dart';
import 'package:chat_jyotishi/features/home/screens/book_pandit_screen.dart';
import 'package:chat_jyotishi/features/home/screens/book_vaastu_sastri.dart';
import 'package:chat_jyotishi/features/home/screens/help_support_screen.dart';
import 'package:chat_jyotishi/features/home/screens/home_screen_client.dart'
    show HomeScreenClient;
import 'package:chat_jyotishi/features/home/screens/horroscope_screen.dart';
import 'package:chat_jyotishi/features/home/screens/privacy_policy_screen.dart';
import 'package:chat_jyotishi/features/home_astrologer/screens/home_screen_astrologer.dart';
import 'package:chat_jyotishi/features/notification/screens/notification_screen.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';
import 'package:chat_jyotishi/features/payment/screens/broadcast_page.dart';
import 'package:chat_jyotishi/features/payment/screens/chat_options_page.dart';
import 'package:chat_jyotishi/features/payment/screens/payment_page.dart';
import 'package:chat_jyotishi/features/setting/screens/change_password_screen.dart';
import 'package:chat_jyotishi/features/setting/screens/set_password_screen.dart';
import 'package:chat_jyotishi/features/setting/screens/settings_screen.dart';
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
        // '/splash_screen': (context) => SplashScreen(),
        // '/login_screen': (context) => LoginScreen(),
        // '/login_screen_astrologer': (context) => LoginScreenAstrologer(),
        // '/home_screen_client': (context) => HomeScreenClient(),
        // '/home_screen_astrologer': (context) => HomeScreenAstrologer(),
        // '/user_profile_screen': (context) => UserProfileScreen(),
        // '/horoscope_screen': (context) => HoroscopeScreen(),
        // // '/chat_screen': (context) => ChatScreen(),
        // '/set_password_screen': (context) => SetPasswordScreen(),
        // '/change_password_screen': (context) => ChangePasswordScreen(),
        // '/chat_list_screen': (context) => ChatListScreen(),
        // '/astrologer_chat_list_screen': (context) => AstrologerChatListScreen(),
        // // Astrologer incoming requests and broadcasts
        // '/incoming_requests': (context) => IncomingRequestsScreen(),
        // '/broadcast_messages': (context) => BroadcastMessagesScreen(),
        // // Payment and broadcast routes
        // '/payment_page': (context) => PaymentPage(),
        // '/chat_options_page': (context) => ChatOptionsPage(),
        // '/broadcast_page': (context) => BroadcastPage(),
        '/splash_screen': (context) => SplashScreen(),
        '/login_screen': (context) => LoginScreen(),
        '/login_screen_astrologer': (context) => LoginScreenAstrologer(),
        '/home_screen_client': (context) => HomeScreenClient(),
        '/history_screen_client': (context) => HistoryScreenClient(),
        '/book_pandit_screen': (context) => BookPanditScreen(),
        '/book_vaastu_sastri_screen': (context) => BookVaastuSastriScreen(),
        '/settings_screen': (context) => SettingsScreen(),
        '/help_support_screen': (context) => HelpSupportScreen(),
        '/about_us_screen': (context) => AboutUsScreen(),
        '/privacy_policy_screen': (context) => PrivacyPolicyScreen(),
        '/home_screen_astrologer': (context) => HomeScreenAstrologer(),
        '/user_profile_screen': (context) => UserProfileScreen(),
        // '/astrologer_profile_screen': (context) => AstrologerProfileScreen(),
        '/horoscope_screen': (context) => HoroscopeScreen(),
        // '/chat_screen': (context) => ChatScreen(),
        '/set_password_screen': (context) => SetPasswordScreen(),
        '/change_password_screen': (context) => ChangePasswordScreen(),
        '/chat_list_screen': (context) => ChatListScreen(),
        '/astrologer_chat_list_screen': (context) => AstrologerChatListScreen(),

        /// Astrologer incoming requests
        '/incoming_requests': (context) => IncomingRequestsScreen(),

        ///Payment and broadcast routes
        '/payment_page': (context) => PaymentPage(),
        '/chat_options_page': (context) => ChatOptionsPage(),
        '/broadcast_page': (context) => BroadcastPage(),

        ///Appointment feature
        '/appointment_screen': (context) => AppointmentScreen(),

        ///Notification service route
        '/notification_screen': (context) => NotificationScreen(),
      },
      initialRoute: '/home_screen_client',
    );
  }
}
