import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
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

  List<ActiveAstrologerModel> _onlineAstrologers = [];

  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;

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
          errorMessage =
              'You already have an active chat. Please end it first.';
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
      _isWaiting = true;
      _selectedMessage = finalMessage;
    });

    // Load online astrologers when waiting starts
    _loadOnlineAstrologers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadOnlineAstrologers();
    });

    try {
      _socketService.sendBroadcastMessage(content: finalMessage, type: 'TEXT');
      setState(() => _isSending = false);
    } catch (e) {
      _refreshTimer?.cancel();
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
    _refreshTimer?.cancel();
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

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _connectionController.dispose();
    _rotationController.dispose();
    _waveController.dispose();
    _customTextController.dispose();
    _customTextFocusNode.dispose();
    for (var controller in _subtopicAnimationControllers.values) {
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
          // Connection animation with spider web and astrologers
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
          // Status text
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
            'Your message has been sent to all online astrologers',
            style: TextStyle(color: AppColors.textGray300, fontSize: 14),
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
    // Use online astrologers or create placeholder positions
    final astrologerCount = _onlineAstrologers.isEmpty
        ? 6
        : _onlineAstrologers.length;
    final displayAstrologers = _onlineAstrologers.isEmpty
        ? List.generate(6, (i) => null)
        : _onlineAstrologers.take(6).toList();

    return SizedBox(
      width: 320,
      height: 320,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _connectionController,
          _rotationController,
          _waveController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Spider web network
              CustomPaint(
                size: const Size(320, 320),
                painter: SpiderWebPainter(
                  progress: _connectionController.value,
                  rotation: _rotationController.value,
                  color: AppColors.cosmicPurple,
                ),
              ),

              // Astrologer avatars positioned around the web
              ...List.generate(astrologerCount, (index) {
                final angle = (index * 2 * pi / astrologerCount) - (pi / 2);
                final radius = 130.0;
                final waveOffset =
                    sin((_waveAnimation.value + index * 0.3) * 2 * pi) * 8;
                final currentRadius = radius + waveOffset;

                final x =
                    cos(angle + _rotationController.value * 0.5) *
                    currentRadius;
                final y =
                    sin(angle + _rotationController.value * 0.5) *
                    currentRadius;

                final astrologer = index < displayAstrologers.length
                    ? displayAstrologers[index]
                    : null;

                return Positioned(
                  left: 160 + x - 30,
                  top: 160 + y - 30,
                  child: Transform.scale(
                    scale:
                        0.8 +
                        (sin((_waveAnimation.value + index * 0.2) * 2 * pi) *
                            0.2),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.cosmicPurple.withOpacity(0.8),
                            AppColors.cosmicPink.withOpacity(0.6),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.cosmicPurple.withOpacity(0.8),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cosmicPurple.withOpacity(0.6),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child:
                            astrologer?.profilePhoto != null &&
                                astrologer!.profilePhoto.isNotEmpty
                            ? Image.network(
                                astrologer.profilePhoto,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                    ),
                  ),
                );
              }),

              // Center pulsing icon
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: AppColors.cosmicPrimaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cosmicPurple.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.wifi_find_rounded,
                    color: Colors.white,
                    size: 45,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Custom painter for spider web network animation
class SpiderWebPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final Color color;

  SpiderWebPainter({
    required this.progress,
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 20;
    const nodeCount = 8; // Number of astrologer positions

    // Create concentric circles (spider web rings)
    final rings = 4;
    for (int ring = 1; ring <= rings; ring++) {
      final ringRadius = (maxRadius / rings) * ring;
      final ringProgress = (progress + ring * 0.1) % 1.0;
      final opacity = (0.2 + (ringProgress * 0.3)).clamp(0.0, 0.5);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withOpacity(opacity);

      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw radial lines (spider web spokes)
    for (int i = 0; i < nodeCount; i++) {
      final angle = (i * 2 * pi / nodeCount) - (pi / 2) + (rotation * 0.3);
      final lineProgress = (progress + i * 0.15) % 1.0;
      final opacity = (0.3 + (lineProgress * 0.4)).clamp(0.0, 0.7);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = color.withOpacity(opacity);

      final endPoint = Offset(
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );

      canvas.drawLine(center, endPoint, paint);
    }

    // Draw connecting lines between nodes (web pattern)
    final nodes = List.generate(nodeCount, (index) {
      final angle = (index * 2 * pi / nodeCount) - (pi / 2) + (rotation * 0.3);
      final nodeRadius = maxRadius * 0.85;
      return Offset(
        center.dx + nodeRadius * cos(angle),
        center.dy + nodeRadius * sin(angle),
      );
    });

    // Draw web connections
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < maxRadius * 1.2) {
          final lineProgress = (progress + (i + j) * 0.1) % 1.0;
          final opacity = (0.15 + (lineProgress * 0.25)).clamp(0.0, 0.4);

          final paint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color.withOpacity(opacity);

          canvas.drawLine(nodes[i], nodes[j], paint);
        }
      }
    }

    // Draw pulsing center node
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(0.4 + (progress * 0.3));
    canvas.drawCircle(center, 6, centerPaint);
  }

  @override
  bool shouldRepaint(covariant SpiderWebPainter oldDelegate) {
    return progress != oldDelegate.progress || rotation != oldDelegate.rotation;
  }
}
