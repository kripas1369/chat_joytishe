import 'dart:convert';
import 'dart:io';

import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.messageId}');
}

/// Notification Service - Singleton
/// Handles Firebase Cloud Messaging and local notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Set only after Firebase is initialized (in initialize())
  FirebaseMessaging? _fcm;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  // Callback for handling notification taps
  Function(Map<String, dynamic>)? onNotificationTap;

  // Android notification channel for broadcast requests
  static const AndroidNotificationChannel _broadcastChannel =
      AndroidNotificationChannel(
    'broadcast_channel',
    'Broadcast Requests',
    description: 'Notifications for incoming broadcast chat requests',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Android notification channel for instant chat requests
  static const AndroidNotificationChannel _instantChatChannel =
      AndroidNotificationChannel(
    'instant_chat_channel',
    'Chat Requests',
    description: 'Notifications for incoming instant chat requests',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // Android notification channel for chat messages
  static const AndroidNotificationChannel _chatMessageChannel =
      AndroidNotificationChannel(
    'chat_message_channel',
    'Chat Messages',
    description: 'Notifications for new chat messages',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize notification service (only when Firebase is already initialized)
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Use Firebase only if it has been initialized (e.g. by main())
      if (Firebase.apps.isEmpty) {
        debugPrint('NotificationService: Firebase not initialized, skipping FCM');
        return;
      }
      _fcm = FirebaseMessaging.instance;

      // Request permission
      await _requestPermission();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Setup Firebase message handlers
      _setupFirebaseMessaging();

      _isInitialized = true;
      debugPrint('NotificationService initialized');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    if (_fcm == null) return;
    final settings = await _fcm!.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: true,
      carPlay: false,
      criticalAlert: false,
    );

    debugPrint('Notification permission: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    // Android settings
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS settings
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      final androidPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(_broadcastChannel);
      await androidPlugin?.createNotificationChannel(_instantChatChannel);
      await androidPlugin?.createNotificationChannel(_chatMessageChannel);
    }
  }

  /// Handle notification tap
  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');

    if (response.payload != null && onNotificationTap != null) {
      try {
        final data = jsonDecode(response.payload!);
        onNotificationTap!(Map<String, dynamic>.from(data));
      } catch (e) {
        debugPrint('Error parsing notification payload: $e');
      }
    }
  }

  /// Setup Firebase Cloud Messaging handlers
  void _setupFirebaseMessaging() {
    if (_fcm == null) return;
    final fcm = _fcm!;
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Background notification tapped: ${message.notification?.title}');
      _handleMessageOpen(message);
    });

    // Handle initial notification (app opened from terminated state)
    fcm.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('Initial message: ${message.notification?.title}');
        _handleMessageOpen(message);
      }
    });

    // Listen for token refresh
    fcm.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token refreshed: $newToken');
      _registerTokenWithBackend(newToken);
    });
  }

  /// Register FCM token with backend server
  /// Call this after user login to associate token with user
  Future<bool> registerFcmToken() async {
    try {
      final token = await getToken();
      if (token == null) {
        debugPrint('FCM token is null, cannot register');
        return false;
      }
      return await _registerTokenWithBackend(token);
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
      return false;
    }
  }

  /// Internal method to register token with backend
  Future<bool> _registerTokenWithBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null) {
        debugPrint('No access token, skipping FCM registration');
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.registerFcmToken}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
        body: jsonEncode({
          'fcmToken': token,
          'deviceType': Platform.isIOS ? 'ios' : 'android',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM token registered with backend successfully');
        // Save token locally to check for changes
        await prefs.setString('fcmToken', token);
        return true;
      } else {
        debugPrint('Failed to register FCM token: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error registering FCM token with backend: $e');
      return false;
    }
  }

  /// Remove FCM token from backend (call on logout)
  Future<bool> removeFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');
      final fcmToken = prefs.getString('fcmToken');

      if (accessToken == null || fcmToken == null) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.removeFcmToken}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
        body: jsonEncode({'fcmToken': fcmToken}),
      );

      if (response.statusCode == 200) {
        await prefs.remove('fcmToken');
        debugPrint('FCM token removed from backend');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
      return false;
    }
  }

  /// Handle message open
  void _handleMessageOpen(RemoteMessage message) {
    final data = message.data;
    if (onNotificationTap != null) {
      onNotificationTap!(Map<String, dynamic>.from(data));
    }
  }

  /// Get FCM token
  Future<String?> getToken() async {
    if (_fcm == null) return null;
    try {
      final token = await _fcm!.getToken();
      debugPrint('FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
      return null;
    }
  }

  /// Subscribe to topic (e.g., astrologer-specific notifications)
  Future<void> subscribeToTopic(String topic) async {
    if (_fcm == null) return;
    try {
      await _fcm!.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_fcm == null) return;
    try {
      await _fcm!.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Show local notification from Firebase message
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final data = message.data;
    final type = data['type'] ?? 'chat';
    final isBroadcast = type == 'broadcast';

    final androidDetails = AndroidNotificationDetails(
      isBroadcast ? _broadcastChannel.id : _instantChatChannel.id,
      isBroadcast ? _broadcastChannel.name : _instantChatChannel.name,
      channelDescription: isBroadcast
          ? _broadcastChannel.description
          : _instantChatChannel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: isBroadcast ? const Color(0xFFFF9800) : const Color(0xFF2196F3),
      category: AndroidNotificationCategory.message,
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'accept',
          'Accept',
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'reject',
          'Reject',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(data),
    );
  }

  /// Show broadcast request notification (called from socket)
  Future<void> showBroadcastNotification({
    required String messageId,
    required String clientName,
    required String message,
    String? clientId,
    String? clientPhoto,
  }) async {
    final payload = {
      'type': 'broadcast',
      'messageId': messageId,
      'clientId': clientId ?? '',
      'clientName': clientName,
      'clientPhoto': clientPhoto,
      'message': message,
    };

    const androidDetails = AndroidNotificationDetails(
      'broadcast_channel',
      'Broadcast Requests',
      channelDescription: 'Notifications for incoming broadcast chat requests',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF9800),
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'Reject',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      messageId.hashCode,
      'New Broadcast Request',
      '$clientName: $message',
      details,
      payload: jsonEncode(payload),
    );

    debugPrint('Broadcast notification shown for: $clientName');
  }

  /// Show instant chat request notification (called from socket)
  Future<void> showInstantChatNotification({
    required String requestId,
    required String clientName,
    required String message,
    String? clientId,
    String? clientPhoto,
  }) async {
    final payload = {
      'type': 'instant',
      'requestId': requestId,
      'clientId': clientId ?? '',
      'clientName': clientName,
      'clientPhoto': clientPhoto,
      'message': message,
    };

    const androidDetails = AndroidNotificationDetails(
      'instant_chat_channel',
      'Chat Requests',
      channelDescription: 'Notifications for incoming instant chat requests',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2196F3),
      category: AndroidNotificationCategory.message,
      fullScreenIntent: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'accept',
          'Accept',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'reject',
          'Reject',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      requestId.hashCode,
      'New Chat Request',
      '$clientName: $message',
      details,
      payload: jsonEncode(payload),
    );

    debugPrint('Instant chat notification shown for: $clientName');
  }

  /// Show chat message notification (called from socket on new message)
  Future<void> showChatMessageNotification({
    required String messageId,
    required String senderName,
    required String message,
    String? senderId,
    String? chatId,
    String? senderPhoto,
  }) async {
    final payload = {
      'type': 'chat_message',
      'messageId': messageId,
      'senderId': senderId ?? '',
      'chatId': chatId ?? '',
      'senderName': senderName,
      'senderPhoto': senderPhoto,
      'message': message,
    };

    const androidDetails = AndroidNotificationDetails(
      'chat_message_channel',
      'Chat Messages',
      channelDescription: 'Notifications for new chat messages',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF4CAF50),
      category: AndroidNotificationCategory.message,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      messageId.hashCode,
      senderName,
      message,
      details,
      payload: jsonEncode(payload),
    );

    debugPrint('Chat message notification shown from: $senderName');
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }
}
