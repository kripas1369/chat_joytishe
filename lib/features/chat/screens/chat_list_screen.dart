import 'dart:convert';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/show_top_snackBar.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/payment/services/coin_provider.dart';
import 'package:chat_jyotishi/features/chat/service/chat_lock_service.dart';
import 'package:chat_jyotishi/features/chat/widgets/astrologer_profile_sheet.dart';
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
  final ChatLockService _chatLockService = ChatLockService();
  bool _isConnecting = false;
  int _coinBalance = 0;
  bool _isChatsLocked = false;
  String? _lockedJyotishId;
  String? _lockedJyotishName;

  // Chat conversations from server
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingConversations = false;
  String? _currentUserId;
  Dio? _dio;

  @override
  void initState() {
    super.initState();
    _initializeDio();
    _loadCoinBalance();
    _loadLockStatus();
    _loadConversations();
  }

  Future<void> _initializeDio() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          if (accessToken != null && refreshToken != null)
            'cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      ),
    );

    // Get current user ID
    if (accessToken != null) {
      final decoded = decodeJwt(accessToken);
      _currentUserId = decoded?['id'];
    }
  }

  Future<void> _loadCoinBalance() async {
    try {
      if (!coinProvider.isInitialized) {
        await coinProvider.initialize();
      } else {
        await coinProvider.refreshBalance();
      }
      if (mounted) {
        setState(() => _coinBalance = coinProvider.balance);
      }
    } catch (e) {
      // Fallback to local
      final balance = await _coinService.getBalance();
      if (mounted) {
        setState(() => _coinBalance = balance);
      }
    }
  }

  /// Load chat conversations from server
  Future<void> _loadConversations() async {
    if (_dio == null) {
      await _initializeDio();
    }

    setState(() => _isLoadingConversations = true);

    try {
      final response = await _dio!.get('/chat/chats');
      debugPrint('Conversations response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> chats = [];

        // Handle different response structures
        if (data['chats'] != null) {
          chats = data['chats'] as List;
        } else if (data['data'] != null) {
          chats = data['data'] as List;
        } else if (data is List) {
          chats = data;
        }

        // Sort by last message time (oldest first, so latest appears at bottom)
        chats.sort((a, b) {
          final aTime = DateTime.tryParse(a['lastMessageAt']?.toString() ?? a['updatedAt']?.toString() ?? '') ?? DateTime(2000);
          final bTime = DateTime.tryParse(b['lastMessageAt']?.toString() ?? b['updatedAt']?.toString() ?? '') ?? DateTime(2000);
          return aTime.compareTo(bTime); // Oldest first, latest at bottom
        });

        if (mounted) {
          setState(() {
            _conversations = List<Map<String, dynamic>>.from(chats);
            _isLoadingConversations = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() => _isLoadingConversations = false);
      }
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
            message: 'Please wait for ${_lockedJyotishName ?? "Jyotish"} to reply first.',
            backgroundColor: Colors.orange,
          );
        }
        return;
      }
    }

    // Go directly to chat
    _openChatWithAstrologer(astrologer);
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

  Widget _lockStatusBanner() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withAlpha(51),
            Colors.blueAccent.withAlpha(26),
          ],
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
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
    if (_isLoadingConversations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                color: AppColors.primaryPurple,
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Loading conversations...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryPurple.withAlpha(40),
                    AppColors.deepPurple.withAlpha(20),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple.withAlpha(60),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.primaryPurple,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Start chatting with an astrologer from the "Active Now" section above',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'RECENT CHATS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_conversations.length}',
                  style: TextStyle(
                    color: AppColors.primaryPurple,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Spacer(),
              GestureDetector(
                onTap: _loadConversations,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, color: Colors.white54, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Refresh',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chat list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadConversations,
            color: AppColors.primaryPurple,
            backgroundColor: AppColors.cardDark,
            child: ListView.builder(
              physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: _conversations.length,
              reverse: true, // Latest at bottom, scroll starts from bottom
              itemBuilder: (context, index) {
                // Since list is reversed, index 0 is the latest (at bottom)
                final reversedIndex = _conversations.length - 1 - index;
                final chat = _conversations[reversedIndex];
                return _buildChatTile(chat);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    // Get the other participant (astrologer)
    final participant1 = chat['participant1'] ?? chat['clientParticipant'];
    final participant2 = chat['participant2'] ?? chat['astrologerParticipant'];

    // Determine which participant is the other user
    Map<String, dynamic>? otherUser;
    if (participant1 != null && participant1['id'] != _currentUserId) {
      otherUser = Map<String, dynamic>.from(participant1);
    } else if (participant2 != null && participant2['id'] != _currentUserId) {
      otherUser = Map<String, dynamic>.from(participant2);
    }

    // Fallback to astrologerParticipant or clientParticipant
    if (otherUser == null) {
      final fallback = chat['astrologerParticipant'] ?? chat['clientParticipant'];
      otherUser = fallback != null ? Map<String, dynamic>.from(fallback) : {};
    }
    final Map<String, dynamic> user = otherUser;

    final String odtherUserId = user['id']?.toString() ?? '';
    final String name = user['name']?.toString() ?? 'Unknown';
    final String? profilePhoto = user['profilePhoto']?.toString();
    final String role = user['role']?.toString() ?? 'ASTROLOGER';
    final bool isOnline = user['isOnline'] == true;

    // Get additional details from participant data
    final String? specialization = user['specialization']?.toString();
    final double rating = _parseDouble(user['rating']);

    // Chat details
    final String? lastMessage = chat['lastMessageText']?.toString();
    final String status = chat['status']?.toString() ?? 'ACTIVE';
    final bool isEnded = status == 'ENDED';
    final int unreadCount = chat['unreadCount'] ?? 0;

    // Format time
    final String timeStr = _formatTime(chat['lastMessageAt'] ?? chat['updatedAt']);

    // Get image URL
    final String imageUrl = profilePhoto != null && profilePhoto.isNotEmpty
        ? (profilePhoto.startsWith('http')
            ? profilePhoto
            : '${ApiEndpoints.socketUrl}$profilePhoto')
        : '';

    return GestureDetector(
      onTap: () => _openChatFromConversation(chat, user),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isEnded
              ? Colors.grey.withAlpha(20)
              : AppColors.cardDark.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: unreadCount > 0
                ? gold.withAlpha(100)
                : isEnded
                    ? Colors.grey.withAlpha(40)
                    : AppColors.primaryPurple.withAlpha(30),
            width: unreadCount > 0 ? 1.5 : 1,
          ),
          boxShadow: unreadCount > 0 ? [
            BoxShadow(
              color: gold.withAlpha(20),
              blurRadius: 8,
              spreadRadius: 0,
            ),
          ] : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openChatFromConversation(chat, user),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  // Profile photo with online indicator
                  GestureDetector(
                    onTap: () => _showProfileSheet(odtherUserId, name, profilePhoto, isOnline),
                    child: Stack(
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: isOnline
                                ? LinearGradient(
                                    colors: [Colors.green.shade400, Colors.green.shade600],
                                  )
                                : AppColors.primaryGradient,
                          ),
                          padding: EdgeInsets.all(2.5),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.cardDark,
                            ),
                            padding: EdgeInsets.all(2),
                            child: ClipOval(
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildInitials(name),
                                    )
                                  : _buildInitials(name),
                            ),
                          ),
                        ),
                        // Online indicator
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey.shade600,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.cardDark, width: 2.5),
                              boxShadow: isOnline ? [
                                BoxShadow(
                                  color: Colors.green.withAlpha(150),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ] : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  // Chat info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name row with badges
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.w600,
                                        fontSize: 15,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (role == 'ASTROLOGER') ...[
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.verified_rounded,
                                      color: gold,
                                      size: 16,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            // Time
                            Text(
                              timeStr,
                              style: TextStyle(
                                color: unreadCount > 0 ? gold : Colors.white54,
                                fontSize: 11,
                                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        // Specialization or role info
                        if (specialization != null && specialization.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.auto_awesome, color: AppColors.primaryPurple, size: 12),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    specialization,
                                    style: TextStyle(
                                      color: AppColors.primaryPurple,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (rating > 0) ...[
                                  Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                                  SizedBox(width: 2),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: TextStyle(
                                      color: Colors.amber,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        // Last message row
                        Row(
                          children: [
                            if (isEnded)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(40),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Ended',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                lastMessage ?? 'Start a conversation',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: lastMessage != null
                                      ? (unreadCount > 0 ? Colors.white70 : Colors.white54)
                                      : Colors.white38,
                                  fontSize: 13,
                                  fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                                  fontStyle: lastMessage == null ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),
                            ),
                            // Unread badge
                            if (unreadCount > 0)
                              Container(
                                margin: EdgeInsets.only(left: 8),
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [gold, gold.withAlpha(220)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withAlpha(100),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitials(String name) {
    // Generate a consistent color based on name
    final colors = [
      Colors.purple.shade400,
      Colors.blue.shade400,
      Colors.teal.shade400,
      Colors.orange.shade400,
      Colors.pink.shade400,
      Colors.indigo.shade400,
    ];
    final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors[colorIndex],
            colors[colorIndex].withAlpha(180),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
              offset: Offset(1, 1),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';

    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';

    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    return '${date.day}/${date.month}';
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _showProfileSheet(String userId, String name, String? photo, bool isOnline) {
    showAstrologerProfileSheet(
      context: context,
      astrologerId: userId,
      astrologerName: name,
      astrologerPhoto: photo,
      isOnline: isOnline,
    );
  }

  Future<void> _openChatFromConversation(
    Map<String, dynamic> chat,
    Map<String, dynamic> otherUser,
  ) async {
    if (_isConnecting) return;

    setState(() => _isConnecting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        if (mounted) {
          showTopSnackBar(
            context: context,
            message: 'Please login first',
            backgroundColor: AppColors.error,
          );
          setState(() => _isConnecting = false);
        }
        return;
      }

      // Connect socket if needed
      if (!_socketService.connected) {
        await _socketService.connect(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        await Future.delayed(Duration(milliseconds: 500));
      }

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chat['id']?.toString() ?? '',
            otherUserId: otherUser['id']?.toString() ?? '',
            otherUserName: otherUser['name']?.toString() ?? 'Unknown',
            otherUserPhoto: otherUser['profilePhoto']?.toString(),
            currentUserId: _currentUserId ?? '',
            accessToken: accessToken,
            refreshToken: refreshToken,
            isOnline: otherUser['isOnline'] == true,
          ),
        ),
      ).then((_) {
        _loadLockStatus();
        _loadCoinBalance();
        _loadConversations();
      });
    } catch (e) {
      debugPrint('Error opening chat: $e');
      if (mounted) {
        showTopSnackBar(
          context: context,
          message: 'Failed to open chat',
          backgroundColor: AppColors.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }
}
