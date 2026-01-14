import 'dart:convert';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/chat/service/chat_lock_service.dart';
import 'package:dio/dio.dart';
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
          ChatBloc(chatRepository: ChatRepository(chatService: ChatService()))
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
  final ChatLockService _chatLockService = ChatLockService();
  bool _isConnecting = false;
  int _coinBalance = 0;
  bool _isChatsLocked = false;
  String? _lockedJyotishId;
  String? _lockedJyotishName;

  @override
  void initState() {
    super.initState();
    _loadCoinBalance();
    _loadLockStatus();
  }

  Future<void> _loadCoinBalance() async {
    final balance = await _coinService.getBalance();
    if (mounted) {
      setState(() => _coinBalance = balance);
    }
  }

  Future<void> _loadLockStatus() async {
    final locked = await _chatLockService.isLocked();
    final lockedId = await _chatLockService.getLockedJyotishId();
    final lockedName = await _chatLockService.getLockedJyotishName();
    if (mounted) {
      setState(() {
        _isChatsLocked = locked;
        _lockedJyotishId = lockedId;
        _lockedJyotishName = lockedName;
      });
    }
  }

  /// Handle chat entry - go directly to chat (no popup)
  /// If locked, only allow entry to the locked Jyotish
  Future<void> _handleChatEntry(ActiveAstrologerModel astrologer) async {
    // Reload lock status
    await _loadLockStatus();

    // Check if chats are locked
    if (_isChatsLocked) {
      // Can only enter the chat of the Jyotish user is waiting for
      if (_lockedJyotishId != astrologer.id) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message:
                'Please wait for ${_lockedJyotishName ?? "Jyotish"} to reply first.',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
    }

    // Go directly to chat
    _openChatWithAstrologer(astrologer);
  }

  Future<String?> _getOrCreateChatId(String astrologerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        debugPrint('No tokens available');
        return null;
      }

      final dio = Dio(
        BaseOptions(
          baseUrl: ApiEndpoints.baseUrl,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
          },
        ),
      );

      debugPrint('Creating/getting chat with astrologer: $astrologerId');

      // Try to create or get existing chat
      final response = await dio.post(
        ApiEndpoints.chatChats,
        data: {'participantId': astrologerId},
      );

      debugPrint('Chat creation response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'];

        // Try different possible field names
        String? chatId =
            data['id'] ??
            data['chatId'] ??
            data['_id'] ??
            data['conversationId'];

        if (chatId != null) {
          debugPrint('Got chat ID: $chatId');
          return chatId;
        } else {
          debugPrint('No chat ID found in response: $data');
          return null;
        }
      }

      debugPrint('Unexpected status code: ${response.statusCode}');
      return null;
    } on DioException catch (e) {
      debugPrint('DioException creating chat: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      return null;
    } catch (e) {
      debugPrint('Error creating/getting chat: $e');
      return null;
    }
  }

  Future<void> _openChatWithAstrologer(ActiveAstrologerModel astrologer) async {
    if (_isConnecting) return;

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
            chatId: '',
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
      ).then((_) {
        // Refresh lock status and coin balance when returning from chat
        _loadLockStatus();
        _loadCoinBalance();
      });
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
                final isLoading = state is ChatLoadingState;
                final astrologers = state is ActiveUsersLoadedState
                    ? state.astrologers
                    : <ActiveAstrologerModel>[];

                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _header(isLoading),
                      SizedBox(height: 16),

                      if (_isChatsLocked) ...[
                        SizedBox(height: 12),
                        _lockStatusBanner(),
                      ],
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
          icon: Icons.arrow_back_ios_new_rounded,
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

  Widget _lockStatusBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withAlpha(51), Colors.blueAccent.withAlpha(26)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(77)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Waiting for reply',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'From ${_lockedJyotishName ?? "Jyotish"}',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.lock_rounded, color: Colors.blue, size: 20),
        ],
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
                '2 coins/chat',
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
                      onTap: () => _handleChatEntry(astrologer),
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
