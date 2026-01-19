import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../chat/service/socket_service.dart';
import '../models/astrologer_chat_models.dart';
import '../service/astrologer_chat_service.dart';
import 'astrologer_chat_screen.dart';
import 'client_profile_screen.dart';

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

class AstrologerChatListScreen extends StatefulWidget {
  const AstrologerChatListScreen({super.key});

  @override
  State<AstrologerChatListScreen> createState() =>
      _AstrologerChatListScreenState();
}

class _AstrologerChatListScreenState extends State<AstrologerChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AstrologerChatService _chatService = AstrologerChatService();
  final SocketService _socketService = SocketService();

  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _error;
  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;
  bool _isOnline = true;

  // Stats
  int _activeCount = 0;
  int _pendingCount = 0;
  int _completedCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _socketService.offMessageReceived();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    await _loadUserData();
    await _initializeService();
    await _loadConversations();
    _setupSocketListeners();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('astrologerAccessToken') ??
                   prefs.getString('accessToken');
    _refreshToken = prefs.getString('astrologerRefreshToken') ??
                    prefs.getString('refreshToken');

    if (_accessToken != null) {
      final decoded = decodeJwt(_accessToken!);
      _currentUserId = decoded?['id'] ?? decoded?['userId'];
    }
  }

  Future<void> _initializeService() async {
    try {
      await _chatService.initialize();
    } catch (e) {
      debugPrint('Error initializing chat service: $e');
    }
  }

  Future<void> _loadConversations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = _conversations.isEmpty;
      _error = null;
    });

    try {
      final conversations = await _chatService.getConversations();

      if (mounted) {
        setState(() {
          _conversations = conversations;
          _filteredConversations = conversations;
          _isLoading = false;
          _updateStats();
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshConversations() async {
    setState(() => _isRefreshing = true);
    await _loadConversations();
    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  void _updateStats() {
    _activeCount = _conversations.where((c) => c.status == 'ACTIVE').length;
    _pendingCount = _conversations.where((c) =>
      c.hasUnread(_currentUserId ?? '')).length;
    _completedCount = _conversations.where((c) => c.status == 'ENDED').length;
  }

  void _setupSocketListeners() {
    // Connect to socket if not connected
    if (!_socketService.connected &&
        _accessToken != null &&
        _refreshToken != null) {
      _socketService.connect(
        accessToken: _accessToken!,
        refreshToken: _refreshToken!,
      );
    }

    // Listen for new messages to update conversation list
    _socketService.onMessageReceived((data) {
      if (mounted) {
        _refreshConversations();
      }
    });
  }

  void _filterConversations(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredConversations = _conversations;
      });
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    setState(() {
      _filteredConversations = _conversations.where((conversation) {
        final otherUser = conversation.getOtherParticipant(_currentUserId ?? '');
        final name = otherUser?.name?.toLowerCase() ?? '';
        final email = otherUser?.email?.toLowerCase() ?? '';
        final lastMessage = conversation.lastMessage?.content.toLowerCase() ?? '';

        return name.contains(lowercaseQuery) ||
               email.contains(lowercaseQuery) ||
               lastMessage.contains(lowercaseQuery);
      }).toList();
    });
  }

  void _navigateToChat(ConversationModel conversation) {
    final otherUser = conversation.getOtherParticipant(_currentUserId ?? '');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AstrologerChatScreen(
          chatId: conversation.id,
          clientId: otherUser?.id ?? '',
          clientName: otherUser?.name ?? 'Client',
          clientPhoto: otherUser?.profilePhoto,
          astrologerId: _currentUserId ?? '',
          accessToken: _accessToken,
          refreshToken: _refreshToken,
        ),
      ),
    ).then((_) {
      // Refresh on return
      _refreshConversations();
    });
  }

  void _navigateToClientProfile(String clientId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ClientProfileScreen(clientId: clientId),
      ),
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
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
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primaryPurple.withOpacity(0.01),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      SizedBox(height: 16),
                      _buildSearchBar(),
                      SizedBox(height: 8),
                      _buildStatsRow(),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _buildContent(),
                ),
              ],
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
          onTap: () => Navigator.pushReplacementNamed(
            context,
            '/home_screen_astrologer',
          ),
          icon: Icons.arrow_back,
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              if (_conversations.isNotEmpty)
                Text(
                  '${_conversations.length} conversation${_conversations.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        // Online status indicator
        GestureDetector(
          onTap: _toggleOnlineStatus,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isOnline
                    ? Colors.green.withOpacity(0.4)
                    : Colors.grey.withOpacity(0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isOnline ? Colors.green : Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8),
        GlassIconButton(
          onTap: _isRefreshing ? () {} : _refreshConversations,
          icon: _isRefreshing ? Icons.hourglass_empty : Icons.refresh,
        ),
      ],
    );
  }

  Future<void> _toggleOnlineStatus() async {
    try {
      final response = await _chatService.toggleOnlineStatus();
      if (mounted) {
        setState(() {
          _isOnline = response.isOnline;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isOnline
                ? 'You are now online'
                : 'You are now offline'),
            backgroundColor: _isOnline ? Colors.green : Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling online status: $e');
    }
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          icon: Icons.people_outline,
          label: 'Active',
          value: '$_activeCount',
          color: Colors.greenAccent,
        ),
        SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.schedule,
          label: 'Unread',
          value: '$_pendingCount',
          color: Colors.orangeAccent,
        ),
        SizedBox(width: 8),
        _buildStatChip(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '$_completedCount',
          color: Colors.blueAccent,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 2),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryPurple.withOpacity(0.12),
            AppColors.deepPurple.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primaryPurple.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPurple.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search, color: Colors.white60, size: 20),
          hintText: 'Search clients...',
          hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.white54, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _filterConversations('');
                  },
                )
              : null,
        ),
        onChanged: _filterConversations,
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryPurple,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.primaryPurple.withOpacity(0.5),
              ),
              SizedBox(height: 16),
              Text(
                'Error loading conversations',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadConversations,
                icon: Icon(Icons.refresh),
                label: Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredConversations.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshConversations,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: _filteredConversations.length,
        separatorBuilder: (_, __) => SizedBox(height: 12),
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return _buildConversationTile(conversation);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.primaryPurple.withOpacity(0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            _searchController.text.isNotEmpty
                ? 'No matching conversations'
                : 'No Conversations Yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty
                ? 'Try a different search term'
                : 'Accept requests to start chatting',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/incoming_requests');
              },
              icon: Icon(Icons.inbox),
              label: Text('View Incoming Requests'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryPurple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final otherUser = conversation.getOtherParticipant(_currentUserId ?? '');
    final hasUnread = conversation.hasUnread(_currentUserId ?? '');
    final isActive = conversation.status == 'ACTIVE';

    return GestureDetector(
      onTap: () => _navigateToChat(conversation),
      onLongPress: () {
        // Show options menu
        _showConversationOptions(conversation);
      },
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryPurple.withOpacity(0.12),
              AppColors.deepPurple.withOpacity(0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            width: 1.5,
            color: isActive
                ? Colors.greenAccent.withOpacity(0.4)
                : AppColors.primaryPurple.withOpacity(0.25),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.15),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Profile image with status
            GestureDetector(
              onTap: () {
                if (otherUser != null) {
                  _navigateToClientProfile(otherUser.id);
                }
              },
              child: _buildProfileAvatar(otherUser, isActive),
            ),
            SizedBox(width: 14),

            // Name and message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          otherUser?.name ?? 'Client',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.greenAccent.shade100,
                                Colors.greenAccent.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.3),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'LIVE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    _getMessagePreview(conversation),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasUnread ? Colors.white70 : Colors.white54,
                      fontSize: 13,
                      fontWeight: hasUnread
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),

            // Time and unread badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(conversation.lastMessageAt ?? conversation.createdAt),
                  style: TextStyle(
                    color: hasUnread ? Colors.white70 : Colors.white54,
                    fontSize: 11,
                    fontWeight: hasUnread
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                SizedBox(height: 8),
                if (hasUnread)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryPurple,
                          AppColors.primaryPurple.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryPurple.withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      conversation.unreadCount?.toString() ?? 'New',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Icon(Icons.check, color: Colors.white38, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(ChatUserModel? user, bool isOnline) {
    final imageUrl = user?.profilePhoto != null
        ? (user!.profilePhoto!.startsWith('http')
            ? user.profilePhoto!
            : '${ApiEndpoints.socketUrl}${user.profilePhoto}')
        : null;

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isOnline ? Colors.greenAccent : Colors.white24,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildDefaultAvatar(user?.name),
                  )
                : _buildDefaultAvatar(user?.name),
          ),
        ),
        Positioned(
          right: 2,
          bottom: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.backgroundDark, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.primaryPurple.withOpacity(0.3),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getMessagePreview(ConversationModel conversation) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return 'No messages yet';

    if (lastMessage.type == 'IMAGE') {
      return '📷 Photo';
    } else if (lastMessage.type == 'FILE') {
      return '📎 File';
    } else if (lastMessage.type == 'AUDIO') {
      return '🎵 Audio';
    }

    return lastMessage.content;
  }

  void _showConversationOptions(ConversationModel conversation) {
    final otherUser = conversation.getOtherParticipant(_currentUserId ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.person_outline, color: Colors.white),
                  title: Text('View Profile',
                    style: TextStyle(color: Colors.white)),
                  subtitle: Text('See client birth details',
                    style: TextStyle(color: Colors.white60)),
                  onTap: () {
                    Navigator.pop(context);
                    if (otherUser != null) {
                      _navigateToClientProfile(otherUser.id);
                    }
                  },
                ),
                ListTile(
                  leading: Icon(Icons.chat_bubble_outline, color: Colors.white),
                  title: Text('Open Chat',
                    style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    _navigateToChat(conversation);
                  },
                ),
                if (conversation.status == 'ACTIVE')
                  ListTile(
                    leading: Icon(Icons.call_end, color: Colors.red),
                    title: Text('End Chat',
                      style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      _confirmEndChat(conversation);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmEndChat(ConversationModel conversation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('End Chat?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to end this chat session?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _chatService.endChat(conversation.id);
                _refreshConversations();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to end chat')),
                  );
                }
              }
            },
            child: Text('End', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
