import 'package:chat_jyotishi/constants/api_endpoints.dart';
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
  void onMessageReceived(Function(Map<String, dynamic>) callback) {
    socket?.on('chat:receive', (data) {
      print('📨 Message received: ${data['content']}');
      callback(Map<String, dynamic>.from(data));
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
  // INSTANT CHAT EVENTS
  // ============================================================

  /// Create instant chat request (Client)
  void createInstantChatRequest({String? message}) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('instantChat:create', {
      if (message != null) 'message': message,
    });
  }

  /// Listen for instant chat created confirmation
  void onInstantChatCreated(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:created', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for new instant chat requests (Astrologer)
  void onNewInstantChatRequest(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:newRequest', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Accept instant chat request (Astrologer)
  void acceptInstantChatRequest(String requestId) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('instantChat:accept', {'requestId': requestId});
  }

  /// Listen for instant chat accepted (Astrologer)
  void onInstantChatAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:accepted', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for instant chat request accepted (Client)
  void onInstantChatRequestAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:requestAccepted', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Cancel instant chat request (Client)
  void cancelInstantChatRequest(String requestId) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('instantChat:cancel', {'requestId': requestId});
  }

  /// Listen for instant chat cancelled
  void onInstantChatCancelled(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:cancelled', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for instant chat errors
  void onInstantChatError(Function(Map<String, dynamic>) callback) {
    socket?.on('instantChat:error', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  // ============================================================
  // BROADCAST MESSAGE EVENTS
  // ============================================================

  /// Send broadcast message (Client only)
  void sendBroadcastMessage({required String content, String? type}) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('broadcast:sendMessage', {
      'content': content,
      if (type != null) 'type': type,
    });
  }

  /// Listen for broadcast message sent
  void onBroadcastMessageSent(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:messageSent', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Accept broadcast message (Astrologer only)
  void acceptBroadcastMessage(String messageId) {
    if (!connected) throw Exception('Socket not connected');

    socket?.emit('broadcast:acceptMessage', {'messageId': messageId});
  }

  /// Listen for broadcast message accepted (Astrologer)
  void onBroadcastMessageAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:messageAccepted', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for your broadcast accepted (Client)
  void onYourBroadcastAccepted(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:yourMessageAccepted', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }

  /// Listen for broadcast errors
  void onBroadcastError(Function(Map<String, dynamic>) callback) {
    socket?.on('broadcast:error', (data) {
      callback(Map<String, dynamic>.from(data));
    });
  }
}
