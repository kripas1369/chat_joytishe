import 'dart:async';
import 'dart:io';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/chat/widgets/profile_status.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final String currentUserId;
  final String? accessToken;
  final String? refreshToken;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    required this.currentUserId,
    this.accessToken,
    this.refreshToken,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  late Dio _dio;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isOtherUserTyping = false;
  bool _isOtherUserOnline = true;
  bool _isSendingImage = false;
  Timer? _typingTimer;

  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeDio();
    _registerSocketListeners();
    _loadChatHistory();
  }

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (widget.accessToken != null && widget.refreshToken != null) {
      _dio.options.headers['cookie'] =
          'accessToken=${widget.accessToken}; refreshToken=${widget.refreshToken}';
    }
  }

  void _registerSocketListeners() {
    _socketService.onMessageReceived((message) {
      final senderId = message['senderId'] ?? message['sender']?['id'];
      if (senderId == widget.otherUserId) {
        final messageId =
            message['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final exists = _messages.any((m) => m['id'] == messageId);
        if (!exists && mounted) {
          setState(() {
            _messages.insert(0, {
              'id': messageId,
              'content': message['content'] ?? '',
              'senderId': senderId,
              'receiverId': message['receiverId'] ?? widget.currentUserId,
              'isRead': message['isRead'] ?? false,
              'createdAt':
                  message['createdAt'] ?? DateTime.now().toIso8601String(),
              'type': message['type'] ?? 'TEXT',
              'metadata': message['metadata'],
            });
          });
          _scrollToBottom();
          _socketService.markMessagesAsRead([messageId]);
        }
      }
    });

    _socketService.onMessageSent((message) {
      if (mounted) {
        setState(() {
          _messages.removeWhere(
            (m) => m['isSending'] == true && m['content'] == message['content'],
          );

          final messageId =
              message['id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString();
          final exists = _messages.any((m) => m['id'] == messageId);
          if (!exists) {
            _messages.insert(0, {
              'id': messageId,
              'content': message['content'] ?? '',
              'senderId': widget.currentUserId,
              'receiverId': widget.otherUserId,
              'isRead': message['isRead'] ?? false,
              'createdAt':
                  message['createdAt'] ?? DateTime.now().toIso8601String(),
              'type': message['type'] ?? 'TEXT',
            });
          }
        });
      }
    });

    _socketService.onTypingIndicator((data) {
      if (data['senderId'] == widget.otherUserId && mounted) {
        setState(() => _isOtherUserTyping = data['isTyping'] ?? false);
      }
    });

    _socketService.onUserStatus((data) {
      if (data['userId'] == widget.otherUserId && mounted) {
        setState(() => _isOtherUserOnline = data['status'] == 'online');
      }
    });
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.chatHistory}/${widget.otherUserId}',
        queryParameters: {'limit': 50},
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        final loadedMessages = (response.data['data'] as List)
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
        loadedMessages.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
          final bTime =
              DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
          return bTime.compareTo(aTime);
        });
        if (mounted) setState(() => _messages = loadedMessages);
      }
    } catch (e) {
      print('Failed to load chat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _stopTyping();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.insert(0, {
        'id': tempId,
        'content': content,
        'senderId': widget.currentUserId,
        'receiverId': widget.otherUserId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'TEXT',
        'isSending': true,
      });
    });

    _scrollToBottom();

    _socketService.sendMessage(
      receiverId: widget.otherUserId,
      content: content,
      type: 'TEXT',
    );
  }

  void _handleTyping(String text) {
    if (text.isNotEmpty) {
      _socketService.sendTypingIndicator(
        receiverId: widget.otherUserId,
        isTyping: true,
      );
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), _stopTyping);
    } else {
      _stopTyping();
    }
  }

  void _stopTyping() {
    _typingTimer?.cancel();
    _socketService.sendTypingIndicator(
      receiverId: widget.otherUserId,
      isTyping: false,
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6C5CE7),
                          ),
                        )
                      : _buildMessagesList(),
                ),
                if (_isOtherUserTyping) _buildTypingIndicator(),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final String imageUrl = widget.otherUserPhoto != null
        ? widget.otherUserPhoto!
        : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 14),
          profileStatus(
            radius: 22,
            isActive: _isOtherUserOnline,
            profileImageUrl: imageUrl,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  _isOtherUserOnline ? 'Active now' : 'Offline',
                  style: TextStyle(
                    color: _isOtherUserOnline ? Colors.green : Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.call, color: AppColors.primaryPurple),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: AppColors.primaryPurple),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 48,
                color: AppColors.primaryPurple,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Say hi to ${widget.otherUserName}! 👋',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['senderId'] == widget.currentUserId;

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: _buildMessageBubble(message, isMe),
        );
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final isSending = message['isSending'] == true;
    final type = message['type'] ?? 'TEXT';
    final content = message['content'] ?? '';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: type == 'IMAGE'
                ? EdgeInsets.all(4)
                : EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.65,
            ),
            decoration: BoxDecoration(
              gradient: isMe ? AppColors.splashGradient : null,
              color: isMe ? null : Colors.white.withOpacity(0.65),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 20),
              ),
            ),
            child: type == 'IMAGE'
                ? _buildImageMessage(content, message['localPath'], isSending)
                : Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 4, left: 4, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message['createdAt']),
                  style: TextStyle(fontSize: 11, color: Colors.white60),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  isSending
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white60,
                          ),
                        )
                      : Icon(
                          message['isRead'] == true
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: message['isRead'] == true
                              ? Colors.blue[300]
                              : Colors.white60,
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          profileStatus(
            radius: 16,
            isActive: true,
            profileImageUrl: widget.otherUserPhoto ?? '',
          ),
          SizedBox(width: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'typing...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white12, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.attach_file, color: Colors.white70, size: 20),
              onPressed: () {},
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: _handleTyping,
                cursorColor: Colors.white,
                style: TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: Colors.white70, size: 20),
                    onPressed: () {},
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.splashGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: GlassIconButton(icon: Icons.send, onTap: _sendMessage),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(String url, String? localPath, bool isSending) {
    if (localPath != null && File(localPath).existsSync()) {
      return Image.file(
        File(localPath),
        width: 200,
        height: 200,
        fit: BoxFit.cover,
      );
    } else if (url.startsWith('http')) {
      return Image.network(url, width: 200, height: 200, fit: BoxFit.cover);
    } else {
      return Container(width: 200, height: 200, color: Colors.grey[700]);
    }
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}
