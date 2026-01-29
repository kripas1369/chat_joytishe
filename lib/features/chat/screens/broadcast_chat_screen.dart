import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../constants/api_endpoints.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../../app_widgets/star_field_background.dart';
import '../../payment/services/coin_provider.dart';
import '../../payment/widgets/insufficient_coins_sheet.dart';
import '../../payment/models/coin_models.dart';
import '../models/active_user_model.dart';
import '../repository/chat_repository.dart';
import '../service/chat_service.dart';
import '../service/socket_service.dart';
import 'chat_screen.dart';
import 'broadcast_loading_screen.dart';

/// Topic with subtopics structure
class TopicModel {
  final IconData icon;
  final String text;
  final Color color;
  final List<String> subtopics;

  TopicModel({
    required this.icon,
    required this.text,
    required this.color,
    required this.subtopics,
  });
}

/// Default topics with subtopics for quick selection
final List<TopicModel> defaultTopics = [
  TopicModel(
    icon: Icons.help_outline_rounded,
    text: 'I need guidance about my future',
    color: Colors.blue,
    subtopics: [
      'Life path guidance',
      'Career direction',
      'Personal growth',
      'Spiritual journey',
      'Life purpose',
    ],
  ),
  TopicModel(
    icon: Icons.favorite_rounded,
    text: 'I want to know about my love life',
    color: Colors.pink,
    subtopics: [
      'Relationship compatibility',
      'Marriage timing',
      'Love predictions',
      'Partner analysis',
      'Relationship issues',
    ],
  ),
  TopicModel(
    icon: Icons.work_rounded,
    text: 'Need advice about my career',
    color: Colors.orange,
    subtopics: [
      'Career change',
      'Job opportunities',
      'Business success',
      'Professional growth',
      'Workplace harmony',
    ],
  ),
  TopicModel(
    icon: Icons.attach_money_rounded,
    text: 'Questions about my financial future',
    color: Colors.green,
    subtopics: [
      'Wealth prediction',
      'Investment guidance',
      'Financial planning',
      'Money matters',
      'Business finance',
    ],
  ),
  TopicModel(
    icon: Icons.family_restroom_rounded,
    text: 'Family related consultation needed',
    color: Colors.purple,
    subtopics: [
      'Family harmony',
      'Children\'s future',
      'Parental guidance',
      'Family disputes',
      'Ancestral issues',
    ],
  ),
  TopicModel(
    icon: Icons.health_and_safety_rounded,
    text: 'Health concerns - need guidance',
    color: Colors.red,
    subtopics: [
      'Health predictions',
      'Medical guidance',
      'Wellness advice',
      'Health remedies',
      'Preventive care',
    ],
  ),
  TopicModel(
    icon: Icons.school_rounded,
    text: 'Education and studies guidance',
    color: Colors.teal,
    subtopics: [
      'Academic success',
      'Career choice',
      'Study guidance',
      'Examination predictions',
      'Educational path',
    ],
  ),
  TopicModel(
    icon: Icons.flight_takeoff_rounded,
    text: 'Travel and relocation questions',
    color: Colors.indigo,
    subtopics: [
      'Travel timing',
      'Relocation guidance',
      'Foreign opportunities',
      'Travel safety',
      'Settlement advice',
    ],
  ),
  TopicModel(
    icon: Icons.ring_volume_rounded,
    text: 'Marriage compatibility check',
    color: Colors.deepOrange,
    subtopics: [
      'Marriage timing',
      'Partner compatibility',
      'Marriage predictions',
      'Marital harmony',
      'Marriage remedies',
    ],
  ),
  TopicModel(
    icon: Icons.stars_rounded,
    text: 'General horoscope reading',
    color: Colors.amber,
    subtopics: [
      'Daily horoscope',
      'Weekly predictions',
      'Monthly forecast',
      'Yearly predictions',
      'Complete analysis',
    ],
  ),
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
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ChatRepository _chatRepository = ChatRepository(ChatService());

  bool _isConnecting = false;
  bool _isSending = false;
  bool _isWaiting = false;
  String? _selectedMessage;
  int? _selectedIndex;
  int? _expandedTopicIndex;
  Set<int> _selectedSubtopicIndices = {};
  final TextEditingController _customTextController = TextEditingController();
  final FocusNode _customTextFocusNode = FocusNode();
  DateTime? _expiresAt;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  int _remainingSeconds = 300; // 5 minutes

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _connectionController;
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  final Map<int, AnimationController> _subtopicAnimationControllers = {};

  // New animation controllers for broadcast waiting view
  late AnimationController _rippleController;
  final Map<int, AnimationController> _lineAnimations = {};
  final List<int> _connected = [];
  static const double particleRadiusRatio = 0.35;

  // Astrologer nodes for the network animation
  final List<AstrologerNode> _astrologers = [
    AstrologerNode('Vedic', '🔮', 'Vedic', Offset(0.15, 0.25)),
    AstrologerNode('Tarot', '🃏', 'Tarot', Offset(0.85, 0.25)),
    AstrologerNode('Numerology', '🔢', 'Numbers', Offset(0.08, 0.55)),
    AstrologerNode('Palmistry', '✋', 'Palmist', Offset(0.92, 0.55)),
    AstrologerNode('Vastu', '🏠', 'Vastu', Offset(0.22, 0.82)),
    AstrologerNode('Horoscope', '⭐', 'Horoscope', Offset(0.78, 0.82)),
  ];

  List<ActiveAstrologerModel> _onlineAstrologers = [];

  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;
  bool _isResolvingActiveChat = false;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    _setupAnimations();
    _setupSubtopicAnimations();
  }

  void _setupSubtopicAnimations() {
    for (int i = 0; i < defaultTopics.length; i++) {
      _subtopicAnimationControllers[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();

    _waveController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _waveAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );

    // Ripple controller for center node
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Future<void> _loadOnlineAstrologers() async {
    try {
      final astrologers = await _chatRepository.getActiveAstrologers();
      if (mounted) {
        setState(() {
          _onlineAstrologers = astrologers
              .where((a) => a.isOnline)
              .take(6) // Show max 6 online astrologers
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading online astrologers: $e');
    }
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
    // Note: Navigation is handled by BroadcastLoadingScreen
    _socketService.onBroadcastAccepted((data) {
      debugPrint('Broadcast accepted (BroadcastChatScreen): $data');
      _countdownTimer?.cancel();
      // BroadcastLoadingScreen handles the navigation to ChatScreen
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

        final errorCode = data['code']?.toString();
        String errorMessage = data['message'] ?? 'An error occurred';

        // Check for insufficient coins error
        if (InsufficientCoinsException.isInsufficientCoinsError(
          errorCode,
          errorMessage,
        )) {
          final required = InsufficientCoinsException.extractRequiredCoins(
            errorMessage,
          );
          final available = InsufficientCoinsException.extractAvailableCoins(
            errorMessage,
          );

          showInsufficientCoinsSheet(
            context: context,
            requiredCoins: required > 0 ? required : CoinCosts.broadcastMessage,
            availableCoins: available > 0 ? available : coinProvider.balance,
            message:
                'You need ${CoinCosts.broadcastMessage} coin to send a broadcast message.',
          ).then((_) => coinProvider.refreshBalance());
          return;
        }

        if (errorCode == 'ACTIVE_CHAT_EXISTS') {
          // Show a popup that lets the user end the current active chat
          // (via API) and then re-send this broadcast automatically.
          _showActiveChatExistsDialog();
          return;
        } else if (errorCode == 'NO_ASTROLOGERS_ONLINE') {
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

  /// Show dialog when backend reports an existing active chat
  void _showActiveChatExistsDialog() {
    if (_isResolvingActiveChat) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.32),
                    AppColors.cosmicPink.withOpacity(0.22),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    ).createShader(bounds),
                    child: const Text(
                      'Active chat detected',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You already have an active chat.\n'
                    'Do you want to end it and send this broadcast now?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGray300,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'No, cancel',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await _endActiveChatAndResendBroadcast();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.cosmicPurple,
                                  AppColors.cosmicPink,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPurple.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'End chat & broadcast',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// End the currently active chat via API, then re-send the broadcast.
  Future<void> _endActiveChatAndResendBroadcast() async {
    if (_isResolvingActiveChat) return;
    if (_accessToken == null || _refreshToken == null) {
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: 'Please login again to manage chats.',
          backgroundColor: AppColors.error,
        );
      }
      return;
    }

    setState(() {
      _isResolvingActiveChat = true;
      _isSending = true;
    });

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'cookie': 'accessToken=$_accessToken; refreshToken=$_refreshToken',
          },
        ),
      );

      // 1) Fetch conversations from API only (no local state)
      final response = await dio.get(ApiEndpoints.chatConversations);
      if (response.statusCode != 200) {
        if (mounted) {
          setState(() {
            _isResolvingActiveChat = false;
            _isSending = false;
          });
          showTopSnackBar(
            context: context,
            message: 'Could not load chats. Please try again.',
            backgroundColor: AppColors.error,
          );
        }
        return;
      }

      final raw = response.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map) {
        list = raw['chats'] ?? raw['conversations'] ?? raw['data'] ?? [];
      }
      final chats = list
          .where((e) => e is Map)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      // 2) Find first chat with status ACTIVE (from API only)
      Map<String, dynamic>? activeChat;
      for (final chat in chats) {
        final status = (chat['status']?.toString() ?? '').toUpperCase();
        if (status == 'ACTIVE') {
          activeChat = chat;
          break;
        }
      }

      if (activeChat == null || activeChat.isEmpty) {
        // No ACTIVE chat in API – still try sending broadcast
        if (mounted) {
          setState(() {
            _isResolvingActiveChat = false;
          });
          showTopSnackBar(
            context: context,
            message: 'No active chat to end. Sending broadcast...',
            backgroundColor: Colors.green,
          );
        }
        _sendBroadcast();
        return;
      }

      // 3) Get chat id from API response
      String? chatId = activeChat['id']?.toString();
      if (chatId == null || chatId.isEmpty) {
        chatId = activeChat['chat']?['id']?.toString();
      }
      if (chatId == null || chatId.isEmpty) {
        if (mounted) {
          setState(() {
            _isResolvingActiveChat = false;
            _isSending = false;
          });
          showTopSnackBar(
            context: context,
            message: 'Could not identify chat. Sending broadcast...',
            backgroundColor: Colors.orange,
          );
        }
        _sendBroadcast();
        return;
      }

      // 4) End chat via API
      await dio.put('${ApiEndpoints.chatEnd}/$chatId/end');

      if (mounted) {
        setState(() {
          _isResolvingActiveChat = false;
        });
        showTopSnackBar(
          context: context,
          message: 'Active chat ended. Sending your broadcast now...',
          backgroundColor: Colors.green,
        );
      }
      _sendBroadcast();
    } catch (e) {
      debugPrint('Error ending active chat before broadcast: $e');
      if (mounted) {
        setState(() {
          _isResolvingActiveChat = false;
          _isSending = false;
        });
        showTopSnackBar(
          context: context,
          message: 'Failed to end active chat. Please try again.',
          backgroundColor: AppColors.error,
        );
      }
    }
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

  Future<void> _sendBroadcast() async {
    // Build message from selected topic, subtopics, and custom text
    String finalMessage = '';

    if (_selectedIndex != null) {
      final topic = defaultTopics[_selectedIndex!];
      finalMessage = topic.text;

      // Add selected subtopics
      if (_selectedSubtopicIndices.isNotEmpty) {
        final selectedSubtopics = _selectedSubtopicIndices
            .map((idx) => topic.subtopics[idx])
            .join(', ');
        finalMessage += '\n\nSubtopics: $selectedSubtopics';
      }
    }

    // Add custom text if provided
    final customText = _customTextController.text.trim();
    if (customText.isNotEmpty) {
      if (finalMessage.isNotEmpty) {
        finalMessage += '\n\n';
      }
      finalMessage += customText;
    }

    if (finalMessage.isEmpty) {
      showTopSnackBar(
        context: context,
        message: 'Please select a topic or enter your message',
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
    });

    // Refresh coin balance first
    try {
      await coinProvider.refreshBalance();
    } catch (e) {
      debugPrint('Error refreshing coin balance: $e');
    }

    // Check coin balance BEFORE sending broadcast
    final currentBalance = coinProvider.balance;
    final requiredCoins = CoinCosts.broadcastMessage;

    if (currentBalance < requiredCoins) {
      setState(() {
        _isSending = false;
      });
      if (mounted) {
        showInsufficientCoinsSheet(
          context: context,
          requiredCoins: requiredCoins,
          availableCoins: currentBalance,
          message: 'You need $requiredCoins coin to send a broadcast message.',
        ).then((_) => coinProvider.refreshBalance());
      }
      return;
    }

    // Check for active chat BEFORE sending broadcast
    final hasActiveChat = await _checkForActiveChat();

    if (hasActiveChat) {
      setState(() {
        _isSending = false;
      });
      _showActiveChatExistsDialog();
      return;
    }

    try {
      // Send broadcast message
      _socketService.sendBroadcastMessage(content: finalMessage, type: 'TEXT');

      setState(() => _isSending = false);

      // Navigate to loading screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BroadcastLoadingScreen(
            message: finalMessage,
            currentUserId: _currentUserId!,
            accessToken: _accessToken,
            refreshToken: _refreshToken,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isSending = false;
      });
      showTopSnackBar(
        context: context,
        message: 'Failed to send broadcast: $e',
        backgroundColor: AppColors.error,
      );
    }
  }

  /// Check if user has an active chat before sending broadcast
  Future<bool> _checkForActiveChat() async {
    if (_accessToken == null || _refreshToken == null) {
      return false;
    }

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'cookie': 'accessToken=$_accessToken; refreshToken=$_refreshToken',
          },
        ),
      );

      // First try the active-chat endpoint
      try {
        final response = await dio.get(ApiEndpoints.chatActiveChat);
        if (response.statusCode == 200) {
          final data = response.data;
          // Check if there's an active chat returned
          if (data != null) {
            if (data is Map && data.isNotEmpty) {
              final status = data['status']?.toString().toUpperCase();
              if (status == 'ACTIVE') {
                return true;
              }
            }
            if (data is List && data.isNotEmpty) {
              for (final chat in data) {
                final status = chat['status']?.toString().toUpperCase();
                if (status == 'ACTIVE') {
                  return true;
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Active chat endpoint check failed: $e');
      }

      // Fallback: check conversations endpoint
      final response = await dio.get(ApiEndpoints.chatConversations);
      if (response.statusCode == 200) {
        final raw = response.data;
        List<dynamic> list = [];
        if (raw is List) {
          list = raw;
        } else if (raw is Map) {
          list = raw['chats'] ?? raw['conversations'] ?? raw['data'] ?? [];
        }

        for (final chat in list) {
          if (chat is Map) {
            final status = (chat['status']?.toString() ?? '').toUpperCase();
            if (status == 'ACTIVE') {
              return true;
            }
          }
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking for active chat: $e');
      return false;
    }
  }

  void _cancelBroadcast() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _resetConnectionAnimations();
    setState(() {
      _isWaiting = false;
      _selectedMessage = null;
      _selectedIndex = null;
      _expandedTopicIndex = null;
      _selectedSubtopicIndices.clear();
      _customTextController.clear();
      _onlineAstrologers = [];
    });
    // Close any expanded subtopics
    for (var controller in _subtopicAnimationControllers.values) {
      controller.reset();
    }
    // Note: The backend may need a cancel event - for now we just reset UI
  }

  void _toggleTopic(int index) {
    setState(() {
      if (_expandedTopicIndex == index) {
        // Collapse
        _expandedTopicIndex = null;
        _subtopicAnimationControllers[index]?.reverse();
      } else {
        // Collapse previous if any
        if (_expandedTopicIndex != null) {
          _subtopicAnimationControllers[_expandedTopicIndex]?.reverse();
        }
        // Expand new
        _expandedTopicIndex = index;
        _selectedIndex = index;
        _subtopicAnimationControllers[index]?.forward();
      }
    });
  }

  void _toggleSubtopic(int subtopicIndex) {
    setState(() {
      if (_selectedSubtopicIndices.contains(subtopicIndex)) {
        _selectedSubtopicIndices.remove(subtopicIndex);
      } else {
        _selectedSubtopicIndices.add(subtopicIndex);
      }
    });
  }

  void _startConnectionAnimations() {
    // Clear previous state
    _connected.clear();
    for (var controller in _lineAnimations.values) {
      controller.dispose();
    }
    _lineAnimations.clear();

    // Create animation controllers for each astrologer line
    for (int i = 0; i < _astrologers.length; i++) {
      _lineAnimations[i] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      );
    }

    // Start sequential connection animations
    _animateConnections();
  }

  Future<void> _animateConnections() async {
    final random = Random();
    final indices = List.generate(_astrologers.length, (i) => i)..shuffle(random);

    for (final index in indices) {
      if (!mounted || !_isWaiting) break;

      await Future.delayed(Duration(milliseconds: 500 + random.nextInt(1000)));

      if (!mounted || !_isWaiting) break;

      _connected.add(index);
      await _lineAnimations[index]?.forward();

      if (mounted) setState(() {});
    }
  }

  void _resetConnectionAnimations() {
    _connected.clear();
    for (var controller in _lineAnimations.values) {
      controller.dispose();
    }
    _lineAnimations.clear();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _connectionController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _rippleController.dispose();
    _customTextController.dispose();
    _customTextFocusNode.dispose();
    for (var controller in _subtopicAnimationControllers.values) {
      controller.dispose();
    }
    for (var controller in _lineAnimations.values) {
      controller.dispose();
    }

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
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          const StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  AppColors.cosmicPurple.withOpacity(0.3),
                  AppColors.cosmicPink.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
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
                child: CircularProgressIndicator(color: AppColors.cosmicPurple),
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
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    AppColors.purple300,
                    AppColors.pink300,
                    AppColors.red300,
                  ],
                ).createShader(bounds),
                child: const Text(
                  'Everyone Jyotish',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                'Broadcast to all astrologers',
                style: TextStyle(color: AppColors.textGray300, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: const Text(
            'What do you need help with?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select a topic to broadcast to all online astrologers',
          style: TextStyle(color: AppColors.textGray300, fontSize: 14),
        ),
        const SizedBox(height: 20),

        // Topics list with subtopics
        Expanded(
          child: ListView.separated(
            itemCount: defaultTopics.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final topic = defaultTopics[index];
              final isSelected = _selectedIndex == index;
              final isExpanded = _expandedTopicIndex == index;
              final animationController = _subtopicAnimationControllers[index]!;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () => _toggleTopic(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isSelected
                              ? [
                                  topic.color.withOpacity(0.3),
                                  topic.color.withOpacity(0.15),
                                ]
                              : [
                                  Colors.white.withOpacity(0.08),
                                  Colors.white.withOpacity(0.03),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? topic.color.withOpacity(0.6)
                              : Colors.white.withOpacity(0.1),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: topic.color.withOpacity(
                                isSelected ? 0.3 : 0.15,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              topic.icon,
                              color: isSelected
                                  ? topic.color
                                  : topic.color.withOpacity(0.7),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              topic.text,
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
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: isSelected
                                  ? topic.color
                                  : Colors.white.withOpacity(0.5),
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Subtopics with animation
                  SizeTransition(
                    sizeFactor: CurvedAnimation(
                      parent: animationController,
                      curve: Curves.easeInOut,
                    ),
                    child: ClipRect(
                      child: Container(
                        margin: const EdgeInsets.only(
                          top: 8,
                          left: 16,
                          right: 16,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: topic.color.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(topic.subtopics.length, (
                            subtopicIndex,
                          ) {
                            final isSubtopicSelected = _selectedSubtopicIndices
                                .contains(subtopicIndex);
                            return GestureDetector(
                              onTap: () => _toggleSubtopic(subtopicIndex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSubtopicSelected
                                      ? topic.color.withOpacity(0.3)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSubtopicSelected
                                        ? topic.color.withOpacity(0.6)
                                        : Colors.white.withOpacity(0.1),
                                    width: isSubtopicSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSubtopicSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: topic.color,
                                        size: 16,
                                      )
                                    else
                                      Icon(
                                        Icons.circle_outlined,
                                        color: Colors.white.withOpacity(0.3),
                                        size: 16,
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      topic.subtopics[subtopicIndex],
                                      style: TextStyle(
                                        color: isSubtopicSelected
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: isSubtopicSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),

        // Custom text field
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _customTextController,
                focusNode: _customTextFocusNode,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Or type your own message here...',
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Send button
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap:
                (_isSending ||
                    (_selectedIndex == null &&
                        _customTextController.text.trim().isEmpty))
                ? null
                : () {
                    _sendBroadcast();
                    // Auto navigate to waiting view (already handled by _isWaiting state)
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient:
                    (_selectedIndex != null ||
                        _customTextController.text.trim().isNotEmpty)
                    ? AppColors.cosmicHeroGradient
                    : null,
                color:
                    (_selectedIndex == null &&
                        _customTextController.text.trim().isEmpty)
                    ? Colors.white.withOpacity(0.1)
                    : null,
                borderRadius: BorderRadius.circular(16),
                boxShadow:
                    (_selectedIndex != null ||
                        _customTextController.text.trim().isNotEmpty)
                    ? [
                        BoxShadow(
                          color: AppColors.cosmicRed.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
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
                    Icon(
                      Icons.broadcast_on_personal,
                      color:
                          (_selectedIndex != null ||
                              _customTextController.text.trim().isNotEmpty)
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _isSending
                        ? 'Broadcasting...'
                        : (_selectedIndex != null ||
                              _customTextController.text.trim().isNotEmpty)
                        ? 'Broadcast Now'
                        : 'Select a topic or enter message',
                    style: TextStyle(
                      color:
                          (_selectedIndex != null ||
                              _customTextController.text.trim().isNotEmpty)
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
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
    );
  }

  Widget _buildWaitingView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // Connection animation with new network design
          _buildConnectionAnimation(),
          const SizedBox(height: 20),
          // Status info
          Text(
            _onlineAstrologers.isEmpty
                ? 'Finding Online Astrologers...'
                : 'Connecting to ${_onlineAstrologers.length} Online Astrologers',
            style: TextStyle(
              color: AppColors.textGray300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          // Status text + helper lines (waiting for astrologer)
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                AppColors.purple300,
                AppColors.pink300,
                AppColors.red300,
              ],
            ).createShader(bounds),
            child: const Text(
              'Waiting for an astrologer...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Connecting to astrologers...',
            style: TextStyle(
              color: AppColors.textGray300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Please be patient',
            style: TextStyle(
              color: AppColors.textGray300.withOpacity(0.9),
              fontSize: 12,
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
              border: Border.all(
                color: AppColors.cosmicPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: _remainingSeconds < 60
                      ? AppColors.cosmicRed
                      : AppColors.cosmicPurple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Expires in ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    color: _remainingSeconds < 60
                        ? AppColors.cosmicRed
                        : Colors.white,
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
                border: Border.all(
                  color: AppColors.cosmicPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.textGray300,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildConnectionAnimation() {
    final size = MediaQuery.of(context).size;
    final containerHeight = 320.0;

    return Container(
      width: size.width,
      height: containerHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0E27), Color(0xFF1A1A3E), Color(0xFF2E1A47)],
        ),
      ),
      child: Stack(
        children: [
          // Background grid pattern
          CustomPaint(
            size: Size(size.width, containerHeight),
            painter: GridPainter(),
          ),

          // 7 Particles within circular radius
          ...List.generate(
            7,
            (index) => _buildParticle(index, containerHeight),
          ),

          // Connection lines
          CustomPaint(
            size: Size(size.width, containerHeight),
            painter: NetworkPainter(
              astrologers: _astrologers,
              connected: _connected,
              lineAnimations: _lineAnimations,
              pulse: _pulseController.value,
              containerHeight: containerHeight,
            ),
          ),

          // Astrologer nodes
          ..._buildAstrologers(size.width, containerHeight),

          // Center node with Earth
          _centerNode(containerHeight),
        ],
      ),
    );
  }

  Widget _centerNode(double containerHeight) {
    return Positioned(
      left: 0,
      right: 0,
      top: (containerHeight - 100) / 2,
      child: Center(
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Multiple ripple effects
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) => Container(
                  width: 120 + (_rippleController.value * 100),
                  height: 120 + (_rippleController.value * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF667EEA).withOpacity(
                        (1 - _rippleController.value).clamp(0.0, 1.0) * 0.5,
                      ),
                      width: 2,
                    ),
                  ),
                ),
              ),

              // Second ripple with offset
              AnimatedBuilder(
                animation: _rippleController,
                builder: (_, __) {
                  final offset = (_rippleController.value + 0.5) % 1.0;
                  return Container(
                    width: 120 + (offset * 100),
                    height: 120 + (offset * 100),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF667EEA).withOpacity(
                          (1 - offset).clamp(0.0, 1.0) * 0.5,
                        ),
                        width: 2,
                      ),
                    ),
                  );
                },
              ),

              // Main node with glow and Earth icon
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                        Color(0xFF4A148C),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.6),
                        blurRadius: 30 + (_pulseController.value * 10),
                        spreadRadius: 5 + (_pulseController.value * 3),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🌍', style: TextStyle(fontSize: 50)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAstrologers(double screenWidth, double containerHeight) {
    return _astrologers.asMap().entries.map((e) {
      final index = e.key;
      final astrologer = e.value;
      final isConnecting = _lineAnimations[index]?.isAnimating ?? false;

      // Check if there's an online astrologer at this index with a profile photo
      final onlineAstrologer = index < _onlineAstrologers.length
          ? _onlineAstrologers[index]
          : null;
      final hasProfilePhoto = onlineAstrologer?.profilePhoto != null &&
          onlineAstrologer!.profilePhoto.isNotEmpty;

      return Positioned(
        left: screenWidth * astrologer.position.dx - 30,
        top: containerHeight * astrologer.position.dy - 30,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: hasProfilePhoto
                    ? null
                    : LinearGradient(
                        colors: isConnecting
                            ? [const Color(0xFFE53935), const Color(0xFFFF8C00)]
                            : [const Color(0xFF2A2A4C), const Color(0xFF1A1A3E)],
                      ),
                border: Border.all(
                  color: isConnecting ? const Color(0xFFFFD700) : const Color(0xFF4A4A6A),
                  width: isConnecting ? 3 : 2,
                ),
                boxShadow: isConnecting
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.7),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
              ),
              child: ClipOval(
                child: hasProfilePhoto
                    ? Image.network(
                        onlineAstrologer.profilePhoto,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(astrologer.avatar, style: const TextStyle(fontSize: 28)),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Text(astrologer.avatar, style: const TextStyle(fontSize: 28)),
                          );
                        },
                      )
                    : Center(
                        child: Text(astrologer.avatar, style: const TextStyle(fontSize: 28)),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnecting
                    ? const Color(0xFFFFD700).withOpacity(0.2)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnecting
                      ? const Color(0xFFFFD700).withOpacity(0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                // Show astrologer name if available, otherwise show specialty
                onlineAstrologer?.name ?? astrologer.specialty,
                style: TextStyle(
                  color: isConnecting ? const Color(0xFFFFD700) : Colors.white60,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildParticle(int index, double containerHeight) {
    final rand = Random(index + 100);

    // Generate random angle and distance within the circular radius
    final angle = rand.nextDouble() * 2 * pi;
    final distance = rand.nextDouble() * particleRadiusRatio;

    // Convert polar coordinates to cartesian
    final dx = 0.5 + (distance * cos(angle));
    final dy = 0.5 + (distance * sin(angle));

    final delay = rand.nextDouble();
    final size = 2.0 + rand.nextDouble() * 3;

    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, _) {
        final v = (_rotationController.value + delay) % 1.0;
        final opacity = (0.1 + sin(v * pi * 2) * 0.2).clamp(0.0, 1.0);

        return Positioned(
          left: MediaQuery.of(context).size.width * dx,
          top: containerHeight * dy,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF667EEA).withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Model class for astrologer nodes in the network animation
class AstrologerNode {
  final String name;
  final String avatar;
  final String specialty;
  final Offset position;

  AstrologerNode(this.name, this.avatar, this.specialty, this.position);
}

/// Custom painter for grid background pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for network connection lines
class NetworkPainter extends CustomPainter {
  final List<AstrologerNode> astrologers;
  final List<int> connected;
  final Map<int, AnimationController> lineAnimations;
  final double pulse;
  final double containerHeight;

  NetworkPainter({
    required this.astrologers,
    required this.connected,
    required this.lineAnimations,
    required this.pulse,
    required this.containerHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, containerHeight * 0.5);

    for (final i in connected) {
      final astrologer = astrologers[i];
      final astroPoint = Offset(
        size.width * astrologer.position.dx,
        containerHeight * astrologer.position.dy,
      );

      final lineProgress = lineAnimations[i]?.value ?? 0.0;
      final isAnimating = lineAnimations[i]?.isAnimating ?? false;

      final currentEnd = Offset.lerp(center, astroPoint, lineProgress)!;

      // Draw glow effect for animating line
      if (isAnimating || lineProgress >= 1.0) {
        final glowPaint = Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.3)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawLine(center, currentEnd, glowPaint);
      }

      // Main thin line
      final linePaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFD700).withOpacity(0.7);

      canvas.drawLine(center, currentEnd, linePaint);

      // Draw connection dot at the end of animating line
      if (isAnimating && lineProgress > 0.05) {
        // Outer glow
        final outerGlowPaint = Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(currentEnd, 8, outerGlowPaint);

        // Main dot
        final dotPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 5, dotPaint);

        // Inner bright dot
        final brightDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 2.5, brightDotPaint);
      }

      // Draw pulsing particles at completed connections
      if (lineProgress >= 1.0) {
        _drawPulsingParticle(canvas, astroPoint, pulse);
      }
    }
  }

  void _drawPulsingParticle(Canvas canvas, Offset position, double pulse) {
    final size = 4 + (pulse * 3);

    final particlePaint = Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, size, particlePaint);
  }

  @override
  bool shouldRepaint(covariant NetworkPainter old) => true;
}
