import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../../app_widgets/star_field_background.dart';
import '../models/active_user_model.dart';
import '../service/socket_service.dart';
import 'chat_screen.dart';

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

/// Instant Chat Request Screen
/// Client requests a specific astrologer for a chat
class InstantChatRequestScreen extends StatefulWidget {
  final ActiveAstrologerModel astrologer;

  const InstantChatRequestScreen({super.key, required this.astrologer});

  @override
  State<InstantChatRequestScreen> createState() =>
      _InstantChatRequestScreenState();
}

class _InstantChatRequestScreenState extends State<InstantChatRequestScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();

  bool _isConnecting = false;
  bool _isSending = false;
  bool _isWaiting = false;
  String? _requestId;
  Timer? _timeoutTimer;
  int _waitingSeconds = 0;

  late AnimationController _rotationController;

  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupAnimations();
  }

  void _setupAnimations() {
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
    // Listen for request confirmation
    _socketService.onInstantChatRequested((data) {
      debugPrint('Instant chat requested: $data');
      if (mounted) {
        setState(() {
          _requestId = data['request']?['id'];
        });
      }
    });

    // Listen for astrologer acceptance
    _socketService.onInstantChatAccepted((data) {
      debugPrint('Instant chat accepted: $data');
      _timeoutTimer?.cancel();

      final chat = data['chat'];
      final astrologer = data['astrologer'];

      if (chat != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat['id'],
              otherUserId: astrologer?['id'] ?? widget.astrologer.id,
              otherUserName: astrologer?['name'] ?? widget.astrologer.name,
              otherUserPhoto:
                  astrologer?['profilePhoto'] ?? widget.astrologer.profilePhoto,
              currentUserId: _currentUserId!,
              accessToken: _accessToken,
              refreshToken: _refreshToken,
              isOnline: true,
            ),
          ),
        );
      }
    });

    // Listen for astrologer rejection
    _socketService.onInstantChatRejected((data) {
      debugPrint('Instant chat rejected: $data');
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isWaiting = false;
          _requestId = null;
        });
        showTopSnackBar(
          context: context,
          message:
              'The astrologer is currently busy. Please try another astrologer.',
          backgroundColor: AppColors.error,
        );
      }
    });

    // Listen for errors
    _socketService.onInstantChatError((data) {
      debugPrint('Instant chat error: $data');
      _timeoutTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSending = false;
          _isWaiting = false;
        });

        String errorMessage = data['message'] ?? 'An error occurred';
        if (data['code'] == 'ASTROLOGER_OFFLINE') {
          errorMessage = 'This astrologer is currently offline.';
        } else if (data['code'] == 'ACTIVE_CHAT_EXISTS') {
          errorMessage = 'You already have an active chat.';
        }

        showTopSnackBar(
          context: context,
          message: errorMessage,
          backgroundColor: AppColors.error,
        );
      }
    });
  }

  void _startWaitingTimer() {
    _waitingSeconds = 0;
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _waitingSeconds++;
          // Auto-cancel after 2 minutes if no response
          if (_waitingSeconds >= 120) {
            timer.cancel();
            _isWaiting = false;
            _requestId = null;
            showTopSnackBar(
              context: context,
              message: 'Request timed out. Please try again.',
              backgroundColor: AppColors.error,
            );
          }
        });
      }
    });
  }

  String _formatWaitingTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _sendRequest() {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      showTopSnackBar(
        context: context,
        message: 'Please enter a message',
        backgroundColor: Colors.orange,
      );
      return;
    }

    if (!_socketService.connected) {
      showTopSnackBar(
        context: context,
        message: 'Not connected. Please try again.',
        backgroundColor: AppColors.error,
      );
      return;
    }

    setState(() {
      _isSending = true;
      _isWaiting = true;
    });

    try {
      _socketService.requestInstantChat(
        astrologerId: widget.astrologer.id,
        message: message,
      );
      setState(() => _isSending = false);
      _startWaitingTimer();
    } catch (e) {
      setState(() {
        _isSending = false;
        _isWaiting = false;
      });
      showTopSnackBar(
        context: context,
        message: 'Failed to send request: $e',
        backgroundColor: AppColors.error,
      );
    }
  }

  void _cancelRequest() {
    _timeoutTimer?.cancel();
    setState(() {
      _isWaiting = false;
      _requestId = null;
    });
    // Note: Backend may need a cancel event
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _rotationController.dispose();
    _messageController.dispose();

    // Remove listeners
    _socketService.offInstantChatRequested();
    _socketService.offInstantChatAccepted();
    _socketService.offInstantChatRejected();
    _socketService.offInstantChatError();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.astrologer.profilePhoto.startsWith('http')
        ? widget.astrologer.profilePhoto
        : '${ApiEndpoints.socketUrl}${widget.astrologer.profilePhoto}';

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
                    child: _isWaiting
                        ? _buildWaitingView(imageUrl)
                        : _buildInputView(imageUrl),
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
          icon: Icons.arrow_back,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chat Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Request chat with ${widget.astrologer.name}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputView(String imageUrl) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Astrologer profile card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryPurple.withOpacity(0.2),
                  AppColors.deepPurple.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                // Profile image
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.astrologer.isOnline
                              ? Colors.green
                              : Colors.grey,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryPurple.withOpacity(0.3),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 40,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.astrologer.isOnline)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundDark,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Name
                Text(
                  widget.astrologer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                // Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: widget.astrologer.isOnline
                            ? Colors.green
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.astrologer.isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: widget.astrologer.isOnline
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Message input
          Container(
            alignment: Alignment.centerLeft,
            child: const Text(
              'Your Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.cardDark, AppColors.backgroundDark],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryPurple.withOpacity(0.3),
              ),
            ),
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Describe what you need help with...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Send button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isSending ? null : _sendRequest,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryPurple.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isSending)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    else
                      const Icon(Icons.send_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      _isSending ? 'Sending...' : 'Send Request',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView(String imageUrl) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated waiting indicator with profile
          Stack(
            alignment: Alignment.center,
            children: [
              // Rotating ring
              AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * 3.14159,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryPurple,
                          width: 3,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        gradient: SweepGradient(
                          colors: [
                            AppColors.primaryPurple.withOpacity(0.1),
                            AppColors.primaryPurple,
                            AppColors.primaryPurple.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Profile image
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.primaryPurple.withOpacity(0.3),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            'Waiting for ${widget.astrologer.name}...',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your request has been sent',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Waiting timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Waiting: ${_formatWaitingTime(_waitingSeconds)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Cancel button
          GestureDetector(
            onTap: _cancelRequest,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Cancel Request',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
