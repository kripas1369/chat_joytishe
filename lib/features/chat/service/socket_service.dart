import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/notification/services/notification_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Socket Service - Singleton
/// Handles all real-time socket communication
///
/// Based on FLUTTER_SOCKET_EXACT_CONNECTION.md
/// Cookie format: 'accessToken=XXX; refreshToken=YYY'
class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? socket;
  bool isConnected = false;

  // Notification service for push notifications
  final NotificationService _notificationService = NotificationService();

  // Flag to enable/disable local notifications for incoming requests
  bool enableLocalNotifications = false;

  // Flag to enable/disable chat message notifications
  // Set to false when user is in active chat screen
  bool enableChatNotifications = true;

  // Current active chat ID (to avoid notifications for current chat)
  String? activeChatId;

  /// Connect to Socket.IO server using access token and refresh token
  /// Tokens are sent as cookies in extraHeaders
  ///
  /// IMPORTANT Cookie Format:
  /// ✅ Correct: 'accessToken=TOKEN1; refreshToken=TOKEN2' (semicolon + space)
  /// ❌ Wrong: 'accessToken=TOKEN1;refreshToken=TOKEN2' (missing space)
  Future<void> connect({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (socket != null && socket!.connected) {
      print('✅ Already connected to socket');
      return;
    }

    // Disconnect existing socket if any
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }

    // Format cookies exactly like browser sends
    // IMPORTANT: semicolon followed by space
    final cookieString = 'accessToken=$accessToken; refreshToken=$refreshToken';

    try {
      print('═══════════════════════════════════════════════════════');
      print('🔌 Connecting to: ${ApiEndpoints.socketUrl}');
      print('🔑 Access Token: ${accessToken.substring(0, 20)}...');
      print('═══════════════════════════════════════════════════════');

      socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Allow both transports
            .enableForceNew() // Force new connection
            .setExtraHeaders({
              // Send cookies exactly like browser
              'cookie': cookieString,
              'origin': ApiEndpoints.socketUrl,
              'user-agent': 'Flutter-Socket-Client',
            })
            .build(),
      );

      _setupEventListeners();
      socket!.connect();
    } catch (e) {
      print('❌ Socket connection error: $e');
      throw Exception('Failed to connect to socket: $e');
    }
  }

  /// Connect using cookie string directly
  Future<void> connectWithCookies(String cookieString) async {
    if (socket != null && socket!.connected) {
      print('✅ Already connected to socket');
      return;
    }

    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }

    try {
      print('═══════════════════════════════════════════════════════');
      print('🔌 Connecting to: ${ApiEndpoints.socketUrl}');
      print('🔑 Using cookie string');
      print('═══════════════════════════════════════════════════════');

      socket = IO.io(
        ApiEndpoints.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableForceNew()
            .setExtraHeaders({
              'cookie': cookieString,
              'origin': ApiEndpoints.socketUrl,
              'user-agent': 'Flutter-Socket-Client',
            })
            .build(),
      );

      _setupEventListeners();
      socket!.connect();
    } catch (e) {
      print('❌ Socket connection error: $e');
      throw Exception('Failed to connect to socket: $e');
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    // ✅ Connection successful
    socket?.on('connect', (_) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('✅ Socket connected!');
      print('   Socket ID: ${socket?.id}');
      print('   Transport: ${socket?.io.engine?.transport?.name}');
      print('═══════════════════════════════════════════════════════');
      print('');
      isConnected = true;
    });

    // ❌ Connection error
    socket?.on('connect_error', (error) {
      print('');
      print('═══════════════════════════════════════════════════════');
      print('❌ Connection error: $error');
      print('   Error type: ${error.runtimeType}');
      print('═══════════════════════════════════════════════════════');
      print('');
      isConnected = false;
    });

    // 🔌 Disconnected
    socket?.on('disconnect', (reason) {
      print('🔌 Disconnected: $reason');
      isConnected = false;
    });

    // ❌ Socket error
    socket?.on('error', (error) {
      print('❌ Socket error: $error');
    });

    // Debug: Listen to all events
    socket?.onAny((event, data) {
      print('📨 Event: $event');
      if (data != null) {
        print('   Data: $data');
      }
    });
  }

  /// Disconnect from socket
  void disconnect() {
    socket?.disconnect();
    socket?.dispose();
    socket = null;
    isConnected = false;
    print('🔌 Socket disconnected');
  }

  /// Check if socket is connected
  bool get connected => socket?.connected ?? false;

  /// Set active chat ID (call when entering a chat screen)
  /// This prevents notifications for messages in the current chat
  void setActiveChat(String? chatId) {
    activeChatId = chatId;
  }

  /// Clear active chat (call when leaving a chat screen)
  void clearActiveChat() {
    activeChatId = null;
  }

  // ============================================================
  // CHAT EVENTS
  // ============================================================

  /// Send a chat message
  void sendMessage({
    required String receiverId,
    required String content,
    String type = 'TEXT',
    Map<String, dynamic>? metadata,
  }) {
    if (!connected) {
      throw Exception('Socket not connected');
    }

    socket?.emit('chat:send', {
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'metadata': metadata,
    });
    print('📤 Message sent to $receiverId');
  }

  /// Listen for incoming messages
  /// Shows local notification if enableChatNotifications is true and
  /// message is not from the active chat
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:receive', (data) {
      print('📨 Message received: ${data['content']}');
      final mapData = Map<String, dynamic>.from(data);

      // Show notification if enabled and not from active chat
      final chatId = mapData['chatId'] ?? mapData['chat']?['id'];
      if (enableChatNotifications && chatId != activeChatId) {
        final sender = mapData['sender'] ?? mapData['user'];
        _notificationService.showChatMessageNotification(
          messageId: mapData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: sender?['name'] ?? 'Someone',
          message: mapData['content'] ?? '',
          senderId: sender?['id'] ?? mapData['senderId'],
          chatId: chatId,
          senderPhoto: sender?['profilePhoto'],
        );
      }

      callback(mapData);
    });
  }

  /// Remove message received listener
  void offMessageReceived() {
    socket?.off('chat:receive');
  }

  /// Listen for sent message confirmation
  void onMessageSent(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:sent', (data) {
      print('✅ Message sent confirmation');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove message sent listener
  void offMessageSent() {
    socket?.off('chat:sent');
  }

  /// Listen for chat errors
  void onChatError(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:error', (data) {
      print('❌ Chat error: ${data['message']}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove chat error listener
  void offChatError() {
    socket?.off('chat:error');
  }

  /// Send typing indicator
  void sendTypingIndicator({
    required String receiverId,
    required bool isTyping,
  }) {
    if (!connected) return;

    socket?.emit('chat:typing', {
      'receiverId': receiverId,
      'isTyping': isTyping,
    });
  }

  /// Listen for typing indicator
  void onTypingIndicator(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:typing-indicator', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove typing indicator listener
  void offTypingIndicator() {
    socket?.off('chat:typing-indicator');
  }

  /// Mark messages as read (via socket)
  void markMessagesAsRead(List<String> messageIds) {
    if (!connected) return;

    socket?.emit('chat:mark-read', {'messageIds': messageIds});
  }

  /// Listen for marked as read confirmation
  void onMarkedAsRead(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:marked-read', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove marked as read listener
  void offMarkedAsRead() {
    socket?.off('chat:marked-read');
  }

  /// Listen for user online/offline status
  void onUserStatus(Function(Map<String, dynamic>) callback) {
    socket?.on('user:status', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove user status listener
  void offUserStatus() {
    socket?.off('user:status');
  }

  // ============================================================
  // NOTIFICATION EVENTS
  // ============================================================

  /// Listen for new notifications
  void onNotification(Function(Map<String, dynamic>) callback) {
    socket?.on('notification:new', (data) {
      print('🔔 New notification: ${data['title']}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Mark notification as read (via socket)
  void markNotificationAsRead(String notificationId) {
    if (!connected) return;

    socket?.emit('notification:mark-read', {'notificationId': notificationId});
  }

  /// Mark all notifications as read (via socket)
  void markAllNotificationsAsRead() {
    if (!connected) return;

    socket?.emit('notification:mark-all-read');
  }

  /// Listen for notification marked as read
  void onNotificationMarkedAsRead(Function(Map<String, dynamic>) callback) {
    socket?.on('notification:marked-read', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for all notifications marked as read
  void onAllNotificationsMarkedAsRead(Function() callback) {
    socket?.on('notification:all-marked-read', (_) {
      callback();
    });
  }

  // ============================================================
  // INSTANT CHAT EVENTS (Client requests specific astrologer)
  // ============================================================

  /// Request instant chat with specific astrologer (Client)
  void requestInstantChat({
    required String astrologerId,
    required String message,
  }) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('instantChat:request', {
      'astrologerId': astrologerId,
      'message': message,
    });
    print('📤 Instant chat request sent to astrologer: $astrologerId');
  }

  /// Listen for instant chat request sent confirmation (Client)
  void onInstantChatRequested(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:requested', (data) {
      print('✅ Instant chat request sent successfully');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove instant chat requested listener
  void offInstantChatRequested() {
    socket?.off('instantChat:requested');
  }

  /// Listen for new instant chat requests (Astrologer)
  /// Shows local notification if enableLocalNotifications is true
  void onNewInstantChatRequest(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:newRequest', (data) {
      print('📨 New instant chat request received');
      final mapData = Map<String, dynamic>.from(data);

      // Show local notification for astrologer
      if (enableLocalNotifications) {
        final request = mapData['request'] ?? mapData;
        final client = request['client'] ?? mapData['client'];
        _notificationService.showInstantChatNotification(
          requestId: request['id'] ?? mapData['id'] ?? '',
          clientName: client?['name'] ?? 'Client',
          message: request['message'] ?? mapData['message'] ?? '',
          clientId: client?['id'] ?? request['clientId'] ?? '',
          clientPhoto: client?['profilePhoto'],
        );
      }

      callback(mapData);
    });
  }

  /// Remove new instant chat request listener
  void offNewInstantChatRequest() {
    socket?.off('instantChat:newRequest');
  }

  /// Accept instant chat request (Astrologer)
  void acceptInstantChatRequest(String requestId) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('instantChat:accept', {'requestId': requestId});
    print('📤 Accepting instant chat request: $requestId');
  }

  /// Listen for instant chat accepted (Client receives when astrologer accepts)
  void onInstantChatAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:accepted', (data) {
      print('✅ Instant chat accepted!');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove instant chat accepted listener
  void offInstantChatAccepted() {
    socket?.off('instantChat:accepted');
  }

  /// Listen for instant chat rejected (Client)
  void onInstantChatRejected(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:rejected', (data) {
      print('❌ Instant chat rejected');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove instant chat rejected listener
  void offInstantChatRejected() {
    socket?.off('instantChat:rejected');
  }

  /// Listen for instant chat errors
  void onInstantChatError(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:error', (data) {
      print('❌ Instant chat error: ${data['message']}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove instant chat error listener
  void offInstantChatError() {
    socket?.off('instantChat:error');
  }

  // ============================================================
  // BROADCAST CHAT EVENTS (Client broadcasts to all astrologers)
  // ============================================================

  /// Send broadcast message to all online astrologers (Client only)
  void sendBroadcastMessage({
    required String content,
    String type = 'TEXT',
    Map<String, dynamic>? metadata,
  }) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('broadcast:send', {
      'content': content,
      'type': type,
      if (metadata != null) 'metadata': metadata,
    });
    print('📤 Broadcast message sent: $content');
  }

  /// Listen for broadcast sent confirmation (Client)
  void onBroadcastSent(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:sent', (data) {
      print('✅ Broadcast sent successfully');
      print('   Message ID: ${data['message']?['id']}');
      print('   Expires at: ${data['message']?['expiresAt']}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove broadcast sent listener
  void offBroadcastSent() {
    socket?.off('broadcast:sent');
  }

  /// Listen for when an astrologer accepts the broadcast (Client)
  void onBroadcastAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:accepted', (data) {
      print('✅ Astrologer accepted your broadcast!');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove broadcast accepted listener
  void offBroadcastAccepted() {
    socket?.off('broadcast:accepted');
  }

  /// Listen for broadcast expiry (Client - expires after 5 min if no accept)
  void onBroadcastExpired(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:expired', (data) {
      print('⏰ Broadcast expired');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove broadcast expired listener
  void offBroadcastExpired() {
    socket?.off('broadcast:expired');
  }

  /// Listen for new broadcast messages (Astrologer)
  /// Shows local notification if enableLocalNotifications is true
  void onNewBroadcastMessage(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:newMessage', (data) {
      print('📨 New broadcast message received');
      final mapData = Map<String, dynamic>.from(data);

      // Show local notification for astrologer
      if (enableLocalNotifications) {
        final message = mapData['message'] ?? mapData;
        final client = message['client'] ?? mapData['client'];
        _notificationService.showBroadcastNotification(
          messageId: message['id'] ?? mapData['id'] ?? '',
          clientName: client?['name'] ?? 'Client',
          message: message['content'] ?? mapData['content'] ?? '',
          clientId: client?['id'] ?? message['clientId'] ?? '',
          clientPhoto: client?['profilePhoto'],
        );
      }

      callback(mapData);
    });
  }

  /// Remove new broadcast message listener
  void offNewBroadcastMessage() {
    socket?.off('broadcast:newMessage');
  }

  /// Accept a broadcast message (Astrologer only)
  void acceptBroadcastMessage(String messageId) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('broadcast:accept', {'messageId': messageId});
    print('📤 Accepting broadcast message: $messageId');
  }

  /// Listen for broadcast errors
  void onBroadcastError(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:error', (data) {
      print('❌ Broadcast error: ${data['message']}');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove broadcast error listener
  void offBroadcastError() {
    socket?.off('broadcast:error');
  }

  // ============================================================
  // CHAT SESSION EVENTS
  // ============================================================

  /// Listen for chat ended by other party
  void onChatEnded(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:ended', (data) {
      print('❌ Chat ended');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove chat ended listener
  void offChatEnded() {
    socket?.off('chat:ended');
  }

  // ============================================================
  // APPOINTMENT EVENTS
  // ============================================================

  /// Listen for appointment confirmed (Chat created)
  void onAppointmentConfirmed(Function(Map<String, dynamic>) callback) {
    socket?.on('appointment:confirmed', (data) {
      print('✅ Appointment confirmed!');
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Remove appointment confirmed listener
  void offAppointmentConfirmed() {
    socket?.off('appointment:confirmed');
  }

  // ============================================================
  // REMOVE ALL LISTENERS
  // ============================================================

  /// Remove all custom listeners (call when leaving chat screens)
  void removeAllListeners() {
    // Chat listeners
    offMessageReceived();
    offMessageSent();
    offChatError();
    offTypingIndicator();
    offMarkedAsRead();
    offUserStatus();
    offChatEnded();

    // Instant chat listeners
    offInstantChatRequested();
    offNewInstantChatRequest();
    offInstantChatAccepted();
    offInstantChatRejected();
    offInstantChatError();

    // Broadcast listeners
    offBroadcastSent();
    offBroadcastAccepted();
    offBroadcastExpired();
    offNewBroadcastMessage();
    offBroadcastError();

    // Appointment listeners
    offAppointmentConfirmed();

    print('🧹 All listeners removed');
  }
}
