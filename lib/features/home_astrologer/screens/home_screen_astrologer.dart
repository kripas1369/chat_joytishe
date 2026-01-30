import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/auth/screens/login_screen_astrologer.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/astrologer_chat_screen.dart';
import 'package:chat_jyotishi/features/chat_astrologer/screens/incoming_requests_screen.dart';
import 'package:chat_jyotishi/features/home/widgets/drawer_item.dart';
import 'package:chat_jyotishi/features/home/widgets/notification_button.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';
import 'package:chat_jyotishi/features/chat_astrologer/service/astrologer_chat_service.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';

class HomeScreenAstrologer extends StatefulWidget {
  const HomeScreenAstrologer({super.key});

  @override
  State<HomeScreenAstrologer> createState() => _HomeScreenAstrologerState();
}

class _HomeScreenAstrologerState extends State<HomeScreenAstrologer>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SocketService _socketService = SocketService();
  final NotificationService _notificationService = NotificationService();
  final AstrologerChatService _astrologerChatService = AstrologerChatService();

  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late AnimationController _gradientShiftController;
  late AnimationController _floatController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _gradientShiftAnimation;
  late Animation<double> _floatAnimation;

  // Scroll controller for app bar opacity
  final ScrollController _scrollController = ScrollController();
  double _appBarOpacity = 0.0;

  bool isOnline = false;
  bool _isTogglingStatus = false;
  String astrologerId = '';
  String accessToken = '';
  String refreshToken = '';

  // Broadcast notification state
  List<Map<String, dynamic>> _broadcastNotifications = [];

  // Count of pending broadcast requests for badge
  int _pendingBroadcastCount = 0;

  // Track shown instant chat request IDs to prevent duplicate dialogs
  final Set<String> _shownInstantChatRequestIds = {};
  bool _isInstantChatDialogShowing = false;

  // Track chat IDs that have already shown accept/reject dialog (for one-to-one chats)
  final Set<String> _shownChatDialogIds = {};

  // Real-time chat/notification badge count (from `notification:new`)
  int _realtimeNotificationCount = 0;

  // Keep references so we can remove only our own socket handlers in dispose()
  dynamic _onNotificationNewHandler;
  dynamic _onChatReceiveHandler;

  bool _isChatMessageDialogShowing = false;

  final String astrologerName = 'Dr. Sharma';
  final String specialization = 'Vedic Astrology';
  final double rating = 4.8;
  final int totalConsultations = 1247;
  final String todayEarnings = 'NRs 8000';
  final String monthlyEarnings = 'NRs 87,340';
  final int pendingRequests = 5;
  final int todayConsultations = 12;

  @override
  void initState() {
    super.initState();
    _loadAuthData();
    _initAnimations();
    // Note: _setupBroadcastListener is called in _loadAuthData after socket connects
    _setupNotificationHandler();
    _initializeAstrologerChatService();
  }

  Future<void> _initializeAstrologerChatService() async {
    try {
      await _astrologerChatService.initialize();
    } catch (e) {
      debugPrint('Error initializing AstrologerChatService: $e');
    }
  }

  Future<void> _showChatMessageDialog({
    required String notificationId,
    required String chatId,
    required String clientId,
  }) async {
    if (!mounted) return;
    if (_isChatMessageDialogShowing) return;
    _isChatMessageDialogShowing = true;

    try {
      // Fetch client details for nicer UI (name/photo)
      String clientName = 'Client';
      String? clientPhoto;
      try {
        await _astrologerChatService.initialize();
        final profile = await _astrologerChatService.getClientProfile(clientId);
        clientName = profile.name ?? 'Client';
        clientPhoto = profile.profilePhoto;
      } catch (e) {
        debugPrint('Failed to fetch client profile for dialog: $e');
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.cardDark, AppColors.backgroundDark],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'New Message',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.cardMedium,
                        backgroundImage: clientPhoto != null
                            ? NetworkImage(
                                '${ApiEndpoints.socketUrl}$clientPhoto',
                              )
                            : null,
                        child: clientPhoto == null
                            ? const Icon(
                                Icons.person_rounded,
                                color: Colors.white70,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.10)),
                    ),
                    child: const Text(
                      'Do you want to open this chat now?',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Reject: mark notification read + close
                            _socketService.markNotificationAsRead(
                              notificationId,
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Reject',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            // Accept: mark read + navigate to chat
                            _socketService.markNotificationAsRead(
                              notificationId,
                            );
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AstrologerChatScreen(
                                  chatId: chatId,
                                  clientId: clientId,
                                  clientName: clientName,
                                  clientPhoto: clientPhoto,
                                  astrologerId: astrologerId,
                                  accessToken: accessToken,
                                  refreshToken: refreshToken,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.green.shade700],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Accept',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      _isChatMessageDialogShowing = false;
    }
  }

  void _setupRealtimeNotificationListeners() {
    // Avoid registering multiple handlers if this gets called again
    _removeRealtimeNotificationListeners();

    // Check if socket is connected
    if (_socketService.socket == null || !_socketService.connected) {
      debugPrint(
        '⚠️ Cannot setup notification listeners: socket not connected',
      );
      return;
    }

    debugPrint('✅ Setting up real-time notification listeners...');

    // Listen for new notifications (includes chat message notifications)
    // Backend sends `count` field which is the authoritative notification count
    _onNotificationNewHandler = (data) {
      if (!mounted) {
        debugPrint('⚠️ notification:new handler called but widget not mounted');
        return;
      }

      final map = Map<String, dynamic>.from(data ?? {});

      // Backend payload includes `count` (see your logs: count: 7)
      // This is the total unread notification count, use it directly
      final incomingCount = map['count'];
      final notificationType = map['type'];
      final notificationMessage = map['message']?.toString();

      debugPrint(
        '📨 notification:new received - count: $incomingCount, type: $notificationType',
      );
      debugPrint(
        '📊 Current badge count before update: ${_pendingBroadcastCount + _realtimeNotificationCount}',
      );

      // Update state
      setState(() {
        final oldCount = _realtimeNotificationCount;

        if (incomingCount is int && incomingCount >= 0) {
          // Use backend's authoritative count
          _realtimeNotificationCount = incomingCount;
        } else if (incomingCount is String) {
          final parsed = int.tryParse(incomingCount);
          if (parsed != null && parsed >= 0) {
            _realtimeNotificationCount = parsed;
          } else {
            // Fallback: increment if count is invalid
            _realtimeNotificationCount = _realtimeNotificationCount + 1;
          }
        } else {
          // Fallback: increment if no count provided
          _realtimeNotificationCount = _realtimeNotificationCount + 1;
        }

        debugPrint(
          '📊 Updated badge count: ${_pendingBroadcastCount + _realtimeNotificationCount} (was: ${_pendingBroadcastCount + oldCount})',
        );
      });

      // Make it visible on the homepage immediately (not just a badge).
      // This helps confirm real-time updates even if the badge is hard to notice.
      if (notificationType == 'CHAT_MESSAGE') {
        final metadata = map['metadata'];
        final metaMap = metadata is Map
            ? Map<String, dynamic>.from(metadata)
            : <String, dynamic>{};
        final chatId = metaMap['chatId']?.toString();
        final senderId = metaMap['senderId']?.toString();
        final notifId = map['id']?.toString();

        // Only show accept/reject dialog for the FIRST message from this chat
        // Check if we've already shown the dialog for this chatId
        final bool isFirstTimeForThisChat = chatId != null &&
            !_shownChatDialogIds.contains(chatId);

        debugPrint('📋 Chat notification - chatId: $chatId, isFirstTime: $isFirstTimeForThisChat');

        if (isFirstTimeForThisChat &&
            notifId != null &&
            senderId != null) {
          // First message from this chat - show accept/reject dialog
          _shownChatDialogIds.add(chatId);
          debugPrint('✅ Added chatId to shown dialogs: $chatId');
          _showChatMessageDialog(
            notificationId: notifId,
            chatId: chatId,
            clientId: senderId,
          );
        } else {
          // Ongoing conversation or missing metadata - show snackbar
          final text = notificationMessage?.isNotEmpty == true
              ? notificationMessage!
              : 'New message received';
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(text),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushReplacementNamed('/astrologer_chat_list_screen');
                },
              ),
            ),
          );
        }
      }
    };

    _socketService.socket!.on('notification:new', _onNotificationNewHandler);
    debugPrint('✅ notification:new listener registered');

    // Note: We don't listen to chat:receive here because notification:new
    // already fires when a chat message arrives, and it includes the count.
    // Listening to both would cause double-counting.
    // If you need chat:receive for other purposes, handle it separately.
  }

  void _removeRealtimeNotificationListeners() {
    if (_onNotificationNewHandler != null) {
      _socketService.socket?.off('notification:new', _onNotificationNewHandler);
      _onNotificationNewHandler = null;
    }
    // Note: _onChatReceiveHandler is no longer used, but keeping cleanup for safety
    if (_onChatReceiveHandler != null) {
      _socketService.socket?.off('chat:receive', _onChatReceiveHandler);
      _onChatReceiveHandler = null;
    }
  }

  /// Setup notification tap handler for handling taps on push notifications
  void _setupNotificationHandler() {
    _notificationService.onNotificationTap = (data) {
      debugPrint('Notification tapped with data: $data');
      final type = data['type'];

      if (type == 'broadcast') {
        // Handle broadcast notification tap
        final messageId = data['messageId'] ?? '';
        final clientId = data['clientId'] ?? '';
        final clientName = data['clientName'] ?? 'Client';
        final clientPhoto = data['clientPhoto'];
        final message = data['message'] ?? '';

        // Show dialog to accept/reject
        _showBroadcastDialog({
          'messageId': messageId,
          'clientId': clientId,
          'clientName': clientName,
          'clientPhoto': clientPhoto,
          'content': message,
        });
      } else if (type == 'instant') {
        // Handle instant chat notification tap - navigate to incoming requests
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncomingRequestsScreen()),
        );
      }
    };
  }

  void _setupBroadcastListener() {
    // Listen for new broadcast messages from clients
    _socketService.socket?.on('broadcast:newMessage', (data) {
      debugPrint('New broadcast received: $data');
      if (mounted) {
        final mapData = Map<String, dynamic>.from(data);
        // Parse the message structure from backend
        final message = mapData['message'] ?? mapData;
        final client = message['client'] ?? mapData['client'] ?? {};

        final broadcastData = {
          'messageId': message['id'] ?? mapData['id'] ?? '',
          'content': message['content'] ?? mapData['content'] ?? '',
          'type': message['type'] ?? 'TEXT',
          'clientId': client['id'] ?? message['clientId'] ?? '',
          'clientName': client['name'] ?? 'Client',
          'clientPhoto': client['profilePhoto'],
          'expiresAt': message['expiresAt'],
        };

        setState(() {
          _broadcastNotifications.add(broadcastData);
          _pendingBroadcastCount = _broadcastNotifications.length;
        });
        _showBroadcastDialog(broadcastData);
      }
    });

    // Listen for new instant chat requests
    _socketService.socket?.on('instantChat:newRequest', (data) {
      debugPrint('New instant chat request: $data');
      if (mounted) {
        setState(() {
          _pendingBroadcastCount++;
        });
        // Show dialog for instant requests too
        _showInstantChatDialog(Map<String, dynamic>.from(data));
      }
    });

    // Listen for instant chat accepted confirmation (to navigate to chat)
    _socketService.socket?.on('instantChat:accepted', (data) {
      debugPrint('Instant chat accepted: $data');
      if (mounted) {
        final chat = data['chat'];
        final client = data['client'];
        if (chat != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AstrologerChatScreen(
                chatId: chat['id'] ?? '',
                clientId: client?['id'] ?? '',
                clientName: client?['name'] ?? 'Client',
                clientPhoto: client?['profilePhoto'],
                astrologerId: astrologerId,
                accessToken: accessToken,
                refreshToken: refreshToken,
              ),
            ),
          );
        }
      }
    });
  }

  /// Show dialog for instant chat requests
  void _showInstantChatDialog(Map<String, dynamic> request) {
    final requestData = request['request'] ?? request;
    final client = requestData['client'] ?? request['client'];
    final clientName = client?['name'] ?? requestData['clientName'] ?? 'Client';
    final message = requestData['message'] ?? request['message'] ?? '';
    final requestId = requestData['id'] ?? request['id'] ?? '';

    // Prevent showing duplicate dialogs for the same request
    if (requestId.isEmpty || _shownInstantChatRequestIds.contains(requestId)) {
      debugPrint(
        'Skipping duplicate instant chat dialog for request: $requestId',
      );
      return;
    }

    // Mark this request as shown
    _shownInstantChatRequestIds.add(requestId);
    _isInstantChatDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InstantChatNotificationDialog(
        request: {
          'id': requestId,
          'clientName': clientName,
          'clientPhoto': client?['profilePhoto'],
          'clientId': client?['id'] ?? requestData['clientId'] ?? '',
          'message': message,
        },
        onAccept: () {
          _isInstantChatDialogShowing = false;
          _handleAcceptInstantChat(requestId, client, clientName, message);
        },
        onReject: () {
          _isInstantChatDialogShowing = false;
          _handleRejectInstantChat(requestId);
        },
      ),
    );
  }

  void _handleAcceptInstantChat(
    String requestId,
    dynamic client,
    String clientName,
    String initialMessage,
  ) async {
    Navigator.pop(context); // Close dialog

    setState(() {
      _pendingBroadcastCount--;
    });

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Accepting chat request...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Accept via HTTP API: POST /instant-chat/accept/:requestId
      final response = await http.post(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.instantChatAccept}/$requestId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint(
        'Accept instant chat response: ${response.statusCode} - ${response.body}',
      );

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Response: { "message": "Request accepted", "chat": { "id": "...", ... } }
        final chat = data['chat'];
        final chatId = chat?['id'] ?? requestId;
        final clientId = client?['id'] ?? chat?['clientId'] ?? '';
        final clientPhoto =
            client?['profilePhoto'] ?? chat?['client']?['profilePhoto'];

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Chat request accepted!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to chat
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AstrologerChatScreen(
                chatId: chatId,
                clientId: clientId,
                clientName: clientName,
                clientPhoto: clientPhoto,
                astrologerId: astrologerId,
                accessToken: accessToken,
                refreshToken: refreshToken,
                initialMessage: initialMessage,
              ),
            ),
          );
        }
      } else {
        final errorData = jsonDecode(response.body);
        // Handle both error formats: {"error":{"message":"..."}} and {"message":"..."}
        final errorMessage =
            errorData['error']?['message'] ??
            errorData['message'] ??
            'Failed to accept request';

        // Show error dialog for better UX
        if (mounted) {
          _showAcceptErrorDialog(
            title: 'Cannot Accept Request',
            message: errorMessage,
            isAppointmentRequired:
                errorMessage.toLowerCase().contains('appointment') ||
                errorMessage.toLowerCase().contains('professional'),
          );
        }
      }
    } catch (e) {
      debugPrint('Error accepting instant chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showAcceptErrorDialog(
          title: 'Connection Error',
          message:
              'Unable to connect to the server. Please check your internet connection and try again.',
          isAppointmentRequired: false,
        );
      }
    }
  }

  /// Show error dialog when accepting a chat request fails
  void _showAcceptErrorDialog({
    required String title,
    required String message,
    required bool isAppointmentRequired,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cardDark, AppColors.backgroundDark],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withAlpha(100), width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Error icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isAppointmentRequired
                      ? Icons.calendar_today_rounded
                      : Icons.error_outline_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              // Additional info for appointment-required errors
              if (isAppointmentRequired) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'As a Professional astrologer, clients need to book appointments to chat with you.',
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleRejectInstantChat(String requestId) {
    Navigator.pop(context); // Close dialog

    setState(() {
      _pendingBroadcastCount--;
    });

    // Note: The API doesn't have a reject endpoint for instant chats
    // Just dismiss locally - the request will expire on server
    debugPrint('Instant chat request dismissed: $requestId');
  }

  Future<void> _connectSocket() async {
    if (accessToken.isNotEmpty && refreshToken.isNotEmpty) {
      if (!_socketService.connected) {
        // Enable local notifications for incoming requests
        _socketService.enableLocalNotifications = true;

        // Set up a one-time listener for when socket connects
        // This ensures listeners are set up AFTER connection is established
        bool listenerSetup = false;
        _socketService.socket?.once('connect', (_) {
          if (!listenerSetup && mounted) {
            listenerSetup = true;
            debugPrint(
              '✅ Socket connected event received, setting up notification listeners...',
            );
            _setupRealtimeNotificationListeners();
            _fetchUnreadNotificationCount();
          }
        });

        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        // Subscribe to astrologer-specific notifications topic
        if (astrologerId.isNotEmpty) {
          await _notificationService.subscribeToTopic(
            'astrologer_$astrologerId',
          );
        }

        // If socket connected synchronously (already connected), set up listeners now
        // Otherwise, the 'connect' event handler above will do it
        await Future.delayed(const Duration(milliseconds: 300));
        if (_socketService.connected && !listenerSetup && mounted) {
          listenerSetup = true;
          debugPrint(
            '✅ Socket connected (checked), setting up notification listeners...',
          );
          _setupRealtimeNotificationListeners();
          await _fetchUnreadNotificationCount();
        }
      } else {
        // Socket already connected, set up listeners immediately
        debugPrint(
          '✅ Socket already connected, setting up notification listeners...',
        );
        _setupRealtimeNotificationListeners();
        await _fetchUnreadNotificationCount();
      }
    }
  }

  /// Fetch initial unread notification count from API
  Future<void> _fetchUnreadNotificationCount() async {
    if (accessToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.notificationUnreadCount}',
        ),
        headers: {
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint(
        'Fetch unread count response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response format: { "success": true, "data": { "count": 7 } }
        final count = data['data']?['count'] ?? data['count'] ?? 0;

        if (mounted) {
          setState(() {
            _realtimeNotificationCount = count is int
                ? count
                : (int.tryParse(count.toString()) ?? 0);
            debugPrint(
              '📊 Initial unread count fetched: $_realtimeNotificationCount',
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  /// Toggle astrologer online/offline status via API
  Future<void> _toggleOnlineStatus(bool newStatus) async {
    if (_isTogglingStatus) return;

    // Check if we have valid tokens
    if (accessToken.isEmpty) {
      debugPrint('⚠️ Toggle online status failed: accessToken is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please login again to update your status'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isTogglingStatus = true);

    debugPrint('🔄 Toggling online status to: $newStatus');
    debugPrint('📍 API URL: ${ApiEndpoints.baseUrl}/astrologer/toggle-online');
    debugPrint('🔑 Access token present: ${accessToken.isNotEmpty}');

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/astrologer/toggle-online'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
        body: jsonEncode({'isOnline': newStatus}),
      );

      debugPrint(
        'Toggle online status response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Save status locally for persistence across navigation
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('astrologerOnlineStatus', newStatus);

        setState(() {
          isOnline = newStatus;
        });

        // If going online, connect socket, setup listeners and fetch pending requests
        if (newStatus) {
          await _connectSocket();
          _setupBroadcastListener();
          // _setupRealtimeNotificationListeners() is called inside _connectSocket()
          await _fetchPendingBroadcasts();
          await _fetchPendingInstantChats();
        } else {
          // If going offline, clear notifications and disconnect socket
          setState(() {
            _broadcastNotifications.clear();
            _pendingBroadcastCount = 0;
            _realtimeNotificationCount =
                0; // Reset real-time count when going offline
          });
          // Clear shown request IDs when going offline
          _shownInstantChatRequestIds.clear();
          _shownChatDialogIds.clear();
          // Remove listeners when going offline
          _removeRealtimeNotificationListeners();
          // Disable local notifications when offline
          _socketService.enableLocalNotifications = false;
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                newStatus ? 'You are now online' : 'You are now offline',
              ),
              backgroundColor: newStatus ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // API error
        debugPrint('❌ Toggle online status failed with status: ${response.statusCode}');

        String errorMessage = 'Failed to update status';

        // Handle specific status codes
        if (response.statusCode == 401) {
          errorMessage = 'Session expired. Please login again.';
          debugPrint('⚠️ Token expired or invalid. Need to re-login.');
        } else {
          // Try to parse error message from response
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody['message'] ??
                          errorBody['error']?['message'] ??
                          'Failed to update status (${response.statusCode})';
          } catch (parseError) {
            errorMessage = 'Failed to update status (${response.statusCode})';
            debugPrint('Error parsing response body: $parseError');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglingStatus = false);
      }
    }
  }

  void _showBroadcastDialog(Map<String, dynamic> broadcast) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _BroadcastNotificationDialog(
        broadcast: broadcast,
        onAccept: () => _handleAcceptBroadcast(broadcast),
        onReject: () => _handleRejectBroadcast(broadcast),
      ),
    );
  }

  void _handleAcceptBroadcast(Map<String, dynamic> broadcast) async {
    // Close dialog if showing
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    final messageId = broadcast['messageId'] ?? '';
    final clientId = broadcast['clientId'] ?? '';
    final clientName = broadcast['clientName'] ?? 'Client';
    final clientPhoto = broadcast['clientPhoto'];
    final initialMessage = broadcast['content'] ?? '';

    debugPrint('Accepting broadcast: messageId=$messageId, clientId=$clientId');

    // Remove from local notifications immediately
    setState(() {
      _broadcastNotifications.removeWhere((b) => b['messageId'] == messageId);
      _pendingBroadcastCount = _broadcastNotifications.length;
    });

    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Accepting broadcast...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Accept the broadcast via HTTP API: POST /broadcast-messages/:messageId/accept
      final response = await http.post(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.broadcastMessagesAccept}/$messageId/accept',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint(
        'Accept broadcast response: ${response.statusCode} - ${response.body}',
      );

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Response: { "message": "Broadcast accepted", "chat": { "id": "...", ... } }
        final chat = data['chat'];
        final chatId = chat?['id'] ?? messageId;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Broadcast accepted! Starting chat...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        // Navigate to chat with the actual chat ID from response
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AstrologerChatScreen(
                chatId: chatId,
                clientId: clientId,
                clientName: clientName,
                clientPhoto: clientPhoto,
                astrologerId: astrologerId,
                accessToken: accessToken,
                refreshToken: refreshToken,
                initialMessage: initialMessage,
              ),
            ),
          );
        }
      } else {
        // API error
        final errorData = jsonDecode(response.body);
        // Handle both error formats: {"error":{"message":"..."}} and {"message":"..."}
        final errorMessage =
            errorData['error']?['message'] ??
            errorData['message'] ??
            'Failed to accept broadcast';

        // Show error dialog for better UX
        if (mounted) {
          _showAcceptErrorDialog(
            title: 'Cannot Accept Broadcast',
            message: errorMessage,
            isAppointmentRequired:
                errorMessage.toLowerCase().contains('appointment') ||
                errorMessage.toLowerCase().contains('professional'),
          );
        }
      }
    } catch (e) {
      debugPrint('Error accepting broadcast: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showAcceptErrorDialog(
          title: 'Connection Error',
          message:
              'Unable to connect to the server. Please check your internet connection and try again.',
          isAppointmentRequired: false,
        );
      }
    }
  }

  void _handleRejectBroadcast(Map<String, dynamic> broadcast) async {
    Navigator.pop(context); // Close dialog

    final messageId = broadcast['messageId'] ?? '';

    // Remove from local notifications
    setState(() {
      _broadcastNotifications.removeWhere((b) => b['messageId'] == messageId);
      _pendingBroadcastCount = _broadcastNotifications.length;
    });

    // Dismiss via HTTP API: POST /broadcast-messages/:messageId/dismiss
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.broadcastMessagesDismiss}/$messageId/dismiss',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint('Dismiss broadcast response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('Broadcast dismissed successfully');
      }
    } catch (e) {
      debugPrint('Error dismissing broadcast: $e');
    }
  }

  void _initAnimations() {
    // Fade in animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Pulse animation for glowing effects
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.2, end: 0.4).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Gradient shift animation
    _gradientShiftController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();
    _gradientShiftAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _gradientShiftController, curve: Curves.linear),
    );

    // Float animation for cards
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Scroll listener for app bar opacity
    _scrollController.addListener(_onScroll);

    _fadeController.forward();
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (offset / 100).clamp(0.0, 1.0);
    if (_appBarOpacity != newOpacity) {
      setState(() {
        _appBarOpacity = newOpacity;
      });
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    _removeRealtimeNotificationListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundDark,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _buildHeader(),
                          const SizedBox(height: 24),
                          _buildWelcomeSection(),
                          const SizedBox(height: 16),
                          _buildStatusCard(),
                          const SizedBox(height: 16),
                          _buildStatsGrid(),
                          const SizedBox(height: 24),
                          _buildPendingRequests(),
                          const SizedBox(height: 24),
                          _buildQuickActions(),
                          const SizedBox(height: 24),
                          _buildTodaySchedule(),
                          const SizedBox(height: 40),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Astrologer ID: $astrologerId',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Access Token: $accessToken',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Refresh Token: $refreshToken',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.backgroundDark,
      ),
    );
  }

  Widget _buildAppLogo() {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, AppColors.lightPurple],
          ).createShader(bounds),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Chat',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                TextSpan(
                  text: 'Jyotishi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Icon(
              Icons.auto_awesome,
              size: 16,
              color: AppColors.primaryPurple.withOpacity(_pulseAnimation.value),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final totalNotificationCount =
        _pendingBroadcastCount + _realtimeNotificationCount;

    // Debug: Log badge count on every rebuild
    debugPrint(
      '🔔 Building header with badge count: $totalNotificationCount (broadcast: $_pendingBroadcastCount, realtime: $_realtimeNotificationCount)',
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GlassIconButton(
              icon: Icons.menu_rounded,
              onTap: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            SizedBox(width: 16),
            _buildAppLogo(),
          ],
        ),
        NotificationButton(
          notificationCount: totalNotificationCount,
          onTap: () {
            // Navigate to incoming requests if there are pending broadcasts
            if (_pendingBroadcastCount > 0) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const IncomingRequestsScreen(),
                ),
              );
            } else {
              _navigateTo('/notifications');
            }
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryPurple.withOpacity(0.2),
            AppColors.deepPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildGreetingBadge(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isOnline
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.orange
                          ..withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            'Welcome, $astrologerName',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            isOnline
                ? 'You\'re guiding seekers today. Ready to share cosmic wisdom\nwith those seeking celestial guidance.'
                : 'Take time to recharge your spiritual energy.\nToggle online when ready to guide seekers.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreetingBadge() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;

    if (hour < 12) {
      greeting = 'Good Morning';
      icon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = Icons.wb_sunny_outlined;
    } else {
      greeting = 'Good Evening';
      icon = Icons.nightlight_rounded;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.lightPurple),
          SizedBox(width: 6),
          Text(
            greeting,
            style: TextStyle(
              color: AppColors.lightPurple,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isOnline
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
            isOnline
                ? Colors.green.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isOnline ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isOnline ? Colors.green : Colors.orange,
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        isOnline ? 'You\'re Online' : 'You\'re Offline',
                        style: TextStyle(
                          color: isOnline ? Colors.green : Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    isOnline
                        ? 'Available for consultations'
                        : 'Toggle to start receiving requests',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              _isTogglingStatus
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isOnline ? Colors.green : Colors.orange,
                      ),
                    )
                  : Switch(
                      value: isOnline,
                      onChanged: (value) => _toggleOnlineStatus(value),

                      inactiveThumbColor: Colors.orange,
                    ),
            ],
          ),
          if (isOnline && pendingRequests > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_active_rounded,
                    color: AppColors.primaryPurple,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have $pendingRequests new consultation requests',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: AppColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          icon: Icons.currency_rupee_rounded,
          title: 'Today\'s Earnings',
          value: todayEarnings,
          subtitle: 'from $todayConsultations consultations',
          color: Colors.green,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          title: 'Monthly Earnings',
          value: monthlyEarnings,
          subtitle: 'This month',
          color: AppColors.primaryPurple,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.star_rounded,
          title: 'Rating',
          value: rating.toString(),
          subtitle: 'from $totalConsultations reviews',
          color: Colors.amber,
          onTap: () {},
        ),
        _buildStatCard(
          icon: Icons.history_rounded,
          title: 'Chat History',
          value: 'View',
          subtitle: 'Previous conversations',
          color: AppColors.primaryPurple,
          onTap: () =>
              Navigator.of(context).pushNamed('/astrologer_chat_list_screen'),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests() {
    // Only show requests when online
    if (!isOnline) {
      return Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Go online to receive broadcast and chat requests from clients.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // Show broadcast notifications if any
    if (_broadcastNotifications.isEmpty) {
      return Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withAlpha(26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.withAlpha(51)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 24),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'You are online. Waiting for client requests...',
                style: TextStyle(color: Colors.green, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Broadcast Requests',
          '${_broadcastNotifications.length} pending',
        ),
        SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _broadcastNotifications.length,
          itemBuilder: (context, index) {
            final broadcast = _broadcastNotifications[index];
            return _buildBroadcastRequestCard(broadcast);
          },
        ),
      ],
    );
  }

  Widget _buildBroadcastRequestCard(Map<String, dynamic> broadcast) {
    final clientName = broadcast['clientName'] ?? 'Client';
    final content = broadcast['content'] ?? '';
    final clientPhoto = broadcast['clientPhoto'];

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withAlpha(51),
            Colors.deepOrange.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withAlpha(77), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Broadcast badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(51),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign_rounded, color: Colors.orange, size: 14),
                SizedBox(width: 4),
                Text(
                  'Broadcast',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.cardMedium,
                backgroundImage: clientPhoto != null
                    ? NetworkImage('${ApiEndpoints.socketUrl}$clientPhoto')
                    : null,
                child: clientPhoto == null
                    ? Icon(Icons.person_rounded, color: AppColors.textSecondary)
                    : null,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAcceptBroadcast(broadcast),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 18),
                      SizedBox(width: 6),
                      Text('Accept'),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleRejectBroadcast(broadcast),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withAlpha(51),
                    foregroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.red.withAlpha(102)),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.close, size: 18),
                      SizedBox(width: 6),
                      Text('Reject'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.account_balance_wallet_rounded,
        'label': 'Earnings',
        'route': '/earnings',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Schedule',
        'route': '/schedule',
      },
      {'icon': Icons.history_rounded, 'label': 'History', 'route': '/history'},
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Analytics',
        'route': '/analytics',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Quick Actions', 'Manage your services'),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionButton(
              icon: action['icon'] as IconData,
              label: action['label'] as String,
              onTap: () => _navigateTo(action['route'] as String),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primaryPurple, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          'Today\'s Schedule',
          '$todayConsultations consultations',
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08), width: 1),
          ),
          child: Column(
            children: [
              _buildScheduleItem(
                '10:00 AM',
                'Priya Sharma',
                'Birth Chart Analysis',
              ),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildScheduleItem(
                '11:30 AM',
                'Amit Patel',
                'Career Consultation',
              ),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildScheduleItem(
                '02:00 PM',
                'Neha Gupta',
                'Love & Relationship',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleItem(String time, String name, String type) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              time,
              style: TextStyle(
                color: AppColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.backgroundDark,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Divider(color: Colors.white.withOpacity(0.08)),
              Expanded(child: _buildDrawerItems()),
              Divider(color: Colors.white.withOpacity(0.08)),
              _buildDrawerLogout(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.cardMedium,
              child: Icon(
                Icons.person_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
          ),
          SizedBox(height: 16),
          Text(
            astrologerName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            specialization,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              Text(
                '$rating',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                ' ($totalConsultations reviews)',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItems() {
    final items = [
      {'icon': Icons.home_rounded, 'title': 'Home', 'selected': true},
      {
        'icon': Icons.chat_bubble_rounded,
        'title': 'Messages',
        'route': '/astrologer_chat_list_screen',
      },
      {'icon': Icons.person_rounded, 'title': 'Profile', 'route': '/profile'},
      {
        'icon': Icons.account_balance_wallet_rounded,
        'title': 'Earnings',
        'route': '/earnings',
      },
      {
        'icon': Icons.calendar_today_rounded,
        'title': 'Schedule',
        'route': '/schedule',
      },
      {
        'icon': Icons.history_rounded,
        'title': 'Consultation History',
        'route': '/history',
      },
      {
        'icon': Icons.bar_chart_rounded,
        'title': 'Analytics',
        'route': '/analytics',
      },
      {
        'icon': Icons.settings_rounded,
        'title': 'Settings',
        'route': '/settings',
      },
      {
        'icon': Icons.help_outline_rounded,
        'title': 'Help & Support',
        'route': '/support',
      },
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: items.map((item) {
        return DrawerItem(
          icon: item['icon'] as IconData,
          title: item['title'] as String,
          isSelected: item['selected'] as bool? ?? false,
          onTap: () {
            if (item['route'] != null) {
              _navigateTo(item['route'] as String);
            } else {
              Navigator.pop(context);
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildDrawerLogout() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: DrawerItem(
        icon: Icons.logout_rounded,
        title: 'Logout',
        isDestructive: true,
        onTap: _handleLogout,
      ),
    );
  }

  void _navigateTo(String route) {
    Navigator.of(context).pushNamed(route);
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved online status first (for immediate UI feedback)
    final savedOnlineStatus = prefs.getBool('astrologerOnlineStatus') ?? false;

    setState(() {
      astrologerId = prefs.getString('astrologerId') ?? '';
      accessToken = prefs.getString('astrologerAccessToken') ?? '';
      refreshToken = prefs.getString('astrologerRefreshToken') ?? '';
      isOnline = savedOnlineStatus; // Use saved status immediately
    });

    // If we have a saved online status, connect socket and setup listeners
    if (savedOnlineStatus && accessToken.isNotEmpty) {
      await _connectSocket();
      _setupBroadcastListener();
      await _fetchPendingBroadcasts();
      await _fetchPendingInstantChats();
    }

    // Then verify with server (but don't override if server fails)
    await _fetchOnlineStatus();
  }

  /// Fetch current online status from server using GET /instant-chat/status
  Future<void> _fetchOnlineStatus() async {
    if (accessToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.instantChatStatus}'),
        headers: {
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint(
        'Fetch online status response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { "isOnline": true, "astrologerId": "..." }
        final serverOnlineStatus = data['isOnline'] ?? false;

        // Sync local storage with server status
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('astrologerOnlineStatus', serverOnlineStatus);

        setState(() {
          isOnline = serverOnlineStatus;
        });

        // If already online on server, connect socket and fetch pending requests
        if (serverOnlineStatus) {
          await _connectSocket();
          _setupBroadcastListener();
          // _setupRealtimeNotificationListeners() is called inside _connectSocket()
          await _fetchPendingBroadcasts();
          await _fetchPendingInstantChats();
        }
      }
      // If server request fails, keep using the locally saved status (already loaded)
    } catch (e) {
      debugPrint('Error fetching online status: $e');
      // On error, keep using the locally saved status
    }
  }

  /// Fetch pending broadcast messages from API GET /broadcast-messages/pending
  Future<void> _fetchPendingBroadcasts() async {
    if (accessToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse(
          '${ApiEndpoints.baseUrl}${ApiEndpoints.broadcastMessagesPending}',
        ),
        headers: {
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint('Fetch pending broadcasts response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { "messages": [ { "id": "...", "client": {...}, "content": "...", ... } ] }
        final messages = data['messages'] ?? data['data'] ?? [];

        final List<Map<String, dynamic>> broadcasts = [];
        for (var msg in messages) {
          final client = msg['client'] ?? {};
          broadcasts.add({
            'messageId': msg['id'] ?? '',
            'content': msg['content'] ?? '',
            'type': msg['type'] ?? 'TEXT',
            'clientId': client['id'] ?? msg['clientId'] ?? '',
            'clientName': client['name'] ?? 'Client',
            'clientPhoto': client['profilePhoto'],
            'expiresAt': msg['expiresAt'],
            'createdAt': msg['createdAt'],
          });
        }

        if (mounted) {
          setState(() {
            _broadcastNotifications = broadcasts;
            _pendingBroadcastCount = broadcasts.length;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending broadcasts: $e');
    }
  }

  /// Fetch pending instant chat requests from API GET /instant-chat/pending
  Future<void> _fetchPendingInstantChats() async {
    if (accessToken.isEmpty) return;

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.instantChatPending}'),
        headers: {
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint(
        'Fetch pending instant chats response: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Response: { "requests": [ { "id": "...", "client": {...}, "message": "...", ... } ] }
        final requests = data['requests'] ?? data['data'] ?? [];

        // Show dialogs for each pending instant chat request
        for (var req in requests) {
          if (mounted) {
            _showInstantChatDialog(Map<String, dynamic>.from(req));
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching pending instant chats: $e');
    }
  }

  Future<void> _handleLogout() async {
    debugPrint('Logout tapped');

    // Clear online status before logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('astrologerOnlineStatus', false);

    // Try to set offline on server
    if (accessToken.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${ApiEndpoints.baseUrl}/astrologer/toggle-online'),
          headers: {
            'Content-Type': 'application/json',
            'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
          },
          body: jsonEncode({'isOnline': false}),
        );
      } catch (e) {
        debugPrint('Error setting offline on logout: $e');
      }
    }

    // Clear all astrologer data
    await prefs.remove('astrologerId');
    await prefs.remove('astrologerAccessToken');
    await prefs.remove('astrologerRefreshToken');

    // Disconnect socket
    _socketService.disconnect();

    if (!mounted) return;

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreenAstrologer()),
    );
  }
}

/// Dialog widget for broadcast notifications
class _BroadcastNotificationDialog extends StatelessWidget {
  final Map<String, dynamic> broadcast;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _BroadcastNotificationDialog({
    required this.broadcast,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final senderName = broadcast['clientName'] ?? 'Client';
    final message = broadcast['content'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.withOpacity(0.4), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.campaign_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            SizedBox(height: 20),

            // Title
            Text(
              'New Broadcast Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            // Sender info
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_rounded, color: Colors.white70, size: 16),
                  SizedBox(width: 6),
                  Text(
                    senderName,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),

            // Message
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onReject,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog widget for instant chat notifications
class _InstantChatNotificationDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _InstantChatNotificationDialog({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final clientName = request['clientName'] ?? 'Client';
    final message = request['message'] ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blue.withAlpha(102), width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.blue.shade700],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withAlpha(102),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'New Chat Request',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Sender info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withAlpha(51),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_rounded,
                    color: Colors.white70,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    clientName,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(13),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(26), width: 1),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onReject,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(51),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withAlpha(102),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Reject',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onAccept,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green, Colors.green.shade700],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withAlpha(77),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
