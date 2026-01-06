import 'dart:convert';

import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/payment/screens/broadcast_waiting_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BroadcastPage extends StatefulWidget {
  const BroadcastPage({super.key});

  @override
  State<BroadcastPage> createState() => _BroadcastPageState();
}

class _BroadcastPageState extends State<BroadcastPage> {
  final SocketService _socketService = SocketService();
  bool _isSending = false;
  int _selectedMessageIndex = 0;

  final List<String> _defaultMessages = [
    "Namaste! I'm seeking astrological guidance. I would like to discuss about my life path and receive insights about my future. Please connect with me if you're available.",
    "Hello, I need guidance regarding my career and professional growth. Could you analyze my chart and suggest the best path forward?",
    "I'm experiencing challenges in my relationships and would appreciate some astrological insights to improve my personal connections.",
    "Looking for predictions about my financial prospects and investment opportunities based on planetary positions.",
    "I'm planning an important event and need muhurta consultation for auspicious timing. Please help me choose the right date.",
    "Concerned about health issues, seeking remedies and planetary guidance for better well-being and healing.",
    "Want to understand my karmic patterns and past life influences affecting my current situation.",
    "Seeking marriage compatibility analysis and guidance for a harmonious married life.",
    "Need guidance on education and career choices for my child based on their horoscope.",
    "Looking for spiritual guidance and remedies to overcome obstacles in my spiritual journey.",
  ];

  @override
  void initState() {
    super.initState();
    _initializeSocket();
  }

  Future<void> _initializeSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken != null && refreshToken != null) {
      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
    }
  }

  /// Decode JWT token to get user info
  Map<String, dynamic>? _decodeJwt(String token) {
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

  Future<void> _sendBroadcast() async {
    final message = _defaultMessages[_selectedMessageIndex].trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a message'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null) {
        throw Exception('Not authenticated');
      }

      final decodedToken = _decodeJwt(accessToken);
      final currentUserId = decodedToken?['id'] ?? '';
      final currentUserName = decodedToken?['name'] ?? 'User';

      // Send broadcast via socket
      _socketService.sendBroadcastMessage(content: message);

      if (mounted) {
        // Navigate to waiting page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => BroadcastWaitingPage(
              message: message,
              currentUserId: currentUserId,
              currentUserName: currentUserName,
              accessToken: accessToken,
              refreshToken: refreshToken,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  void dispose() {
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
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildInfoCard(),
                  SizedBox(height: 24),
                  _buildMessageSection(),
                  Spacer(),
                  _buildSendButton(),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_isSending)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryPurple),
                    SizedBox(height: 16),
                    Text(
                      'Sending broadcast...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
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
        SizedBox(width: 16),
        Text(
          'Broadcast Message',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
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
            Colors.orange.withOpacity(0.2),
            Colors.deepOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange, Colors.deepOrange],
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

  Widget _buildMessageSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Your Message',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedMessageIndex = 0;
                  });
                },
                child: Text(
                  'Reset to First',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.15),
                    AppColors.deepPurple.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Selected message display
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primaryPurple.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_border,
                              color: Colors.orange,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Selected Message',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          _defaultMessages[_selectedMessageIndex],
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Message selection
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      itemCount: _defaultMessages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageOption(index);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageOption(int index) {
    bool isSelected = _selectedMessageIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMessageIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryPurple.withOpacity(0.2)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryPurple.withOpacity(0.6)
                : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.primaryPurple
                      : Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                color: isSelected
                    ? AppColors.primaryPurple
                    : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getMessageTitle(index),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    _defaultMessages[index],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMessageTitle(int index) {
    List<String> titles = [
      'General Guidance',
      'Career Advice',
      'Relationship Issues',
      'Financial Predictions',
      'Muhurta Consultation',
      'Health Concerns',
      'Karmic Patterns',
      'Marriage Compatibility',
      'Child\'s Future',
      'Spiritual Guidance',
    ];
    return titles[index];
  }

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isSending ? null : _sendBroadcast,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.orange, Colors.deepOrange]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_rounded, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              'Send Broadcast',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
