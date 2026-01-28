import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/show_top_snackBar.dart';
import '../../app_widgets/star_field_background.dart';
import '../models/active_user_model.dart';
import '../repository/chat_repository.dart';
import '../service/chat_service.dart';
import '../service/socket_service.dart';
import 'chat_screen.dart';

/// Model class for astrologer nodes in the network animation
class AstrologerNode {
  final String name;
  final String avatar;
  final String specialty;
  final Offset position;

  AstrologerNode(this.name, this.avatar, this.specialty, this.position);
}

/// Broadcast Loading Screen - Shows animated waiting view while connecting to astrologers
class BroadcastLoadingScreen extends StatefulWidget {
  final String message;
  final String currentUserId;
  final String? accessToken;
  final String? refreshToken;

  const BroadcastLoadingScreen({
    super.key,
    required this.message,
    required this.currentUserId,
    this.accessToken,
    this.refreshToken,
  });

  @override
  State<BroadcastLoadingScreen> createState() => _BroadcastLoadingScreenState();
}

class _BroadcastLoadingScreenState extends State<BroadcastLoadingScreen>
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ChatRepository _chatRepository = ChatRepository(ChatService());

  DateTime? _expiresAt;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  Timer? _replayTimer;
  int _remainingSeconds = 300; // 5 minutes

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late AnimationController _rippleController;
  final Map<int, AnimationController> _lineAnimations = {};
  final List<int> _connected = [];
  static const double particleRadiusRatio = 0.35;

  // Randomly generated astrologer nodes
  late List<AstrologerNode> _astrologers;

  List<ActiveAstrologerModel> _onlineAstrologers = [];

  @override
  void initState() {
    super.initState();
    _astrologers = _generateRandomAstrologers();
    _setupAnimations();
    _setupSocketListeners();
    _startBroadcast();
    _loadOnlineAstrologers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadOnlineAstrologers();
    });
  }

  List<AstrologerNode> _generateRandomAstrologers() {
    final random = Random();
    final avatars = [
      '🧙',
      '👳',
      '🧔',
      '🧘',
      '👨‍🦳',
      '🧓',
      '👴',
      '🧙‍♀️',
      '👩‍🦳',
      '🧑‍🦰',
      '👨‍🦱',
      '🧑‍🦲',
    ];
    final specialties = [
      'Vedic',
      'Numerology',
      'Palmistry',
      'Spiritual',
      'Vastu',
      'Gemology',
      'Kundli',
      'Feng Shui',
      'Reiki',
    ];

    final astrologers = <AstrologerNode>[];
    final positions = <Offset>[];

    // Create 7 astrologers with random positions
    const count = 7;
    const minDistance = 0.15; // Minimum distance between astrologers
    const minDistanceFromCenter = 0.28; // Minimum distance from center
    const maxAttempts = 100;

    for (int i = 0; i < count; i++) {
      double x = 0.5;
      double y = 0.5;
      bool validPosition = false;
      int attempts = 0;

      while (!validPosition && attempts < maxAttempts) {
        attempts++;
        x = 0.15 + random.nextDouble() * 0.7; // Between 0.15 and 0.85
        y = 0.15 + random.nextDouble() * 0.7; // Between 0.15 and 0.85

        // Check distance from center (0.5, 0.5)
        final distanceFromCenter = sqrt(pow(x - 0.5, 2) + pow(y - 0.5, 2));

        // Ensure not too close to center
        if (distanceFromCenter < minDistanceFromCenter) {
          continue;
        }

        // Check distance from all existing positions
        bool tooClose = false;
        for (final pos in positions) {
          final distance = sqrt(pow(x - pos.dx, 2) + pow(y - pos.dy, 2));
          if (distance < minDistance) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          validPosition = true;
        }
      }

      final position = Offset(x, y);
      positions.add(position);

      astrologers.add(
        AstrologerNode(
          'Astrologer ${i + 1}',
          avatars[random.nextInt(avatars.length)],
          specialties[random.nextInt(specialties.length)],
          position,
        ),
      );
    }

    return astrologers;
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<void> _loadOnlineAstrologers() async {
    try {
      final astrologers = await _chatRepository.getActiveAstrologers();
      if (mounted) {
        setState(() {
          _onlineAstrologers = astrologers
              .where((a) => a.isOnline)
              .take(7)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading online astrologers: $e');
    }
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
      _refreshTimer?.cancel();
      _replayTimer?.cancel();

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
              currentUserId: widget.currentUserId,
              accessToken: widget.accessToken,
              refreshToken: widget.refreshToken,
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
      _refreshTimer?.cancel();
      _replayTimer?.cancel();
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: 'No astrologer accepted your request. Please try again.',
          backgroundColor: AppColors.error,
        );
        Navigator.pop(context);
      }
    });

    // Listen for broadcast errors
    _socketService.onBroadcastError((data) {
      debugPrint('Broadcast error: $data');
      _countdownTimer?.cancel();
      _refreshTimer?.cancel();
      _replayTimer?.cancel();
      if (mounted) {
        final errorMessage = data['message'] ?? 'An error occurred';
        showTopSnackBar(
          context: context,
          message: errorMessage,
          backgroundColor: AppColors.error,
        );
        Navigator.pop(context);
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

  void _startBroadcast() {
    // Connect to all astrologers at once
    _connectToAllAstrologers();

    // Replay every 10 seconds
    _replayTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _connectToAllAstrologers();
    });
  }

  void _connectToAllAstrologers() {
    setState(() {
      _connected.clear();

      // Dispose old controllers
      for (var controller in _lineAnimations.values) {
        controller.dispose();
      }
      _lineAnimations.clear();

      // Create new connections for all astrologers
      for (int i = 0; i < _astrologers.length; i++) {
        _connected.add(i);

        final lineController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 10), // 10 seconds connection time
        );

        _lineAnimations[i] = lineController;

        // Start animation
        lineController.forward();
      }
    });
  }

  void _cancelBroadcast() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _replayTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    _replayTimer?.cancel();
    _pulseController.dispose();
    _rotationController.dispose();
    _rippleController.dispose();
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
    final size = MediaQuery.of(context).size;
    final broadcastHeight = size.height * 0.6;

    return Scaffold(
      backgroundColor: AppColors.primaryBlack,
      body: Stack(
        children: [
          // Star field background
          const StarFieldBackground(),
          // Gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.7),
                  AppColors.cosmicPurple.withValues(alpha: 0.3),
                  AppColors.cosmicPink.withValues(alpha: 0.2),
                  Colors.black.withValues(alpha: 0.9),
                ],
                stops: const [0.0, 0.3, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Top 60% - Broadcast Animation Area
                SizedBox(
                  height: broadcastHeight,
                  child: Stack(
                    children: [
                      // Background grid pattern
                      CustomPaint(
                        size: Size(size.width, broadcastHeight),
                        painter: GridPainter(),
                      ),

                      // 7 Particles within circular radius
                      ...List.generate(
                        7,
                        (index) => _buildParticle(index, broadcastHeight),
                      ),

                      // Connection lines
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) => CustomPaint(
                          size: Size(size.width, broadcastHeight),
                          painter: NetworkPainter(
                            astrologers: _astrologers,
                            connected: _connected,
                            lineAnimations: _lineAnimations,
                            pulse: _pulseController.value,
                            containerHeight: broadcastHeight,
                          ),
                        ),
                      ),

                      // Astrologer nodes
                      ..._buildAstrologers(size.width, broadcastHeight),

                      // Center node with Earth
                      _centerNode(broadcastHeight),

                      // Top header
                      _topHeader(),
                    ],
                  ),
                ),

                Expanded(child: _bottomTextArea()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topHeader() {
    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            'GLOBAL BROADCAST',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Color(0xFF667EEA),
                  Colors.transparent,
                ],
              ),
            ),
          ),
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
                      color: const Color(0xFF667EEA).withValues(
                        alpha:
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
                        color: const Color(
                          0xFF667EEA,
                        ).withValues(alpha: (1 - offset).clamp(0.0, 1.0) * 0.5),
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
                        color: const Color(0xFF667EEA).withValues(alpha: 0.6),
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
      final hasProfilePhoto =
          onlineAstrologer?.profilePhoto != null &&
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
                            : [
                                const Color(0xFF2A2A4C),
                                const Color(0xFF1A1A3E),
                              ],
                      ),
                border: Border.all(
                  color: isConnecting
                      ? const Color(0xFFFFD700)
                      : const Color(0xFF4A4A6A),
                  width: isConnecting ? 3 : 2,
                ),
                boxShadow: isConnecting
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                          blurRadius: 20,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
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
                          child: Text(
                            astrologer.avatar,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: Text(
                              astrologer.avatar,
                              style: const TextStyle(fontSize: 28),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Text(
                          astrologer.avatar,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isConnecting
                    ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isConnecting
                      ? const Color(0xFFFFD700).withValues(alpha: 0.3)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Text(
                onlineAstrologer?.name ?? astrologer.specialty,
                style: TextStyle(
                  color: isConnecting
                      ? const Color(0xFFFFD700)
                      : Colors.white60,
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

    final angle = rand.nextDouble() * 2 * pi;
    final distance = rand.nextDouble() * particleRadiusRatio;

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
                    color: const Color(0xFF667EEA).withValues(alpha: 0.5),
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

  Widget _bottomTextArea() {
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            // Status info
            Text(
              _onlineAstrologers.isEmpty
                  ? 'Finding Online Astrologers...'
                  : 'Connecting to ${_onlineAstrologers.length} Online Astrologers',
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Main status text
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
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
            const Text(
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
                color: AppColors.textGray300.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            // Timer display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.cosmicPurple.withValues(alpha: 0.3),
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
            const SizedBox(height: 20),
            // Cancel button
            GestureDetector(
              onTap: _cancelBroadcast,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cosmicPurple.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textGray300,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for grid background pattern
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }

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
      if (i >= astrologers.length) continue;

      final astrologer = astrologers[i];
      final astroPoint = Offset(
        size.width * astrologer.position.dx,
        containerHeight * astrologer.position.dy,
      );

      final lineProgress = lineAnimations[i]?.value ?? 0.0;
      final isAnimating = lineAnimations[i]?.isAnimating ?? false;

      final currentEnd = Offset.lerp(center, astroPoint, lineProgress)!;

      if (isAnimating || lineProgress >= 1.0) {
        final glowPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.3)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawLine(center, currentEnd, glowPaint);
      }

      final linePaint = Paint()
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFD700).withValues(alpha: 0.7);

      canvas.drawLine(center, currentEnd, linePaint);

      if (isAnimating && lineProgress > 0.05) {
        final outerGlowPaint = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.6)
          ..style = PaintingStyle.fill
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

        canvas.drawCircle(currentEnd, 8, outerGlowPaint);

        final dotPaint = Paint()
          ..color = const Color(0xFFFFD700)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 5, dotPaint);

        final brightDotPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

        canvas.drawCircle(currentEnd, 2.5, brightDotPaint);
      }

      if (lineProgress >= 1.0) {
        _drawPulsingParticle(canvas, astroPoint, pulse);
      }
    }
  }

  void _drawPulsingParticle(Canvas canvas, Offset position, double pulse) {
    final size = 4 + (pulse * 3);

    final particlePaint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawCircle(position, size, particlePaint);
  }

  @override
  bool shouldRepaint(covariant NetworkPainter old) => true;
}
