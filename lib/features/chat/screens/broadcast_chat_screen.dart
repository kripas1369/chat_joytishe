import 'dart:async';
import 'dart:convert';
import 'package:chat_jyotishi/features/app_widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../service/socket_service.dart';
import 'chat_screen.dart';

const List<Map<String, dynamic>> defaultBroadcastMessages = [
  {
    'icon': Icons.help_outline_rounded,
    'text': 'I need guidance about my future',
    'color': Colors.blue,
  },
  {
    'icon': Icons.favorite_rounded,
    'text': 'I want to know about my love life',
    'color': Colors.pink,
  },
  {
    'icon': Icons.work_rounded,
    'text': 'Need advice about my career',
    'color': Colors.orange,
  },
  {
    'icon': Icons.attach_money_rounded,
    'text': 'Questions about my financial future',
    'color': Colors.green,
  },
  {
    'icon': Icons.family_restroom_rounded,
    'text': 'Family related consultation needed',
    'color': Colors.purple,
  },
  {
    'icon': Icons.health_and_safety_rounded,
    'text': 'Health concerns - need guidance',
    'color': Colors.red,
  },
  {
    'icon': Icons.school_rounded,
    'text': 'Education and studies guidance',
    'color': Colors.teal,
  },
  {
    'icon': Icons.flight_takeoff_rounded,
    'text': 'Travel and relocation questions',
    'color': Colors.indigo,
  },
  {
    'icon': Icons.ring_volume_rounded,
    'text': 'Marriage compatibility check',
    'color': Colors.deepOrange,
  },
  {
    'icon': Icons.stars_rounded,
    'text': 'General horoscope reading',
    'color': Colors.amber,
  },
];

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

/// Broadcast Chat Screen - "Everyone Jyotish" feature
/// Client sends a broadcast message to all online astrologers
/// First astrologer to accept gets the chat
class BroadcastChatScreen extends StatefulWidget {
  const BroadcastChatScreen({super.key});

  @override
  State<BroadcastChatScreen> createState() => _BroadcastChatScreenState();
}

class _BroadcastChatScreenState extends State<BroadcastChatScreen>
    with SingleTickerProviderStateMixin {
  final SocketService _socketService = SocketService();

  bool _isConnecting = false;
  bool _isSending = false;
  bool _isWaiting = false;
  String? _selectedMessage;
  int? _selectedIndex;
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  int _remainingSeconds = 300; // 5 minutes

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
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
    // Listen for broadcast sent confirmation
    _socketService.onBroadcastSent((data) {
      debugPrint('Broadcast sent: $data');
      if (mounted) {
        setState(() {
          if (data['message']?['expiresAt'] != null) {
            _expiresAt = DateTime.parse(data['message']['expiresAt']);
            _startCountdown();
          }
        });
      }
    });

    // Listen for broadcast accepted by astrologer
    _socketService.onBroadcastAccepted((data) {
      debugPrint('Broadcast accepted: $data');
      _countdownTimer?.cancel();

      final chat = data['chat'];
      final astrologer = data['astrologer'];

      if (chat != null && astrologer != null && mounted) {
        // Navigate to chat screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chat['id'],
              otherUserId: astrologer['id'],
              otherUserName: astrologer['name'] ?? 'Astrologer',
              otherUserPhoto: astrologer['profilePhoto'],
              currentUserId: _currentUserId!,
              accessToken: _accessToken,
              refreshToken: _refreshToken,
              isOnline: true,
            ),
          ),
        );
      }
    });

    // Listen for broadcast expired
    _socketService.onBroadcastExpired((data) {
      debugPrint('Broadcast expired: $data');
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isWaiting = false;
          _selectedMessage = null;
          _selectedIndex = null;
        });
        showTopSnackBar(
          context: context,
          message: 'No astrologer accepted your request. Please try again.',
          backgroundColor: AppColors.error,
        );
      }
    });

    // Listen for broadcast errors
    _socketService.onBroadcastError((data) {
      debugPrint('Broadcast error: $data');
      _countdownTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSending = false;
          _isWaiting = false;
        });

        String errorMessage = data['message'] ?? 'An error occurred';
        if (data['code'] == 'ACTIVE_CHAT_EXISTS') {
          errorMessage =
              'You already have an active chat. Please end it first.';
        } else if (data['code'] == 'NO_ASTROLOGERS_ONLINE') {
          errorMessage = 'No astrologers are available at the moment.';
        }

        showTopSnackBar(
          context: context,
          message: errorMessage,
          backgroundColor: AppColors.error,
        );
      }
    });
  }

  void _startCountdown() {
    if (_expiresAt == null) {
      _remainingSeconds = 300;
    } else {
      _remainingSeconds = _expiresAt!.difference(DateTime.now()).inSeconds;
    }

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            timer.cancel();
            // Expiry will be handled by socket event
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _sendBroadcast() {
    if (_selectedMessage == null || _selectedMessage!.isEmpty) {
      showTopSnackBar(
        context: context,
        message: 'Please select a message',
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
      _socketService.sendBroadcastMessage(
        content: _selectedMessage!,
        type: 'TEXT',
      );
      setState(() => _isSending = false);
    } catch (e) {
      setState(() {
        _isSending = false;
        _isWaiting = false;
      });
      showTopSnackBar(
        context: context,
        message: 'Failed to send broadcast: $e',
        backgroundColor: AppColors.error,
      );
    }
  }

  void _cancelBroadcast() {
    _countdownTimer?.cancel();
    setState(() {
      _isWaiting = false;
      _selectedMessage = null;
      _selectedIndex = null;
    });
    // Note: The backend may need a cancel event - for now we just reset UI
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();

    // Remove listeners
    _socketService.offBroadcastSent();
    _socketService.offBroadcastAccepted();
    _socketService.offBroadcastExpired();
    _socketService.offBroadcastError();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
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
                    child: _isWaiting ? _buildWaitingView() : _buildInputView(),
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
    return Column(
      children: [
        Row(
          children: [
            GlassIconButton(
              onTap: () => Navigator.pop(context),
              icon: Icons.arrow_back,
            ),
            const SizedBox(width: 16),
            const Text(
              'Broadcast Message',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoCard(),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.8),
                      Colors.deepOrange.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast to All Astrologers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your message will be sent to all available astrologers',
                      style: TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'First astrologer to accept will start a chat with you',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Message options grid
        Expanded(
          child: ListView.separated(
            itemCount: defaultBroadcastMessages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final message = defaultBroadcastMessages[index];
              final isSelected = _selectedIndex == index;
              final color = message['color'] as Color;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = index;
                    _selectedMessage = message['text'] as String;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [color.withOpacity(0.3), color.withOpacity(0.15)]
                          : [
                              Colors.white.withOpacity(0.08),
                              Colors.white.withOpacity(0.03),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? color.withOpacity(0.6)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isSelected ? 0.3 : 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          message['icon'] as IconData,
                          color: isSelected ? color : color.withOpacity(0.7),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          message['text'] as String,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        AppButton(
          title: _isSending
              ? 'Broadcasting...'
              : _selectedMessage != null
              ? 'Broadcast Now'
              : 'Select a topic above',
          onTap: (_isSending || _selectedMessage == null)
              ? null
              : _sendBroadcast,
          isLoading: _isSending,
          icon: Icons.broadcast_on_personal,
          gradient: _selectedMessage != null
              ? AppColors.splashGradient
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated waiting indicator
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryPurple.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.broadcast_on_personal,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          const Text(
            'Waiting for an astrologer...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your message has been sent to all online astrologers',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Countdown timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: _remainingSeconds < 60 ? Colors.red : Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expires in ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.red : Colors.white,
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
            onTap: _cancelBroadcast,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Text(
                'Cancel',
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
