import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../../app_widgets/star_field_background.dart';
import '../../chat/service/socket_service.dart';
import '../models/astrologer_chat_models.dart';
import '../service/astrologer_chat_service.dart';
import 'astrologer_chat_screen.dart';

/// Decode JWT token to get user info
Map<String, dynamic>? decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    switch (payload.length % 4) {
      case 1:
        payload += '===';
        break;
      case 2:
        payload += '==';
        break;
      case 3:
        payload += '=';
        break;
    }

    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  } catch (e) {
    debugPrint('Error decoding JWT: $e');
    return null;
  }
}

/// Unified request model for both broadcast and instant chat
class IncomingRequest {
  final String id;
  final String type; // 'broadcast' or 'instant'
  final String clientId;
  final String clientName;
  final String? clientPhoto;
  final String message;
  final DateTime createdAt;
  final DateTime? expiresAt;

  IncomingRequest({
    required this.id,
    required this.type,
    required this.clientId,
    required this.clientName,
    this.clientPhoto,
    required this.message,
    required this.createdAt,
    this.expiresAt,
  });

  factory IncomingRequest.fromBroadcast(Map<String, dynamic> data) {
    final message = data['message'] ?? data;
    final client = message['client'] ?? data['client'];
    return IncomingRequest(
      id: message['id'] ?? data['id'] ?? '',
      type: 'broadcast',
      clientId: client?['id'] ?? message['clientId'] ?? '',
      clientName: client?['name'] ?? 'Client',
      clientPhoto: client?['profilePhoto'],
      message: message['content'] ?? data['content'] ?? '',
      createdAt: message['createdAt'] != null
          ? DateTime.parse(message['createdAt'])
          : DateTime.now(),
      expiresAt: message['expiresAt'] != null
          ? DateTime.parse(message['expiresAt'])
          : null,
    );
  }

  factory IncomingRequest.fromInstant(Map<String, dynamic> data) {
    final request = data['request'] ?? data;
    final client = request['client'] ?? data['client'];
    return IncomingRequest(
      id: request['id'] ?? data['id'] ?? '',
      type: 'instant',
      clientId: client?['id'] ?? request['clientId'] ?? '',
      clientName: client?['name'] ?? 'Client',
      clientPhoto: client?['profilePhoto'],
      message: request['message'] ?? data['message'] ?? '',
      createdAt: request['createdAt'] != null
          ? DateTime.parse(request['createdAt'])
          : DateTime.now(),
      expiresAt: request['expiresAt'] != null
          ? DateTime.parse(request['expiresAt'])
          : null,
    );
  }

  factory IncomingRequest.fromBroadcastModel(BroadcastMessageModel model) {
    return IncomingRequest(
      id: model.id,
      type: 'broadcast',
      clientId: model.clientId,
      clientName: model.client?.name ?? 'Client',
      clientPhoto: model.client?.profilePhoto,
      message: model.content,
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
    );
  }

  factory IncomingRequest.fromInstantModel(InstantChatRequestModel model) {
    return IncomingRequest(
      id: model.id,
      type: 'instant',
      clientId: model.clientId,
      clientName: model.client?.name ?? 'Client',
      clientPhoto: model.client?.profilePhoto,
      message: model.message ?? '',
      createdAt: model.createdAt,
      expiresAt: model.expiresAt,
    );
  }

  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final remaining = expiresAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
}

/// Incoming Requests Screen for Astrologers
/// Shows broadcast messages and instant chat requests from clients
class IncomingRequestsScreen extends StatefulWidget {
  const IncomingRequestsScreen({super.key});

  @override
  State<IncomingRequestsScreen> createState() => _IncomingRequestsScreenState();
}

class _IncomingRequestsScreenState extends State<IncomingRequestsScreen> {
  final SocketService _socketService = SocketService();
  final AstrologerChatService _chatService = AstrologerChatService();
  final List<IncomingRequest> _requests = [];

  bool _isLoading = true;
  bool _isConnecting = false;
  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;

  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();

    // Start timer to update expiry times
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        // Remove expired requests
        final now = DateTime.now();
        _requests.removeWhere((r) =>
          r.expiresAt != null && now.isAfter(r.expiresAt!));
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _socketService.offNewBroadcastMessage();
    _socketService.offNewInstantChatRequest();
    _socketService.offBroadcastError();
    _socketService.offInstantChatAccepted();
    _socketService.offInstantChatError();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    await _loadUserData();

    if (_currentUserId == null) {
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: 'Please login first',
          backgroundColor: AppColors.error,
        );
        Navigator.pop(context);
      }
      return;
    }

    await _initializeService();
    await _connectSocket();
    await _loadPendingRequests();
    _setupSocketListeners();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('astrologerAccessToken') ??
                   prefs.getString('accessToken');
    _refreshToken = prefs.getString('astrologerRefreshToken') ??
                    prefs.getString('refreshToken');

    if (_accessToken != null) {
      final decoded = decodeJwt(_accessToken!);
      _currentUserId = decoded?['id'] ?? decoded?['userId'];
    }
  }

  Future<void> _initializeService() async {
    try {
      await _chatService.initialize();
    } catch (e) {
      debugPrint('Error initializing chat service: $e');
    }
  }

  Future<void> _connectSocket() async {
    if (!_socketService.connected &&
        _accessToken != null &&
        _refreshToken != null) {
      setState(() => _isConnecting = true);
      try {
        await _socketService.connect(
          accessToken: _accessToken!,
          refreshToken: _refreshToken!,
        );
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        debugPrint('Socket connection error: $e');
      }
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _isLoading = true);

    try {
      // Load pending broadcasts
      final broadcasts = await _chatService.getPendingBroadcasts();
      for (final broadcast in broadcasts) {
        final request = IncomingRequest.fromBroadcastModel(broadcast);
        if (!_requests.any((r) => r.id == request.id)) {
          _requests.add(request);
        }
      }

      // Load pending instant chats
      final instantChats = await _chatService.getPendingInstantChats();
      for (final instant in instantChats) {
        final request = IncomingRequest.fromInstantModel(instant);
        if (!_requests.any((r) => r.id == request.id)) {
          _requests.add(request);
        }
      }

      // Sort by created time (newest first)
      _requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('Error loading pending requests: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _setupSocketListeners() {
    // Enable local notifications
    _socketService.enableLocalNotifications = true;

    // Listen for new broadcast messages
    _socketService.onNewBroadcastMessage((data) {
      debugPrint('New broadcast message: $data');
      if (mounted) {
        final request = IncomingRequest.fromBroadcast(data);
        setState(() {
          _requests.removeWhere((r) => r.id == request.id);
          _requests.insert(0, request);
        });
      }
    });

    // Listen for new instant chat requests
    _socketService.onNewInstantChatRequest((data) {
      debugPrint('New instant chat request: $data');
      if (mounted) {
        final request = IncomingRequest.fromInstant(data);
        setState(() {
          _requests.removeWhere((r) => r.id == request.id);
          _requests.insert(0, request);
        });
      }
    });

    // Listen for acceptance success (for broadcast)
    _socketService.socket?.on('broadcast:accepted', (data) {
      debugPrint('Broadcast accepted confirmation: $data');
      _handleAcceptanceSuccess(data);
    });

    // Listen for acceptance success (for instant)
    _socketService.onInstantChatAccepted((data) {
      debugPrint('Instant chat accepted confirmation: $data');
      _handleAcceptanceSuccess(data);
    });

    // Listen for errors
    _socketService.onBroadcastError((data) {
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: data['message'] ?? 'Error accepting broadcast',
          backgroundColor: AppColors.error,
        );
      }
    });

    _socketService.onInstantChatError((data) {
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: data['message'] ?? 'Error accepting request',
          backgroundColor: AppColors.error,
        );
      }
    });
  }

  void _handleAcceptanceSuccess(Map<String, dynamic> data) {
    final chat = data['chat'];
    final client = data['client'];

    if (chat != null && mounted) {
      // Remove the request from list
      setState(() {
        _requests.removeWhere(
            (r) => r.clientId == (client?['id'] ?? chat['participant1Id']));
      });

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AstrologerChatScreen(
            chatId: chat['id'],
            clientId: client?['id'] ?? chat['participant1Id'] ?? '',
            clientName: client?['name'] ?? 'Client',
            clientPhoto: client?['profilePhoto'],
            astrologerId: _currentUserId!,
            accessToken: _accessToken,
            refreshToken: _refreshToken,
          ),
        ),
      );
    }
  }

  Future<void> _acceptRequest(IncomingRequest request) async {
    // Try socket first for real-time
    if (_socketService.connected) {
      if (request.type == 'broadcast') {
        _socketService.acceptBroadcastMessage(request.id);
      } else {
        _socketService.acceptInstantChatRequest(request.id);
      }

      showTopSnackBar(
        context: context,
        message: 'Accepting request...',
        backgroundColor: Colors.green,
      );
    } else {
      // HTTP fallback
      try {
        if (request.type == 'broadcast') {
          final response = await _chatService.acceptBroadcast(request.id);

          if (mounted && response.chatId != null) {
            setState(() {
              _requests.removeWhere((r) => r.id == request.id);
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AstrologerChatScreen(
                  chatId: response.chatId!,
                  clientId: response.client?.id ?? request.clientId,
                  clientName: response.client?.name ?? request.clientName,
                  clientPhoto: response.client?.profilePhoto ?? request.clientPhoto,
                  astrologerId: _currentUserId!,
                  accessToken: _accessToken,
                  refreshToken: _refreshToken,
                ),
              ),
            );
          }
        } else {
          final response = await _chatService.acceptInstantChat(request.id);

          if (mounted && response.chatId != null) {
            setState(() {
              _requests.removeWhere((r) => r.id == request.id);
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AstrologerChatScreen(
                  chatId: response.chatId!,
                  clientId: response.client?.id ?? request.clientId,
                  clientName: response.client?.name ?? request.clientName,
                  clientPhoto: response.client?.profilePhoto ?? request.clientPhoto,
                  astrologerId: _currentUserId!,
                  accessToken: _accessToken,
                  refreshToken: _refreshToken,
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message: e.toString().replaceAll('Exception: ', ''),
            backgroundColor: AppColors.error,
          );
        }
      }
    }
  }

  Future<void> _declineRequest(IncomingRequest request) async {
    // For broadcasts, we can dismiss via API
    if (request.type == 'broadcast') {
      try {
        await _chatService.dismissBroadcast(request.id);
      } catch (e) {
        debugPrint('Error dismissing broadcast: $e');
      }
    }

    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
    });
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatRemainingTime(Duration? remaining) {
    if (remaining == null) return '';
    if (remaining.isNegative || remaining.inSeconds <= 0) return 'Expired';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          GlassIconButton(
            onTap: () => Navigator.pop(context),
            icon: Icons.arrow_back,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incoming Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_requests.length} pending request${_requests.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(180),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (_requests.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(50),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          GlassIconButton(
            onTap: _loadPendingRequests,
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
        ),
      );
    }

    if (_requests.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadPendingRequests,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        itemCount: _requests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 64,
              color: AppColors.primaryPurple.withAlpha(125),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Pending Requests',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New chat requests will appear here',
            style: TextStyle(
              color: Colors.white.withAlpha(180),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(IncomingRequest request) {
    final imageUrl = request.clientPhoto != null
        ? (request.clientPhoto!.startsWith('http')
            ? request.clientPhoto!
            : '${ApiEndpoints.socketUrl}${request.clientPhoto}')
        : null;

    final isBroadcast = request.type == 'broadcast';
    final remainingTime = request.remainingTime;
    final isExpiringSoon = remainingTime != null &&
        remainingTime.inSeconds <= 60 &&
        remainingTime.inSeconds > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isBroadcast ? Colors.orange : Colors.blue).withAlpha(40),
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.red.withAlpha(150)
              : (isBroadcast ? Colors.orange : Colors.blue).withAlpha(75),
          width: isExpiringSoon ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type badge
          Row(
            children: [
              // Profile image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isBroadcast ? Colors.orange : Colors.blue,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(
                            request.clientName,
                          ),
                        )
                      : _buildDefaultAvatar(request.clientName),
                ),
              ),
              const SizedBox(width: 12),

              // Name and type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.clientName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isBroadcast ? Colors.orange : Colors.blue)
                                .withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isBroadcast ? 'Broadcast' : 'Direct Request',
                            style: TextStyle(
                              color: isBroadcast ? Colors.orange : Colors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(request.createdAt),
                          style: TextStyle(
                            color: Colors.white.withAlpha(125),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remaining time
              if (remainingTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isExpiringSoon
                        ? Colors.red.withAlpha(50)
                        : Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: isExpiringSoon ? Colors.red : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemainingTime(remainingTime),
                        style: TextStyle(
                          color: isExpiringSoon ? Colors.red : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request.message.isEmpty ? 'No message' : request.message,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _declineRequest(request),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Center(
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _acceptRequest(request),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isBroadcast
                            ? [Colors.orange, Colors.deepOrange]
                            : [Colors.blue, Colors.blue.shade700],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Accept & Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.primaryPurple.withAlpha(75),
      child: Center(
        child: Icon(
          Icons.person,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
