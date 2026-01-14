import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../../app_widgets/star_field_background.dart';
import '../../chat/service/socket_service.dart';
import '../../chat/screens/chat_screen.dart';

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

/// Model for incoming chat request
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
  final List<IncomingRequest> _requests = [];

  bool _isConnecting = false;
  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('accessToken');
    _refreshToken = prefs.getString('refreshToken');

    if (_accessToken != null) {
      final decoded = decodeJwt(_accessToken!);
      _currentUserId = decoded?['id'];
    }

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

    // Connect to socket if not connected
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

    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    // Listen for new broadcast messages
    _socketService.onNewBroadcastMessage((data) {
      debugPrint('New broadcast message: $data');
      if (mounted) {
        final request = IncomingRequest.fromBroadcast(data);
        setState(() {
          // Add to front of list, avoid duplicates
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
          builder: (_) => ChatScreen(
            chatId: chat['id'],
            otherUserId: client?['id'] ?? chat['participant1Id'] ?? '',
            otherUserName: client?['name'] ?? 'Client',
            otherUserPhoto: client?['profilePhoto'],
            currentUserId: _currentUserId!,
            accessToken: _accessToken,
            refreshToken: _refreshToken,
            isOnline: true,
          ),
        ),
      );
    }
  }

  void _acceptRequest(IncomingRequest request) {
    if (!_socketService.connected) {
      showTopSnackBar(
        context: context,
        message: 'Not connected. Please try again.',
        backgroundColor: AppColors.error,
      );
      return;
    }

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
  }

  void _declineRequest(IncomingRequest request) {
    setState(() {
      _requests.removeWhere((r) => r.id == request.id);
    });
    // Note: Backend may need a decline event for instant requests
  }

  @override
  void dispose() {
    _socketService.offNewBroadcastMessage();
    _socketService.offNewInstantChatRequest();
    _socketService.offBroadcastError();
    _socketService.offInstantChatAccepted();
    _socketService.offInstantChatError();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient.withOpacity(0.9),
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
                    child: _requests.isEmpty
                        ? _buildEmptyState()
                        : _buildRequestsList(),
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
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pop(context),
          icon: Icons.arrow_back_ios_new_rounded,
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
                  color: Colors.white.withOpacity(0.7),
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
              color: Colors.green.withOpacity(0.2),
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
      ],
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
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_rounded,
              size: 64,
              color: AppColors.primaryPurple.withOpacity(0.5),
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
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    return ListView.separated(
      itemCount: _requests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = _requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(IncomingRequest request) {
    final imageUrl = request.clientPhoto != null
        ? (request.clientPhoto!.startsWith('http')
            ? request.clientPhoto!
            : '${ApiEndpoints.socketUrl}${request.clientPhoto}')
        : null;

    final isBroadcast = request.type == 'broadcast';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            (isBroadcast ? Colors.orange : Colors.blue).withOpacity(0.15),
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isBroadcast ? Colors.orange : Colors.blue).withOpacity(0.3),
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
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(),
                        )
                      : _buildDefaultAvatar(),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: (isBroadcast ? Colors.orange : Colors.blue)
                            .withOpacity(0.2),
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
                  ],
                ),
              ),

              // Time
              Text(
                _formatTime(request.createdAt),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
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
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              request.message.isEmpty ? 'No message' : request.message,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
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
                      color: Colors.white.withOpacity(0.1),
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

  Widget _buildDefaultAvatar() {
    return Container(
      color: AppColors.primaryPurple.withOpacity(0.3),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 30,
      ),
    );
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
}
