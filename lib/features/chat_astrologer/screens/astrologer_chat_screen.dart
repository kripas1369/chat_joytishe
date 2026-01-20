import 'dart:async';
import 'dart:io';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

/// Simple Chat Screen for Astrologers
/// No coin lock functionality - astrologer can chat freely after accepting request
class AstrologerChatScreen extends StatefulWidget {
  final String chatId;
  final String clientId;
  final String clientName;
  final String? clientPhoto;
  final String astrologerId;
  final String? accessToken;
  final String? refreshToken;
  final String? initialMessage; // Initial message from instant chat/broadcast request

  const AstrologerChatScreen({
    super.key,
    required this.chatId,
    required this.clientId,
    required this.clientName,
    this.clientPhoto,
    required this.astrologerId,
    this.accessToken,
    this.refreshToken,
    this.initialMessage,
  });

  @override
  State<AstrologerChatScreen> createState() => _AstrologerChatScreenState();
}

class _AstrologerChatScreenState extends State<AstrologerChatScreen>
    with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();

  late Dio _dio;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isClientTyping = false;
  bool _isClientOnline = true;
  bool _isSendingImage = false;
  Timer? _typingTimer;

  // Actual chat ID (may be updated from server)
  late String _actualChatId;

  late AnimationController _typingAnimationController;

  @override
  void initState() {
    super.initState();
    _actualChatId = widget.chatId;

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeDio();
    _registerSocketListeners();
    _listenForChatCreated();
    _loadChatHistory();

    // Set active chat to prevent notifications for this chat
    _socketService.setActiveChat(widget.chatId);
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=${widget.accessToken}; refreshToken=${widget.refreshToken}',
      },
    ));
  }

  /// Listen for broadcast:accepted event to get the actual chat ID
  void _listenForChatCreated() {
    _socketService.socket?.on('broadcast:accepted', (data) {
      debugPrint('Broadcast accepted in chat screen: $data');
      final chat = data['chat'];
      if (chat != null && mounted) {
        final newChatId = chat['id'] ?? '';
        if (newChatId.isNotEmpty && newChatId != _actualChatId) {
          setState(() {
            _actualChatId = newChatId;
          });
          _socketService.setActiveChat(_actualChatId);
          // Reload chat history with new chatId
          _loadChatHistory();
        }
      }
    });
  }

  void _registerSocketListeners() {
    // Listen for incoming messages
    _socketService.onMessageReceived((data) {
      if (mounted) {
        final message = Map<String, dynamic>.from(data);
        // Only add if from this chat
        final senderId = message['senderId'] ?? message['sender']?['id'];
        if (senderId == widget.clientId) {
          setState(() {
            _messages.add(message);
          });
          _scrollToBottom();
          // Mark new messages as read
          _markMessagesAsRead();
        }
      }
    });

    // Listen for sent message confirmation
    _socketService.onMessageSent((data) {
      debugPrint('Message sent confirmation: $data');
    });

    // Listen for typing indicator
    _socketService.onTypingIndicator((data) {
      if (data['userId'] == widget.clientId && mounted) {
        setState(() {
          _isClientTyping = data['isTyping'] ?? false;
        });
      }
    });

    // Listen for user status
    _socketService.onUserStatus((data) {
      if (data['userId'] == widget.clientId && mounted) {
        setState(() {
          _isClientOnline = data['status'] == 'online';
        });
      }
    });

    // Listen for chat ended
    _socketService.onChatEnded((data) {
      if (mounted) {
        _showChatEndedDialog();
      }
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      // API: GET /chat/history/:otherUserId - uses clientId for astrologer
      final response = await _dio.get(
        '${ApiEndpoints.chatHistory}/${widget.clientId}',
      );

      debugPrint('Load chat history response: ${response.statusCode}');

      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        // Response: { "messages": [ { "id": "...", "content": "...", ... } ] }
        final messages = data['messages'] ?? data['data'] ?? [];

        // Update actual chat ID from response if available
        if (data['chatId'] != null) {
          _actualChatId = data['chatId'];
          // Mark messages as read
          _markMessagesAsRead();
        }

        setState(() {
          _messages = List<Map<String, dynamic>>.from(messages);
          // If no messages but we have an initial message, add it
          if (_messages.isEmpty && widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
            _messages.add({
              'id': 'initial_${DateTime.now().millisecondsSinceEpoch}',
              'content': widget.initialMessage,
              'type': 'TEXT',
              'senderId': widget.clientId,
              'createdAt': DateTime.now().toIso8601String(),
            });
          }
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      // Chat might not exist yet (just created), that's OK - start fresh
      if (mounted) {
        setState(() {
          _isLoading = false;
          // If we have an initial message, show it even if chat history failed to load
          if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
            _messages = [
              {
                'id': 'initial_${DateTime.now().millisecondsSinceEpoch}',
                'content': widget.initialMessage,
                'type': 'TEXT',
                'senderId': widget.clientId,
                'createdAt': DateTime.now().toIso8601String(),
              }
            ];
          } else {
            _messages = [];
          }
        });
      }
    }
  }

  /// Mark all messages in the chat as read
  Future<void> _markMessagesAsRead() async {
    if (_actualChatId.isEmpty) return;

    try {
      // API: PUT /chat/chats/:chatId/read
      await _dio.put('${ApiEndpoints.chatMarkRead}/$_actualChatId/read');
      debugPrint('Messages marked as read for chat: $_actualChatId');
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    // Send via socket
    _socketService.sendMessage(
      receiverId: widget.clientId,
      content: content,
      type: 'TEXT',
    );

    // Add to local messages
    setState(() {
      _messages.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'content': content,
        'type': 'TEXT',
        'senderId': widget.astrologerId,
        'createdAt': DateTime.now().toIso8601String(),
      });
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _sendTypingIndicator(bool isTyping) {
    _socketService.sendTypingIndicator(
      receiverId: widget.clientId,
      isTyping: isTyping,
    );
  }

  void _onTextChanged(String text) {
    _typingTimer?.cancel();
    _sendTypingIndicator(true);

    _typingTimer = Timer(const Duration(seconds: 2), () {
      _sendTypingIndicator(false);
    });
  }

  Future<void> _pickAndSendImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      setState(() => _isSendingImage = true);

      final file = File(pickedFile.path);
      final fileName = path.basename(file.path);

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'receiverId': widget.clientId,
      });

      final response = await _dio.post(
        ApiEndpoints.chatUploadFile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final fileUrl = data['fileUrl'] ?? data['url'];

        // Send file message via socket
        _socketService.sendMessage(
          receiverId: widget.clientId,
          content: fileUrl,
          type: 'IMAGE',
        );

        // Add to local messages
        setState(() {
          _messages.add({
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': fileUrl,
            'type': 'IMAGE',
            'senderId': widget.astrologerId,
            'createdAt': DateTime.now().toIso8601String(),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error sending image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send image')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingImage = false);
      }
    }
  }

  void _showChatEndedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('Chat Ended', style: TextStyle(color: Colors.white)),
        content: Text(
          'This chat session has ended.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _endChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardDark,
        title: Text('End Chat?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to end this chat?',
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
                // Use actualChatId which may have been updated
                await _dio.put('${ApiEndpoints.chatEnd}/$_actualChatId/end');
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                debugPrint('Error ending chat: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to end chat'), backgroundColor: Colors.red),
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

  @override
  void dispose() {
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();

    // Clear active chat
    _socketService.clearActiveChat();

    // Remove listeners
    _socketService.offMessageReceived();
    _socketService.offMessageSent();
    _socketService.offTypingIndicator();
    _socketService.offUserStatus();
    _socketService.offChatEnded();
    _socketService.socket?.off('broadcast:accepted');

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
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
                          color: AppColors.primaryPurple,
                        ),
                      )
                    : _buildMessagesList(),
              ),
              if (_isClientTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(200),
        border: Border(
          bottom: BorderSide(color: Colors.white.withAlpha(20)),
        ),
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          // Client avatar
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.cardMedium,
                backgroundImage: widget.clientPhoto != null
                    ? NetworkImage('${ApiEndpoints.socketUrl}${widget.clientPhoto}')
                    : null,
                child: widget.clientPhoto == null
                    ? Icon(Icons.person, color: AppColors.textSecondary)
                    : null,
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _isClientOnline ? Colors.green : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.cardDark, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.clientName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _isClientOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: _isClientOnline ? Colors.green : AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // End chat button
          GlassIconButton(
            icon: Icons.call_end,
            onTap: _endChat,
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
            Icon(Icons.chat_bubble_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Start the conversation',
              style: TextStyle(color: AppColors.textMuted, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['senderId'] == widget.astrologerId;
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isMe) {
    final content = message['content'] ?? '';
    final type = message['type'] ?? 'TEXT';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          gradient: isMe
              ? LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.deepPurple],
                )
              : null,
          color: isMe ? null : AppColors.cardMedium,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: type == 'IMAGE'
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  content.startsWith('http')
                      ? content
                      : '${ApiEndpoints.socketUrl}$content',
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      color: AppColors.cardDark,
                      child: Icon(Icons.broken_image, color: AppColors.textMuted),
                    );
                  },
                ),
              )
            : Text(
                content,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Text(
            '${widget.clientName} is typing',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          _buildDots(),
        ],
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Row(
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animation = (_typingAnimationController.value + delay) % 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withAlpha((animation * 255).toInt()),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardDark.withAlpha(200),
        border: Border(
          top: BorderSide(color: Colors.white.withAlpha(20)),
        ),
      ),
      child: Row(
        children: [
          // Image picker button
          GestureDetector(
            onTap: _isSendingImage ? null : _pickAndSendImage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cardMedium,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _isSendingImage
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : Icon(Icons.image, color: AppColors.textSecondary, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          // Text input
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              onChanged: _onTextChanged,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.cardMedium,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryPurple, AppColors.deepPurple],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
