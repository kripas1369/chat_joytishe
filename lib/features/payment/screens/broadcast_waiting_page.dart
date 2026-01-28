import 'dart:async';
import 'dart:math';

import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/repository/chat_repository.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:flutter/material.dart';

class BroadcastWaitingPage extends StatefulWidget {
  final String message;
  final String currentUserId;
  final String currentUserName;
  final String? accessToken;
  final String? refreshToken;

  const BroadcastWaitingPage({
    super.key,
    required this.message,
    required this.currentUserId,
    required this.currentUserName,
    this.accessToken,
    this.refreshToken,
  });

  @override
  State<BroadcastWaitingPage> createState() => _BroadcastWaitingPageState();
}

class _BroadcastWaitingPageState extends State<BroadcastWaitingPage>
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final ChatRepository _chatRepository = ChatRepository(ChatService());

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _connectionController;
  late AnimationController _rotationController;
  late AnimationController _starController;

  bool _isWaiting = true;
  String _statusMessage = 'Sending broadcast to all astrologers...';
  List<ActiveAstrologerModel> _onlineAstrologers = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupSocketListeners();
    _loadOnlineAstrologers();

    // Refresh online astrologers every 3 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (_) {
      _loadOnlineAstrologers();
    });

    // Update status after short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted && _isWaiting) {
        setState(() {
          _statusMessage = 'Connecting to available astrologers...';
        });
      }
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _connectionController = AnimationController(
      duration: Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _rotationController = AnimationController(
      duration: Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _starController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
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

  void _setupSocketListeners() {
    // Listen for broadcast accepted
    _socketService.onBroadcastAccepted((data) {
      debugPrint('Broadcast accepted: $data');

      if (mounted) {
        final chat = data['chat'];
        final astrologer = data['astrologer'];

        final astrologerId = astrologer?['id'] ?? data['astrologerId'] ?? '';
        final astrologerName =
            astrologer?['name'] ?? data['astrologerName'] ?? 'Astrologer';
        final astrologerPhoto =
            astrologer?['profilePhoto'] ?? data['astrologerPhoto'];
        final chatId =
            chat?['id'] ??
            data['chatId'] ??
            'chat_${widget.currentUserId}_$astrologerId';

        setState(() {
          _isWaiting = false;
          _statusMessage = '$astrologerName accepted your request!';
        });

        Future.delayed(Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chatId,
                  otherUserId: astrologerId,
                  otherUserName: astrologerName,
                  otherUserPhoto: astrologerPhoto,
                  currentUserId: widget.currentUserId,
                  accessToken: widget.accessToken,
                  refreshToken: widget.refreshToken,
                  isOnline: true,
                ),
              ),
            );
          }
        });
      }
    });

    // Listen for broadcast errors
    _socketService.onBroadcastError((data) {
      if (mounted) {
        setState(() {
          _isWaiting = false;
          _statusMessage = data['message'] ?? 'Broadcast failed';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_statusMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    // Listen for broadcast expired
    _socketService.onBroadcastExpired((data) {
      if (mounted) {
        setState(() {
          _isWaiting = false;
          _statusMessage =
              'No astrologer accepted your request. Please try again.';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast expired - no astrologer responded'),
            backgroundColor: AppColors.error,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _cancelBroadcast();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _connectionController.dispose();
    _rotationController.dispose();
    _starController.dispose();
    _socketService.offBroadcastAccepted();
    _socketService.offBroadcastError();
    _socketService.offBroadcastExpired();
    super.dispose();
  }

  void _cancelBroadcast() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.pushReplacementNamed(context, '/home_screen_client');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _cancelBroadcast();
        return false;
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // Star field background
            const StarFieldBackground(),

            // Cosmic gradient overlay
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
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    _buildHeader(),
                    SizedBox(height: 20),
                    _buildConnectionAnimation(),
                    SizedBox(height: 20),
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
                    SizedBox(height: 40),
                    _buildStatusText(),
                    SizedBox(height: 24),
                    _buildMessagePreview(),
                    SizedBox(height: 40),
                    _buildCancelButton(),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
      ).createShader(bounds),
      child: Text(
        'Connecting to Astrologers',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
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
      width: 350,
      height: 350,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _connectionController,
          _rotationController,
          _starController,
        ]),
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Enhanced spider web network with 3D depth
              CustomPaint(
                size: const Size(350, 350),
                painter: EnhancedSpiderWebPainter(
                  progress: _connectionController.value,
                  rotation: _rotationController.value,
                  pulseValue: _pulseAnimation.value,
                  color: AppColors.cosmicPurple,
                  astrologerCount: astrologerCount,
                ),
              ),

              // 3D moving astrologer avatars - flowing from one to another
              ...List.generate(astrologerCount, (index) {
                // Create flowing motion - astrologers move in sequence
                final flowProgress =
                    ((_connectionController.value + index * 0.15) % 1.0);
                final baseAngle = (index * 2 * pi / astrologerCount) - (pi / 2);

                // 3D circular path with depth
                final radius = 140.0;
                final depthOffset =
                    cos(flowProgress * 2 * pi) * 20; // 3D depth effect
                final currentRadius = radius + depthOffset;

                // Rotation with flow
                final rotationOffset = _rotationController.value * 0.3;
                final angle = baseAngle + rotationOffset + (flowProgress * 0.2);

                final x = cos(angle) * currentRadius;
                final y = sin(angle) * currentRadius;

                // 3D scale based on depth
                final zDepth = (1.0 - (depthOffset / 40).abs()).clamp(0.5, 1.0);
                final scale = (0.7 + zDepth * 0.3) * _pulseAnimation.value;

                // Opacity based on depth
                final opacity = 0.6 + (zDepth * 0.4);

                final astrologer = index < displayAstrologers.length
                    ? displayAstrologers[index]
                    : null;

                return Positioned(
                  left: 175 + x - 35,
                  top: 175 + y - 35,
                  child: Transform.scale(
                    scale: scale,
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001) // Perspective
                        ..rotateX(flowProgress * 0.3) // 3D rotation
                        ..rotateY(flowProgress * 0.2),
                      alignment: Alignment.center,
                      child: Opacity(
                        opacity: opacity,
                        child: GestureDetector(
                          onTap: astrologer != null
                              ? () {
                                  // Handle tap if needed
                                }
                              : null,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.cosmicPurple.withOpacity(
                                    0.9 * zDepth,
                                  ),
                                  AppColors.cosmicPink.withOpacity(
                                    0.7 * zDepth,
                                  ),
                                  AppColors.cosmicRed.withOpacity(0.5 * zDepth),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.cosmicPurple.withOpacity(
                                  0.9 * zDepth,
                                ),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPurple.withOpacity(
                                    0.7 * zDepth,
                                  ),
                                  blurRadius: 20 * zDepth,
                                  spreadRadius: 4 * zDepth,
                                ),
                                BoxShadow(
                                  color: AppColors.cosmicPink.withOpacity(
                                    0.4 * zDepth,
                                  ),
                                  blurRadius: 30 * zDepth,
                                  spreadRadius: 2 * zDepth,
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
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null)
                                              return child;
                                            return Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                color: AppColors.cosmicPurple,
                                                strokeWidth: 2,
                                              ),
                                            );
                                          },
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 35,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 35,
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Center pulsing 3D Earth hub
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow behind earth
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: AppColors.cosmicPrimaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cosmicPurple.withOpacity(0.7),
                            blurRadius: 35,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: AppColors.cosmicPink.withOpacity(0.5),
                            blurRadius: 50,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    // Rotating 3D-style earth (icon + gradients)
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_rotationController.value * 2 * pi),
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.blue.shade900,
                              Colors.blue.shade600,
                              Colors.lightBlue.shade300,
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.6),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.cyanAccent.withOpacity(0.7),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.public,
                          color: Colors.white.withOpacity(0.95),
                          size: 46,
                        ),
                      ),
                    ),
                    // Check icon overlay when connected
                    if (!_isWaiting)
                      const Positioned(
                        bottom: 8,
                        right: 14,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.green,
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [AppColors.purple300, AppColors.pink300, AppColors.red300],
          ).createShader(bounds),
          child: Text(
            _statusMessage,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        if (_isWaiting) ...[SizedBox(height: 16), _buildLoadingDots()],
      ],
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _connectionController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final value = ((_connectionController.value + delay) % 1.0);
            final opacity = (sin(value * pi)).clamp(0.0, 1.0);

            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.3 + opacity * 0.7),
                    AppColors.cosmicPink.withOpacity(0.3 + opacity * 0.7),
                  ],
                ),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMessagePreview() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cosmicPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: AppColors.purple400, size: 20),
              SizedBox(width: 8),
              Text(
                'Your Message',
                style: TextStyle(
                  color: AppColors.textGray300,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            widget.message,
            style: TextStyle(
              color: AppColors.textGray200,
              fontSize: 14,
              height: 1.4,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return GestureDetector(
      onTap: _cancelBroadcast,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cosmicPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: AppColors.textGray300, size: 20),
            SizedBox(width: 8),
            Text(
              'Cancel & Go Back',
              style: TextStyle(
                color: AppColors.textGray300,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced spider web painter with 3D connection flow
class EnhancedSpiderWebPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final double pulseValue;
  final Color color;
  final int astrologerCount;

  EnhancedSpiderWebPainter({
    required this.progress,
    required this.rotation,
    required this.pulseValue,
    required this.color,
    required this.astrologerCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 25;
    final nodeCount = astrologerCount;

    // Create animated concentric circles with 3D effect
    final rings = 5;
    for (int ring = 1; ring <= rings; ring++) {
      final ringRadius = (maxRadius / rings) * ring;
      final ringProgress = (progress + ring * 0.08) % 1.0;
      final opacity =
          (0.15 + (ringProgress * 0.25)).clamp(0.0, 0.4) * pulseValue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + (ring * 0.2)
        ..color = color.withOpacity(opacity);

      canvas.drawCircle(center, ringRadius, paint);
    }

    // Draw radial lines (spider web spokes) with flowing animation
    for (int i = 0; i < nodeCount; i++) {
      final baseAngle = (i * 2 * pi / nodeCount) - (pi / 2);
      final angle = baseAngle + (rotation * 0.3);
      final lineProgress = (progress + i * 0.12) % 1.0;
      final opacity = (0.4 + (lineProgress * 0.5)).clamp(0.0, 0.9) * pulseValue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..color = color.withOpacity(opacity);

      final endPoint = Offset(
        center.dx + maxRadius * cos(angle),
        center.dy + maxRadius * sin(angle),
      );

      canvas.drawLine(center, endPoint, paint);
    }

    // Draw flowing connection lines between adjacent nodes (series connection)
    for (int i = 0; i < nodeCount; i++) {
      final nextIndex = (i + 1) % nodeCount;
      final baseAngle1 = (i * 2 * pi / nodeCount) - (pi / 2);
      final baseAngle2 = (nextIndex * 2 * pi / nodeCount) - (pi / 2);
      final angle1 = baseAngle1 + (rotation * 0.3);
      final angle2 = baseAngle2 + (rotation * 0.3);

      final nodeRadius = maxRadius * 0.9;
      final node1 = Offset(
        center.dx + nodeRadius * cos(angle1),
        center.dy + nodeRadius * sin(angle1),
      );
      final node2 = Offset(
        center.dx + nodeRadius * cos(angle2),
        center.dy + nodeRadius * sin(angle2),
      );

      // Animated connection line with flowing effect
      final connectionProgress = (progress + i * 0.2) % 1.0;
      final opacity =
          (0.3 + (connectionProgress * 0.5)).clamp(0.0, 0.8) * pulseValue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = color.withOpacity(opacity);

      canvas.drawLine(node1, node2, paint);

      // Draw flowing particle along the connection line
      final particleT = connectionProgress;
      final particleX = node1.dx + (node2.dx - node1.dx) * particleT;
      final particleY = node1.dy + (node2.dy - node1.dy) * particleT;

      final particlePaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.cosmicPink.withOpacity(opacity * 0.8);

      canvas.drawCircle(
        Offset(particleX, particleY),
        4 * pulseValue,
        particlePaint,
      );
    }

    // Draw all-to-all connections for complete web
    final nodes = List.generate(nodeCount, (index) {
      final baseAngle = (index * 2 * pi / nodeCount) - (pi / 2);
      final angle = baseAngle + (rotation * 0.3);
      final nodeRadius = maxRadius * 0.85;
      return Offset(
        center.dx + nodeRadius * cos(angle),
        center.dy + nodeRadius * sin(angle),
      );
    });

    // Draw cross-connections
    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 2; j < nodes.length; j++) {
        final distance = (nodes[i] - nodes[j]).distance;
        if (distance < maxRadius * 1.3) {
          final lineProgress = (progress + (i + j) * 0.08) % 1.0;
          final opacity =
              (0.1 + (lineProgress * 0.2)).clamp(0.0, 0.3) * pulseValue;

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
      ..color = color.withOpacity(0.5 + (progress * 0.3));
    canvas.drawCircle(center, 8 * pulseValue, centerPaint);
  }

  @override
  bool shouldRepaint(covariant EnhancedSpiderWebPainter oldDelegate) {
    return progress != oldDelegate.progress ||
        rotation != oldDelegate.rotation ||
        pulseValue != oldDelegate.pulseValue ||
        astrologerCount != oldDelegate.astrologerCount;
  }
}
