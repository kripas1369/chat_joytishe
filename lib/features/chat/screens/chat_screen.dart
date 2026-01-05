import 'dart:async';
import 'dart:io';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/chat/widgets/profile_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

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
      debugPrint('Failed to load chat: $e');
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

  /// Pick image from gallery and send
  Future<void> _pickAndSendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        await _uploadAndSendImage(File(image.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Take photo with camera and send
  Future<void> _takePhotoAndSend() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo != null) {
        await _uploadAndSendImage(File(photo.path));
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload image to server and send via socket
  Future<void> _uploadAndSendImage(File imageFile) async {
    if (!imageFile.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image file not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isSendingImage = true);

    final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
    final fileName = path.basename(imageFile.path);
    final fileSize = await imageFile.length();

    // Determine content type from extension
    final extension = path.extension(imageFile.path).toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == '.png') {
      mimeType = 'image/png';
    } else if (extension == '.gif') {
      mimeType = 'image/gif';
    } else if (extension == '.webp') {
      mimeType = 'image/webp';
    }

    // Add temp message to show upload progress
    setState(() {
      _messages.insert(0, {
        'id': tempId,
        'content': imageFile.path,
        'senderId': widget.currentUserId,
        'receiverId': widget.otherUserId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
        'type': 'IMAGE',
        'isSending': true,
        'localPath': imageFile.path,
      });
    });
    _scrollToBottom();

    try {
      // Create FormData with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      // Make the upload request
      final response = await _dio.post(
        ApiEndpoints.chatUploadFile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Extract file URL from response
        String? fileUrl;
        final responseData = response.data;

        if (responseData is Map) {
          final data = responseData['data'];
          if (data is Map) {
            if (data['file'] is Map) {
              fileUrl = data['file']['url'] as String?;
            }
            fileUrl ??= data['url'] as String?;
            fileUrl ??= data['fileUrl'] as String?;
            fileUrl ??= data['path'] as String?;
          }
          fileUrl ??= responseData['url'] as String?;
          fileUrl ??= responseData['fileUrl'] as String?;

          // If URL is relative, prepend base URL
          if (fileUrl != null && fileUrl.startsWith('/')) {
            fileUrl = '${ApiEndpoints.socketUrl}$fileUrl';
          }
        }

        if (fileUrl != null && fileUrl.isNotEmpty) {
          // Update temp message
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == tempId);
            if (index != -1) {
              _messages[index]['content'] = fileUrl;
              _messages[index]['isSending'] = false;
            }
          });

          // Send via socket
          _socketService.sendMessage(
            receiverId: widget.otherUserId,
            content: fileUrl,
            type: 'IMAGE',
            metadata: {
              'fileName': fileName,
              'fileSize': fileSize,
              'mimeType': mimeType,
            },
          );
        } else {
          throw Exception('Server did not return file URL');
        }
      } else {
        throw Exception('Upload failed with status ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Upload error: ${e.message}');
      setState(() => _messages.removeWhere((m) => m['id'] == tempId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('General upload error: $e');
      setState(() => _messages.removeWhere((m) => m['id'] == tempId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSendingImage = false);
    }
  }

  /// Show attachment options bottom sheet
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.cardDark,
              AppColors.backgroundDark,
            ],
          ),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            SizedBox(height: 24),
            Text(
              'Share Media',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.primaryPurple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhotoAndSend();
                  },
                ),
              ],
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.3),
                  color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
    // Build proper image URL
    String imageUrl = '';
    if (widget.otherUserPhoto != null && widget.otherUserPhoto!.isNotEmpty) {
      if (widget.otherUserPhoto!.startsWith('http')) {
        imageUrl = widget.otherUserPhoto!;
      } else {
        imageUrl = '${ApiEndpoints.baseUrl}${widget.otherUserPhoto}';
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cardDark.withOpacity(0.8),
            AppColors.backgroundDark.withOpacity(0.6),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.pop(context),
          ),
          SizedBox(width: 12),
          // Profile image with online status
          Stack(
            children: [
              Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isOtherUserOnline
                      ? LinearGradient(
                          colors: [Colors.green, Colors.greenAccent],
                        )
                      : LinearGradient(
                          colors: [Colors.grey, Colors.grey.shade600],
                        ),
                ),
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundDark,
                  ),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.cardMedium,
                    backgroundImage:
                        imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty
                        ? Text(
                            widget.otherUserName.isNotEmpty
                                ? widget.otherUserName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
              // Online indicator dot
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color:
                        _isOtherUserOnline ? Colors.greenAccent : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.backgroundDark,
                      width: 2,
                    ),
                    boxShadow: _isOtherUserOnline
                        ? [
                            BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOtherUserOnline
                            ? Colors.greenAccent
                            : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      _isOtherUserTyping
                          ? 'typing...'
                          : _isOtherUserOnline
                              ? 'Active now'
                              : 'Offline',
                      style: TextStyle(
                        color: _isOtherUserTyping
                            ? AppColors.primaryPurple
                            : _isOtherUserOnline
                                ? Colors.greenAccent
                                : Colors.white54,
                        fontSize: 13,
                        fontWeight: _isOtherUserTyping
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Refresh button only
          GlassIconButton(
            icon: Icons.refresh_rounded,
            onTap: _loadChatHistory,
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
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.2),
                    AppColors.deepPurple.withOpacity(0.1),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.3),
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
              'Start the conversation',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Say hi to ${widget.otherUserName}!',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Send a message or share an image',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 13,
              ),
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
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: type == 'IMAGE'
                ? EdgeInsets.all(4)
                : EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryPurple,
                        AppColors.deepPurple,
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85),
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? AppColors.primaryPurple.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: type == 'IMAGE'
                ? _buildImageMessage(content, message['localPath'], isSending)
                : Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message['createdAt']),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white54,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 5),
                  isSending
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: Colors.white54,
                          ),
                        )
                      : Icon(
                          message['isRead'] == true
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 16,
                          color: message['isRead'] == true
                              ? Colors.greenAccent
                              : Colors.white54,
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Small avatar
          Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primaryPurple, AppColors.deepPurple],
              ),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.cardDark,
              backgroundImage: widget.otherUserPhoto != null &&
                      widget.otherUserPhoto!.isNotEmpty
                  ? NetworkImage(
                      widget.otherUserPhoto!.startsWith('http')
                          ? widget.otherUserPhoto!
                          : '${ApiEndpoints.baseUrl}${widget.otherUserPhoto}',
                    )
                  : null,
              child: widget.otherUserPhoto == null ||
                      widget.otherUserPhoto!.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          SizedBox(width: 10),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.15),
                  Colors.white.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                SizedBox(width: 4),
                _buildTypingDot(1),
                SizedBox(width: 4),
                _buildTypingDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        final value = (_typingAnimationController.value + index * 0.2) % 1.0;
        final scale = 0.5 + (0.5 * (1 - (2 * value - 1).abs()));
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.primaryPurple,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.backgroundDark.withOpacity(0.8),
            AppColors.cardDark,
          ],
        ),
        border: Border(
          top: BorderSide(
            color: AppColors.primaryPurple.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attachment button (camera/gallery)
          GestureDetector(
            onTap: _isSendingImage ? null : _showAttachmentOptions,
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryPurple.withOpacity(0.3),
                    AppColors.deepPurple.withOpacity(0.2),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primaryPurple.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: _isSendingImage
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primaryPurple,
                      ),
                    )
                  : Icon(
                      Icons.add_photo_alternate_rounded,
                      color: AppColors.primaryPurple,
                      size: 22,
                    ),
            ),
          ),
          SizedBox(width: 12),
          // Message input field
          Expanded(
            child: Container(
              constraints: BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                onChanged: _handleTyping,
                cursorColor: AppColors.primaryPurple,
                style: TextStyle(color: Colors.white, fontSize: 15),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: "Type a message...",
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 15),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Send button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPurple.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageMessage(String url, String? localPath, bool isSending) {
    Widget imageWidget;

    if (localPath != null && File(localPath).existsSync()) {
      imageWidget = Image.file(
        File(localPath),
        width: 220,
        height: 220,
        fit: BoxFit.cover,
      );
    } else if (url.startsWith('http')) {
      imageWidget = Image.network(
        url,
        width: 220,
        height: 220,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                    : null,
                color: AppColors.primaryPurple,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
              SizedBox(height: 8),
              Text(
                'Failed to load',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    } else {
      imageWidget = Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.image_rounded, color: Colors.white38, size: 48),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: imageWidget,
        ),
        if (isSending)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
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
