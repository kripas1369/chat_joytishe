import 'dart:async';

import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/screens/chat_screen.dart';
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _dotController;

  bool _isWaiting = true;
  String _statusMessage = 'Sending broadcast to all astrologers...';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _setupSocketListeners();

    // Update status after short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted && _isWaiting) {
        setState(() {
          _statusMessage = 'Waiting for an astrologer to respond...';
        });
      }
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  void _setupSocketListeners() {
    // Listen for broadcast accepted
    _socketService.onBroadcastAccepted((data) {
      debugPrint('Broadcast accepted: $data');

      if (mounted) {
        // Parse data according to API response format
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

        // Navigate to chat after short delay
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

    // Listen for broadcast expired (5 min timeout)
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

        // Navigate back after short delay
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
    _pulseController.dispose();
    _dotController.dispose();
    // Clean up socket listeners
    _socketService.offBroadcastAccepted();
    _socketService.offBroadcastError();
    _socketService.offBroadcastExpired();
    super.dispose();
  }

  void _cancelBroadcast() {
    // Cancel and go back
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
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(height: 40),
                    _buildHeader(),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPulsingIndicator(),
                            SizedBox(height: 40),
                            _buildStatusText(),
                            SizedBox(height: 24),
                            _buildMessagePreview(),
                          ],
                        ),
                      ),
                    ),
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
    return Text(
      'Broadcast Sent',
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPulsingIndicator() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer rings
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.2),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              // Center icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange, Colors.deepOrange],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isWaiting
                      ? Icons.campaign_rounded
                      : Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusText() {
    return Column(
      children: [
        Text(
          _statusMessage,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        if (_isWaiting) ...[SizedBox(height: 16), _buildLoadingDots()],
      ],
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.3;
            final value = ((_dotController.value + delay) % 1.0 * 2 - 1).abs();
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.3 + value * 0.7),
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
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote, color: Colors.white38, size: 20),
              SizedBox(width: 8),
              Text(
                'Your Message',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            widget.message,
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
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
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.close, color: Colors.white70, size: 20),
            SizedBox(width: 8),
            Text(
              'Cancel & Go Back',
              style: TextStyle(
                color: Colors.white70,
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
