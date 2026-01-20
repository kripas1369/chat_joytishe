import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../../../constants/constant.dart';
import '../../app_widgets/glass_icon_button.dart';
import '../../app_widgets/star_field_background.dart';
import '../../chat/service/socket_service.dart';
import '../models/astrologer_chat_models.dart';
import '../service/astrologer_chat_service.dart';
import 'astrologer_chat_screen.dart';

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

/// Broadcast Messages Screen for Astrologers
/// Shows pending and all broadcast messages with accept/dismiss actions
class BroadcastMessagesScreen extends StatefulWidget {
  const BroadcastMessagesScreen({super.key});

  @override
  State<BroadcastMessagesScreen> createState() => _BroadcastMessagesScreenState();
}

class _BroadcastMessagesScreenState extends State<BroadcastMessagesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AstrologerChatService _chatService = AstrologerChatService();
  final SocketService _socketService = SocketService();

  List<BroadcastMessageModel> _pendingBroadcasts = [];
  List<BroadcastMessageModel> _allBroadcasts = [];
  bool _isPendingLoading = true;
  bool _isAllLoading = true;
  String? _pendingError;
  String? _allError;

  String? _currentUserId;
  String? _accessToken;
  String? _refreshToken;

  Timer? _expiryTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeAndLoad();

    // Start timer to update expiry times
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _expiryTimer?.cancel();
    _socketService.offNewBroadcastMessage();
    _socketService.offBroadcastError();
    super.dispose();
  }

  Future<void> _initializeAndLoad() async {
    await _loadUserData();
    await _initializeService();
    _setupSocketListeners();
    await Future.wait([
      _loadPendingBroadcasts(),
      _loadAllBroadcasts(),
    ]);
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

    // Listen for new broadcast messages
    _socketService.onNewBroadcastMessage((data) {
      debugPrint('New broadcast received: $data');
      if (mounted) {
        final message = data['message'] ?? data;
        final broadcast = BroadcastMessageModel.fromJson(message);
        setState(() {
          // Add to pending if not already there
          if (!_pendingBroadcasts.any((b) => b.id == broadcast.id)) {
            _pendingBroadcasts.insert(0, broadcast);
          }
        });
      }
    });

    // Listen for broadcast accepted (by another astrologer)
    _socketService.socket?.on('broadcast:accepted', (data) {
      final messageId = data['messageId'] ?? data['message']?['id'];
      if (messageId != null && mounted) {
        setState(() {
          _pendingBroadcasts.removeWhere((b) => b.id == messageId);
        });
      }
    });

    // Listen for broadcast expired
    _socketService.socket?.on('broadcast:expired', (data) {
      final messageId = data['messageId'] ?? data['message']?['id'];
      if (messageId != null && mounted) {
        setState(() {
          _pendingBroadcasts.removeWhere((b) => b.id == messageId);
        });
      }
    });

    // Listen for errors
    _socketService.onBroadcastError((data) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  Future<void> _loadPendingBroadcasts() async {
    if (!mounted) return;

    setState(() {
      _isPendingLoading = _pendingBroadcasts.isEmpty;
      _pendingError = null;
    });

    try {
      final broadcasts = await _chatService.getPendingBroadcasts();

      if (mounted) {
        setState(() {
          _pendingBroadcasts = broadcasts;
          _isPendingLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pending broadcasts: $e');
      if (mounted) {
        setState(() {
          _pendingError = e.toString().replaceAll('Exception: ', '');
          _isPendingLoading = false;
        });
      }
    }
  }

  Future<void> _loadAllBroadcasts() async {
    if (!mounted) return;

    setState(() {
      _isAllLoading = _allBroadcasts.isEmpty;
      _allError = null;
    });

    try {
      final broadcasts = await _chatService.getAllBroadcasts();

      if (mounted) {
        setState(() {
          _allBroadcasts = broadcasts;
          _isAllLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading all broadcasts: $e');
      if (mounted) {
        setState(() {
          _allError = e.toString().replaceAll('Exception: ', '');
          _isAllLoading = false;
        });
      }
    }
  }

  Future<void> _acceptBroadcast(BroadcastMessageModel broadcast) async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Accepting broadcast...'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 30),
        ),
      );
    }

    // Always use HTTP API for reliability - it returns the chat ID directly
    try {
      final response = await _chatService.acceptBroadcast(broadcast.id);

      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      if (mounted) {
        setState(() {
          _pendingBroadcasts.removeWhere((b) => b.id == broadcast.id);
        });

        // Get chat ID from response
        final chatId = response.chatId ?? response.chat?['id'];

        if (chatId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Broadcast accepted! Opening chat...'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AstrologerChatScreen(
                chatId: chatId,
                clientId: response.client?.id ?? broadcast.clientId,
                clientName: response.client?.name ?? broadcast.client?.name ?? 'Client',
                clientPhoto: response.client?.profilePhoto ?? broadcast.client?.profilePhoto,
                astrologerId: _currentUserId ?? '',
                accessToken: _accessToken,
                refreshToken: _refreshToken,
                initialMessage: broadcast.content,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Broadcast accepted but no chat ID returned'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Hide loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _dismissBroadcast(BroadcastMessageModel broadcast) async {
    try {
      await _chatService.dismissBroadcast(broadcast.id);

      if (mounted) {
        setState(() {
          _pendingBroadcasts.removeWhere((b) => b.id == broadcast.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Broadcast dismissed'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to dismiss'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  String _formatRemainingTime(Duration? remaining) {
    if (remaining == null) return '';
    if (remaining.isNegative || remaining.inSeconds <= 0) return 'Expired';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}m ${seconds}s left';
    }
    return '${seconds}s left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          StarFieldBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.backgroundGradient,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPendingTab(),
                      _buildAllTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
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
                Text(
                  'Broadcast Messages',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_pendingBroadcasts.length} pending',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          GlassIconButton(
            onTap: () {
              _loadPendingBroadcasts();
              _loadAllBroadcasts();
            },
            icon: Icons.refresh,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryPurple, AppColors.deepPurple],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pending_outlined, size: 18),
                const SizedBox(width: 6),
                Text('Pending'),
                if (_pendingBroadcasts.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pendingBroadcasts.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 18),
                const SizedBox(width: 6),
                Text('All'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    if (_isPendingLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_pendingError != null) {
      return _buildErrorState(_pendingError!, _loadPendingBroadcasts);
    }

    if (_pendingBroadcasts.isEmpty) {
      return _buildEmptyState(
        'No Pending Broadcasts',
        'New broadcast requests will appear here',
        Icons.inbox_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPendingBroadcasts,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingBroadcasts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final broadcast = _pendingBroadcasts[index];
          return _buildPendingBroadcastCard(broadcast);
        },
      ),
    );
  }

  Widget _buildAllTab() {
    if (_isAllLoading) {
      return Center(
        child: CircularProgressIndicator(color: AppColors.primaryPurple),
      );
    }

    if (_allError != null) {
      return _buildErrorState(_allError!, _loadAllBroadcasts);
    }

    if (_allBroadcasts.isEmpty) {
      return _buildEmptyState(
        'No Broadcasts Yet',
        'Broadcast history will appear here',
        Icons.history,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllBroadcasts,
      color: AppColors.primaryPurple,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _allBroadcasts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final broadcast = _allBroadcasts[index];
          return _buildAllBroadcastCard(broadcast);
        },
      ),
    );
  }

  Widget _buildPendingBroadcastCard(BroadcastMessageModel broadcast) {
    final imageUrl = broadcast.client?.profilePhoto != null
        ? (broadcast.client!.profilePhoto!.startsWith('http')
            ? broadcast.client!.profilePhoto!
            : '${ApiEndpoints.socketUrl}${broadcast.client!.profilePhoto}')
        : null;

    final remainingTime = broadcast.remainingTime;
    final isExpiringSoon = remainingTime != null &&
        remainingTime.inSeconds <= 60 &&
        remainingTime.inSeconds > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withAlpha(40),
            AppColors.cardDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpiringSoon
              ? Colors.red.withAlpha(150)
              : Colors.orange.withAlpha(75),
          width: isExpiringSoon ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Profile image
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: ClipOval(
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultAvatar(
                            broadcast.client?.name,
                          ),
                        )
                      : _buildDefaultAvatar(broadcast.client?.name),
                ),
              ),
              const SizedBox(width: 12),

              // Name and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      broadcast.client?.name ?? 'Client',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Broadcast',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(broadcast.createdAt),
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remaining time
              if (remainingTime != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isExpiringSoon
                        ? Colors.red.withAlpha(50)
                        : Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer,
                        size: 14,
                        color: isExpiringSoon ? Colors.red : Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatRemainingTime(remainingTime),
                        style: TextStyle(
                          color: isExpiringSoon ? Colors.red : Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              broadcast.content.isEmpty ? 'No message' : broadcast.content,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _dismissBroadcast(broadcast),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Center(
                      child: Text(
                        'Dismiss',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () => _acceptBroadcast(broadcast),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Accept & Chat',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllBroadcastCard(BroadcastMessageModel broadcast) {
    final imageUrl = broadcast.client?.profilePhoto != null
        ? (broadcast.client!.profilePhoto!.startsWith('http')
            ? broadcast.client!.profilePhoto!
            : '${ApiEndpoints.socketUrl}${broadcast.client!.profilePhoto}')
        : null;

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (broadcast.status) {
      case BroadcastStatus.ACCEPTED:
        statusColor = Colors.green;
        statusText = 'Accepted';
        statusIcon = Icons.check_circle;
        break;
      case BroadcastStatus.EXPIRED:
        statusColor = Colors.grey;
        statusText = 'Expired';
        statusIcon = Icons.timer_off;
        break;
      case BroadcastStatus.DISMISSED:
        statusColor = Colors.red;
        statusText = 'Dismissed';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withAlpha(75),
        ),
      ),
      child: Row(
        children: [
          // Profile image
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withAlpha(150), width: 2),
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildDefaultAvatar(
                        broadcast.client?.name,
                      ),
                    )
                  : _buildDefaultAvatar(broadcast.client?.name),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        broadcast.client?.name ?? 'Client',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(broadcast.createdAt),
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  broadcast.content,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (broadcast.acceptedAstrologer != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'by ${broadcast.acceptedAstrologer!.name}',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar(String? name) {
    final initial = name?.isNotEmpty == true ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.primaryPurple.withAlpha(75),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primaryPurple.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: AppColors.primaryPurple.withAlpha(125),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(color: Colors.white60),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
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
}
