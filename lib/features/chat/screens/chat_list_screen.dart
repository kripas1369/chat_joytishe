import 'dart:convert';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/star_field_background.dart';
import '../bloc/chat_bloc.dart';
import '../bloc/chat_events.dart';
import '../bloc/chat_states.dart';
import '../models/active_user_model.dart';
import '../repository/chat_repository.dart';
import '../service/chat_service.dart';
import '../service/socket_service.dart';
import '../widgets/profile_status.dart';
import 'broadcast_chat_screen.dart';
import 'chat_screen.dart';

/// Decode JWT token to get user info
Map<String, dynamic>? decodeJwt(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    String payload = parts[1];
    // Add padding if needed
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

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatBloc(chatRepository: ChatRepository(ChatService()))
            ..add(FetchActiveUsersEvent()),
      child: ChatListScreenContent(),
    );
  }
}

class ChatListScreenContent extends StatefulWidget {
  const ChatListScreenContent({super.key});

  @override
  State<ChatListScreenContent> createState() => _ChatListScreenContentState();
}

class _ChatListScreenContentState extends State<ChatListScreenContent> {
  final SocketService _socketService = SocketService();
  final CoinService _coinService = CoinService();
  bool _isConnecting = false;
  int _coinBalance = 0;

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
  }

  Future<void> _loadCoinBalance() async {
    final balance = await _coinService.getBalance();
    if (mounted) {
      setState(() => _coinBalance = balance);
    }
  }

  /// Show chat type selection dialog
  Future<void> _showChatTypeDialog(ActiveAstrologerModel astrologer) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.cardDark, AppColors.backgroundDark],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: AppColors.primaryPurple.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Chat with ${astrologer.name}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose how you want to connect',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // Single Chat Option (Direct chat with payment)
            _buildChatOptionTile(
              icon: Icons.chat_bubble_rounded,
              title: 'Single Chat',
              description: 'Start chatting now',
              color: Colors.green,
              onTap: () => Navigator.pop(context, 'single'),
            ),
            const SizedBox(height: 12),

            // Broadcast Message Option
            _buildChatOptionTile(
              icon: Icons.broadcast_on_personal,
              title: 'Broadcast Message',
              description: 'Send to all online astrologers',
              color: Colors.orange,
              onTap: () => Navigator.pop(context, 'broadcast'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result == 'single') {
      // Go directly to payment confirmation and chat
      _openChatWithAstrologer(astrologer);
    } else if (result == 'broadcast') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BroadcastChatScreen(),
        ),
      );
    }
  }

  Widget _buildChatOptionTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  /// Show confirmation dialog before paying for chat
  Future<bool> _showPaymentConfirmationDialog(
    ActiveAstrologerModel astrologer,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.cardDark, AppColors.backgroundDark],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.primaryPurple.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.monetization_on_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              SizedBox(height: 20),

              // Title
              Text(
                'Start Chat with ${astrologer.name}?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),

              // Info
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Chat Cost:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, color: gold, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '1 coin',
                              style: TextStyle(
                                color: gold,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Divider(color: Colors.white12),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Balance:',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Row(
                          children: [
                            Icon(Icons.monetization_on, color: gold, size: 18),
                            SizedBox(width: 4),
                            Text(
                              '$_coinBalance coins',
                              style: TextStyle(
                                color: _coinBalance >= 1 ? gold : Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),

              if (_coinBalance < 1)
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Insufficient balance! Please add coins.',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _coinBalance >= 1
                          ? () => Navigator.pop(context, true)
                          : () {
                              Navigator.pop(context, false);
                              Navigator.pushNamed(context, '/payment_page');
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: _coinBalance >= 1
                              ? LinearGradient(
                                  colors: [Colors.green, Colors.green.shade700],
                                )
                              : AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            _coinBalance >= 1 ? 'Pay & Chat' : 'Add Coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
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
    );

    return result ?? false;
  }

  Future<void> _openChatWithAstrologer(ActiveAstrologerModel astrologer) async {
    if (_isConnecting) return;

    // Reload coin balance
    await _loadCoinBalance();

    // Check if already paid for this astrologer
    final alreadyPaid = await _coinService.hasPaidForChat(astrologer.id);

    if (!alreadyPaid) {
      // Show confirmation dialog
      final confirmed = await _showPaymentConfirmationDialog(astrologer);
      if (!confirmed) return;

      // Pay for chat
      final paymentSuccess = await _coinService.payForChat(astrologer.id);
      if (!paymentSuccess) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message: 'Insufficient coins. Please add more coins.',
            backgroundColor: AppColors.error,
          );
        }
        return;
      }

      // Reload balance after payment
      await _loadCoinBalance();
    }

    setState(() => _isConnecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please login first'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      // Decode JWT to get current user ID
      final decodedToken = decodeJwt(accessToken);
      final currentUserId = decodedToken?['id'] ?? '';
      final currentUserName = decodedToken?['name'] ?? 'User';

      if (currentUserId.isEmpty) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message: 'Invalid token. Please login again.',
            backgroundColor: AppColors.error,
          );

          setState(() => _isConnecting = false);
        }
        return;
      }

      // Connect to socket if not already connected
      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        // Wait for connection
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Send chat request notification to astrologer
      // _socketService.sendChatRequest(
      //   astrologerId: astrologer.id,
      //   userName: currentUserName,
      //   userId: currentUserId,
      // );

      if (!mounted) return;

      // Navigate to chat screen with jyotishi id as receiver
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: 'chat_${currentUserId}_${astrologer.id}',
            otherUserId: astrologer.id,
            // Jyotishi ID as receiver
            otherUserName: astrologer.name,
            otherUserPhoto: astrologer.profilePhoto,
            currentUserId: currentUserId,
            // Current user ID from JWT
            accessToken: accessToken,
            refreshToken: refreshToken,
            isOnline: astrologer.isOnline,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
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
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                // Determine loading & astrologers list
                final isLoading = state is ActiveUsersLoading;
                final astrologers = state is ActiveUsersLoaded
                    ? state.astrologers
                    : <ActiveAstrologerModel>[];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(isLoading),
                      SizedBox(height: 16),
                      _balanceCard(),
                      SizedBox(height: 16),
                      _broadcastButton(),
                      SizedBox(height: 16),
                      _searchBar(),
                      SizedBox(height: 20),
                      _activeNowSection(astrologers, isLoading),
                      SizedBox(height: 20),
                      Expanded(child: _chatList()),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isConnecting)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryPurple,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header(bool isLoading) {
    return Row(
      children: [
        GlassIconButton(
          onTap: () => Navigator.pop(context),
          icon: Icons.arrow_back,
        ),
        SizedBox(width: 16),
        Text(
          'Chats',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Spacer(),
        IconButton(
          onPressed: isLoading
              ? null
              : () => context.read<ChatBloc>().add(RefreshActiveUsersEvent()),
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Icon(Icons.refresh, color: Colors.white),
        ),
      ],
    );
  }

  Widget _balanceCard() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.monetization_on_rounded, color: gold, size: 28),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Balance',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$_coinBalance coins',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Spacer(),
          GestureDetector(
            onTap: () async {
              await Navigator.pushNamed(context, '/payment_page');
              _loadCoinBalance();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.add, color: Colors.white, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
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

  Widget _broadcastButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BroadcastChatScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.withOpacity(0.3),
              Colors.deepOrange.withOpacity(0.2),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.orange.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.2),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange, Colors.deepOrange],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.broadcast_on_personal,
                color: Colors.white,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Everyone Jyotish',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Broadcast to all online astrologers',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.orange,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 42,
      padding: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.15),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.white54),
          SizedBox(width: 8),
          Text('Search...', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _activeNowSection(
    List<ActiveAstrologerModel> astrologers,
    bool isLoading,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ACTIVE NOW',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '1 coin/chat',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isLoading) ...[
              SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: 12),
        SizedBox(
          height: 110,
          child: astrologers.isEmpty && !isLoading
              ? Center(
                  child: Text(
                    'No active astrologers',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: astrologers.length,
                  separatorBuilder: (_, __) => SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final astrologer = astrologers[index];
                    return GestureDetector(
                      onTap: () => _showChatTypeDialog(astrologer),
                      child: Column(
                        children: [
                          _buildAstrologerAvatar(astrologer),
                          SizedBox(height: 6),
                          SizedBox(
                            width: 64,
                            child: Text(
                              astrologer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAstrologerAvatar(ActiveAstrologerModel astrologer) {
    // Use socketUrl for static files (not baseUrl which has /api/v1)
    final String imageUrl = astrologer.profilePhoto.startsWith('http')
        ? astrologer.profilePhoto
        : '${ApiEndpoints.socketUrl}${astrologer.profilePhoto}';

    return profileStatus(
      radius: 34,
      isActive: astrologer.isOnline,
      profileImageUrl: imageUrl,
    );
  }

  Widget _chatList() {
    return ListView(
      children: [
        _chatTile(
          name: 'Alice',
          message: 'Hello there!',
          time: '5m',
          online: true,
        ),
        _chatTile(
          name: 'Bob',
          message: 'Meeting tomorrow',
          time: '3h',
          unread: 2,
        ),
      ],
    );
  }

  Widget _chatTile({
    required String name,
    required String message,
    required String time,
    bool online = false,
    bool seen = false,
    int unread = 0,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.15),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryPurple.withOpacity(0.3),
                      AppColors.deepPurple.withOpacity(0.3),
                    ],
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.transparent,
                  child: Icon(Icons.person, color: Colors.white70),
                ),
              ),
              if (online)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.deepPurple, width: 2),
                    ),
                  ),
                ),
              if (unread > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gold, gold.withOpacity(0.8)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: gold.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      unread.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(color: Colors.white54, fontSize: 11)),
              SizedBox(height: 6),
              Icon(
                seen ? Icons.done_all : Icons.done,
                size: 16,
                color: seen ? AppColors.primaryPurple : Colors.white54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
