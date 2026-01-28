import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/constants/constant.dart';
import 'package:chat_jyotishi/features/app_widgets/glass_icon_button.dart';
import 'package:chat_jyotishi/features/app_widgets/star_field_background.dart';
import 'package:chat_jyotishi/features/chat/service/chat_lock_service.dart';
import 'package:chat_jyotishi/features/chat/service/socket_service.dart';
import 'package:chat_jyotishi/features/chat/screens/service_inquiry_screen.dart';
import 'package:chat_jyotishi/features/payment/services/coin_service.dart';
import 'package:chat_jyotishi/features/payment/services/coin_provider.dart';
import 'package:chat_jyotishi/features/payment/widgets/insufficient_coins_sheet.dart';
import 'package:chat_jyotishi/features/payment/models/coin_models.dart';
import 'package:chat_jyotishi/features/chat/widgets/astrologer_profile_sheet.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final ChatLockService _chatLockService = ChatLockService();
  final CoinService _coinService = CoinService();
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
  Timer? _timeoutCheckTimer;

  // Chat lock state
  bool _isChatLocked = false;
  bool _canSendMessage = true;
  int _coinBalance = 0;

  // Actual chat ID (may be updated from server response)
  late String _actualChatId;

  // Chat session ended state
  bool _isChatEnded = false;

  // Animation controllers
  late AnimationController _typingAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _actualChatId = widget.chatId;
    _isOtherUserOnline = widget.isOnline;

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initializeDio();
    _registerSocketListeners();
    _checkLocalEndedState();
    _loadChatHistory();
    _loadLockStatus();
    _loadCoinBalance();
    _startTimeoutChecker();
  }

  Future<void> _checkLocalEndedState() async {
    final prefs = await SharedPreferences.getInstance();
    final endedKey = 'chat_ended_${widget.otherUserId}';
    final isEnded = prefs.getBool(endedKey) ?? false;

    if (isEnded && mounted) {
      setState(() {
        _isChatEnded = true;
      });
    }
  }

  Future<void> _saveEndedStateLocally(bool isEnded) async {
    final prefs = await SharedPreferences.getInstance();
    final endedKey = 'chat_ended_${widget.otherUserId}';

    if (isEnded) {
      await prefs.setBool(endedKey, true);
    } else {
      await prefs.remove(endedKey);
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
      debugPrint('Error loading coin balance: $e');
      final balance = await _coinService.getBalance();
      if (mounted) {
        setState(() => _coinBalance = balance);
      }
    }
  }

  Future<void> _loadLockStatus() async {
    final locked = await _chatLockService.isLocked();
    final canSend = await _chatLockService.canSendMessageInChat(
      widget.otherUserId,
    );
    if (mounted) {
      setState(() {
        _isChatLocked = locked;
        _canSendMessage = canSend;
      });
    }
  }

  void _startTimeoutChecker() {
    _timeoutCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkTimeout(),
    );
  }

  Future<void> _checkTimeout() async {
    if (!_isChatLocked) return;

    final hasExceeded = await _chatLockService.hasExceededTimeout();
    final lockedJyotishId = await _chatLockService.getLockedJyotishId();

    if (hasExceeded && lockedJyotishId == widget.otherUserId && mounted) {
      _showTimeoutInquiryOption();
    }
  }

  void _showTimeoutInquiryOption() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.3),
                    AppColors.cosmicPink.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.orange, Colors.deepOrange],
                    ).createShader(bounds),
                    child: const Text(
                      'Taking too long?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${widget.otherUserName} hasn\'t responded yet.\nWould you like to send an inquiry?',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textGray300,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Keep Waiting',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToInquiryScreen();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.orange, Colors.deepOrange],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Send Inquiry',
                                style: TextStyle(
                                  color: Colors.white,
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
        ),
      ),
    );
  }

  void _navigateToInquiryScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ServiceInquiryScreen(
          jyotishName: widget.otherUserName,
          jyotishId: widget.otherUserId,
        ),
      ),
    );
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
    _unregisterSocketListeners();
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

          Future.delayed(Duration.zero, () {
            _handleJyotishReply(senderId);
          });
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

    _socketService.onChatError((data) {
      debugPrint('Chat error received: $data');
      final errorCode = data['code']?.toString();
      final errorMessage = data['message']?.toString() ?? 'An error occurred';

      if (InsufficientCoinsException.isInsufficientCoinsError(
        errorCode,
        errorMessage,
      )) {
        final required = InsufficientCoinsException.extractRequiredCoins(
          errorMessage,
        );
        final available = InsufficientCoinsException.extractAvailableCoins(
          errorMessage,
        );

        if (mounted) {
          showInsufficientCoinsSheet(
            context: context,
            requiredCoins: required,
            availableCoins: available > 0 ? available : coinProvider.balance,
            message: errorMessage,
          ).then((_) => _loadCoinBalance());
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.cosmicRed,
            ),
          );
        }
      }
    });

    _socketService.onChatEnded((data) {
      final eventChatId = data['chatId']?.toString() ?? '';
      final currentChatId = _actualChatId.isNotEmpty
          ? _actualChatId
          : widget.chatId;

      if (eventChatId == currentChatId && mounted) {
        _showChatEndedDialog();
      }
    });
  }

  Future<void> _handleJyotishReply(String jyotishId) async {
    final isFromLockedJyotish = await _chatLockService.isReplyFromLockedJyotish(
      jyotishId,
    );

    if (isFromLockedJyotish) {
      await _chatLockService.unlockChats();

      if (mounted) {
        setState(() {
          _isChatLocked = false;
          _canSendMessage = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${widget.otherUserName} has replied!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }

      await _loadLockStatus();
    }
  }

  Future<void> _loadChatHistory() async {
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '${ApiEndpoints.chatHistory}/${widget.otherUserId}',
        queryParameters: {'limit': 50},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        String? chatId;
        if (data['chatId'] != null) {
          chatId = data['chatId'].toString();
        } else if (data['chat'] != null && data['chat']['id'] != null) {
          chatId = data['chat']['id'].toString();
        } else if (data['id'] != null) {
          chatId = data['id'].toString();
        }

        if (chatId != null && chatId.isNotEmpty) {
          _actualChatId = chatId;
        }

        String? chatStatus;
        if (data['status'] != null) {
          chatStatus = data['status'].toString().toUpperCase();
        } else if (data['chat'] != null && data['chat']['status'] != null) {
          chatStatus = data['chat']['status'].toString().toUpperCase();
        } else if (data['data'] != null && data['data'] is Map) {
          final chatData = data['data'];
          if (chatData['status'] != null) {
            chatStatus = chatData['status'].toString().toUpperCase();
          } else if (chatData['chat'] != null &&
              chatData['chat']['status'] != null) {
            chatStatus = chatData['chat']['status'].toString().toUpperCase();
          }
        }

        if (chatStatus == 'ENDED' ||
            chatStatus == 'CLOSED' ||
            chatStatus == 'INACTIVE') {
          if (mounted) {
            setState(() {
              _isChatEnded = true;
            });
          }
        } else {
          if (mounted && _isChatEnded) {
            setState(() {
              _isChatEnded = false;
            });
          }
        }

        final messagesList = data['data'] ?? data['messages'] ?? [];
        if (messagesList is List && messagesList.isNotEmpty) {
          final loadedMessages = messagesList
              .map((m) => Map<String, dynamic>.from(m))
              .toList();

          if (_actualChatId.isEmpty && loadedMessages.isNotEmpty) {
            final firstMsgChatId = loadedMessages.first['chatId'];
            if (firstMsgChatId != null &&
                firstMsgChatId.toString().isNotEmpty) {
              _actualChatId = firstMsgChatId.toString();
            }
          }

          loadedMessages.sort((a, b) {
            final aTime =
                DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
            final bTime =
                DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
            return bTime.compareTo(aTime);
          });
          if (mounted) setState(() => _messages = loadedMessages);

          await _updateLockStatusFromHistory(loadedMessages);
        } else {
          if (mounted) {
            setState(() {
              _canSendMessage = true;
              _isChatLocked = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to load chat: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateLockStatusFromHistory(
    List<Map<String, dynamic>> messages,
  ) async {
    if (messages.isEmpty) {
      if (mounted) {
        setState(() {
          _canSendMessage = true;
          _isChatLocked = false;
        });
      }
      await _chatLockService.unlockChats();
      return;
    }

    final lastMessage = messages.first;
    final lastSenderId =
        lastMessage['senderId'] ?? lastMessage['sender']?['id'];

    if (lastSenderId == widget.currentUserId) {
      if (mounted) {
        setState(() {
          _canSendMessage = false;
          _isChatLocked = true;
        });
      }
    } else if (lastSenderId == widget.otherUserId) {
      if (mounted) {
        setState(() {
          _canSendMessage = true;
          _isChatLocked = false;
        });
      }
      await _chatLockService.unlockChats();
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (!_canSendMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please wait for Jyotish to reply before sending another message.',
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    const int messageCost = CoinCosts.ordinaryChat;

    final currentBalance = coinProvider.balance;
    if (currentBalance < messageCost) {
      if (mounted) {
        await showInsufficientCoinsSheet(
          context: context,
          requiredCoins: messageCost,
          availableCoins: currentBalance,
          message: 'You need $messageCost coins to send a message.',
        );
        await _loadCoinBalance();
      }
      return;
    }

    final savedContent = content;
    _messageController.clear();
    _stopTyping();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    setState(() {
      _messages.insert(0, {
        'id': tempId,
        'content': savedContent,
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
      content: savedContent,
      type: 'TEXT',
    );

    coinProvider.localDeduct(messageCost);
    if (mounted) {
      setState(() => _coinBalance = coinProvider.balance);
    }

    await _chatLockService.lockChats(
      widget.otherUserId,
      jyotishName: widget.otherUserName,
    );
    if (mounted) {
      setState(() {
        _isChatLocked = true;
        _canSendMessage = false;
      });
    }
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
            content: const Text('Failed to pick image'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    }
  }

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
            content: const Text('Failed to take photo'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    }
  }

  Future<void> _uploadAndSendImage(File imageFile) async {
    if (!imageFile.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Image file not found'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
      return;
    }

    setState(() => _isSendingImage = true);

    final tempId = 'temp_img_${DateTime.now().millisecondsSinceEpoch}';
    final fileName = path.basename(imageFile.path);
    final fileSize = await imageFile.length();

    final extension = path.extension(imageFile.path).toLowerCase();
    String mimeType = 'image/jpeg';
    if (extension == '.png') {
      mimeType = 'image/png';
    } else if (extension == '.gif') {
      mimeType = 'image/gif';
    } else if (extension == '.webp') {
      mimeType = 'image/webp';
    }

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
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
      });

      final response = await _dio.post(
        ApiEndpoints.chatUploadFile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
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

          if (fileUrl != null && fileUrl.startsWith('/')) {
            fileUrl = '${ApiEndpoints.socketUrl}$fileUrl';
          }
        }

        if (fileUrl != null && fileUrl.isNotEmpty) {
          setState(() {
            final index = _messages.indexWhere((m) => m['id'] == tempId);
            if (index != -1) {
              _messages[index]['content'] = fileUrl;
              _messages[index]['isSending'] = false;
            }
          });

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
            content: const Text('Failed to upload image'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('General upload error: $e');
      setState(() => _messages.removeWhere((m) => m['id'] == tempId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to send image'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    } finally {
      setState(() => _isSendingImage = false);
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cosmicPurple.withOpacity(0.3),
                  AppColors.cosmicPink.withOpacity(0.2),
                  Colors.black.withOpacity(0.9),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(
                color: AppColors.cosmicPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.purple300, AppColors.pink300],
                  ).createShader(bounds),
                  child: const Text(
                    'Share Media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      gradient: const LinearGradient(
                        colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndSendImage();
                      },
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded,
                      label: 'Camera',
                      gradient: const LinearGradient(
                        colors: [AppColors.cosmicPink, AppColors.cosmicRed],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _takePhotoAndSend();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textGray300,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _unregisterSocketListeners() {
    _socketService.offMessageReceived();
    _socketService.offMessageSent();
    _socketService.offTypingIndicator();
    _socketService.offUserStatus();
    _socketService.offChatEnded();
    _socketService.offChatError();
  }

  void _showChatEndedDialog() {
    if (mounted) {
      setState(() {
        _isChatEnded = true;
      });
    }
  }

  void _showChatAgainPopupAfterEnd() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.32),
                    AppColors.cosmicPink.withOpacity(0.22),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.45),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.35),
                          blurRadius: 18,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    ).createShader(bounds),
                    child: const Text(
                      'Chat ended',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Do you want to chat again with this astrologer?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGray300,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context); // close dialog
                            Navigator.pop(this.context, {
                              'chatEnded': true,
                              'jyotishId': widget.otherUserId,
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Close',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context); // close dialog
                            await _reactivateChat();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.cosmicPurple,
                                  AppColors.cosmicPink,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cosmicPurple.withOpacity(
                                    0.4,
                                  ),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Chat Again',
                                style: TextStyle(
                                  color: Colors.white,
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
        ),
      ),
    );
  }

  Future<void> _reactivateChat() async {
    try {
      if (mounted) {
        setState(() => _isLoading = true);
      }

      final String apiUrl = '${ApiEndpoints.baseUrl}${ApiEndpoints.chatCreate}';

      final response = await _dio.post(
        apiUrl,
        data: {'participantId': widget.otherUserId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;

        String? newChatId;
        if (data is Map) {
          if (data['id'] != null) {
            newChatId = data['id'].toString();
          } else if (data['chat'] != null && data['chat']['id'] != null) {
            newChatId = data['chat']['id'].toString();
          } else if (data['data'] != null) {
            final chatData = data['data'];
            if (chatData is Map && chatData['id'] != null) {
              newChatId = chatData['id'].toString();
            } else if (chatData is Map && chatData['chat'] != null) {
              newChatId = chatData['chat']['id']?.toString();
            }
          }
        }

        if (newChatId != null && newChatId.isNotEmpty) {
          _actualChatId = newChatId;
        }

        await _chatLockService.unlockChats();
        await _saveEndedStateLocally(false);

        if (mounted) {
          setState(() {
            _isChatEnded = false;
            _isChatLocked = false;
            _canSendMessage = true;
            _isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text('Chat started! You can message now.'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          await _loadChatHistory();
        }
      }
    } on DioException catch (e) {
      debugPrint('Error reactivating chat: ${e.response?.data}');
      if (mounted) {
        setState(() => _isLoading = false);

        String errorMsg = 'Failed to start chat. Please try again.';
        if (e.response?.data != null && e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'].toString() ?? errorMsg;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error reactivating chat: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to start chat. Please try again.'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    }
  }

  void _showAstrologerProfile() {
    showAstrologerProfileSheet(
      context: context,
      astrologerId: widget.otherUserId,
      astrologerName: widget.otherUserName,
      astrologerPhoto: widget.otherUserPhoto,
      isOnline: _isOtherUserOnline,
    );
  }

  void _endChat() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.cosmicPurple.withOpacity(0.3),
                    AppColors.cosmicPink.withOpacity(0.2),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withOpacity(0.4),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green, Colors.green.shade700],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [Colors.green, Colors.green.shade300],
                    ).createShader(bounds),
                    child: const Text(
                      'End Chat?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you sure you want to end this chat session?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textGray300,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textGray300,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            Navigator.pop(context);
                            await _performEndChat();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.green, Colors.green.shade700],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.white,
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
        ),
      ),
    );
  }

  Future<void> _performEndChat() async {
    try {
      final chatId = _actualChatId.isNotEmpty ? _actualChatId : widget.chatId;

      if (chatId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No active chat to end.'),
              backgroundColor: Colors.orange.shade700,
            ),
          );
        }
        return;
      }

      await _dio.put('${ApiEndpoints.chatEnd}/$chatId/end');
      await _chatLockService.unlockChats();
      await _saveEndedStateLocally(true);

      if (mounted) {
        setState(() {
          _isChatEnded = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Chat ended successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        _showChatAgainPopupAfterEnd();
      }
    } on DioException catch (e) {
      debugPrint('Error ending chat: ${e.response?.data}');
      String errorMessage = 'Failed to end chat. Please try again.';
      if (e.response?.statusCode == 404) {
        errorMessage = 'Chat not found or already ended.';
      } else if (e.response?.data?['message'] != null) {
        errorMessage = e.response?.data['message'];
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error ending chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to end chat. Please try again.'),
            backgroundColor: AppColors.cosmicRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _timeoutCheckTimer?.cancel();
    _unregisterSocketListeners();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _setSystemUIOverlay();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.primaryBlack,
        body: Stack(
          children: [
            // Star field background
            const StarFieldBackground(),
            // Cosmic gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    AppColors.cosmicPurple.withOpacity(0.2),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  _buildCoinNoticeBanner(),
                  if (_isChatLocked) _buildLockStatusBanner(),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const CircularProgressIndicator(
                                color: AppColors.cosmicPurple,
                              ),
                            ),
                          )
                        : _buildMessagesList(),
                  ),
                  if (_isOtherUserTyping) _buildTypingIndicator(),
                  if (_isChatEnded) _buildChatAgainBar() else _buildInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setSystemUIOverlay() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.primaryBlack,
      ),
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.2),
                Colors.black.withOpacity(0.5),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.3),
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
              const SizedBox(width: 12),
              // Tappable profile section
              Expanded(
                child: GestureDetector(
                  onTap: _showAstrologerProfile,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      // Avatar with cosmic border
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: _isOtherUserOnline
                                ? [Colors.greenAccent, Colors.green]
                                : [
                                    AppColors.cosmicPurple,
                                    AppColors.cosmicPink,
                                  ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (_isOtherUserOnline
                                          ? Colors.greenAccent
                                          : AppColors.cosmicPurple)
                                      .withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlack,
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.cosmicPurple.withOpacity(
                              0.3,
                            ),
                            backgroundImage:
                                widget.otherUserPhoto != null &&
                                    widget.otherUserPhoto!.isNotEmpty
                                ? NetworkImage(
                                    widget.otherUserPhoto!.startsWith('http')
                                        ? widget.otherUserPhoto!
                                        : '${ApiEndpoints.socketUrl}${widget.otherUserPhoto}',
                                  )
                                : null,
                            child:
                                widget.otherUserPhoto == null ||
                                    widget.otherUserPhoto!.isEmpty
                                ? Text(
                                    widget.otherUserName.isNotEmpty
                                        ? widget.otherUserName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: ShaderMask(
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                          colors: [
                                            AppColors.purple300,
                                            AppColors.pink300,
                                          ],
                                        ).createShader(bounds),
                                    child: Text(
                                      widget.otherUserName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 16,
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _isOtherUserTyping
                                        ? AppColors.cosmicPink
                                        : _isOtherUserOnline
                                        ? Colors.greenAccent
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                    boxShadow:
                                        _isOtherUserTyping || _isOtherUserOnline
                                        ? [
                                            BoxShadow(
                                              color:
                                                  (_isOtherUserTyping
                                                          ? AppColors.cosmicPink
                                                          : Colors.greenAccent)
                                                      .withOpacity(0.6),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isOtherUserTyping
                                      ? 'typing...'
                                      : _isOtherUserOnline
                                      ? 'Online'
                                      : 'Offline',
                                  style: TextStyle(
                                    color: _isOtherUserTyping
                                        ? AppColors.cosmicPink
                                        : _isOtherUserOnline
                                        ? Colors.greenAccent
                                        : AppColors.textGray400,
                                    fontSize: 12,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icons.refresh_rounded,
                onTap: _loadChatHistory,
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icons.check_circle_outline,
                onTap: _endChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoinNoticeBanner() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withOpacity(0.15),
                Colors.deepOrange.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  '1 coin per message',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.orange.withOpacity(0.3),
                      Colors.deepOrange.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: gold, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_coinBalance',
                      style: const TextStyle(
                        color: gold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockStatusBanner() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.cosmicPurple.withOpacity(0.15),
                AppColors.cosmicPink.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.cosmicPink,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Waiting for ${widget.otherUserName} to reply...',
                  style: const TextStyle(
                    color: AppColors.cosmicPink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _navigateToInquiryScreen,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cosmicPurple.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'Inquiry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cosmicPurple.withOpacity(0.3),
                          AppColors.cosmicPink.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.cosmicPurple.withOpacity(0.4),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cosmicPurple.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 52,
                      color: AppColors.cosmicPink,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppColors.purple300, AppColors.pink300],
              ).createShader(bounds),
              child: const Text(
                'Start the conversation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Say hi to ${widget.otherUserName}!',
              style: const TextStyle(
                color: AppColors.textGray300,
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message['senderId'] == widget.currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
                ? const EdgeInsets.all(4)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            decoration: BoxDecoration(
              gradient: isMe
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.08),
                      ],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 6),
                bottomRight: Radius.circular(isMe ? 6 : 20),
              ),
              border: isMe
                  ? null
                  : Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: isMe
                      ? AppColors.cosmicPurple.withOpacity(0.4)
                      : Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: type == 'IMAGE'
                ? _buildImageMessage(content, message['localPath'], isSending)
                : Text(
                    content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textGray200,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message['createdAt']),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 5),
                  isSending
                      ? SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.cosmicPink.withOpacity(0.7),
                          ),
                        )
                      : Icon(
                          message['isRead'] == true
                              ? Icons.done_all_rounded
                              : Icons.done_rounded,
                          size: 16,
                          color: message['isRead'] == true
                              ? Colors.greenAccent
                              : Colors.white.withOpacity(0.5),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
              ),
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.primaryBlack,
              backgroundImage:
                  widget.otherUserPhoto != null &&
                      widget.otherUserPhoto!.isNotEmpty
                  ? NetworkImage(
                      widget.otherUserPhoto!.startsWith('http')
                          ? widget.otherUserPhoto!
                          : '${ApiEndpoints.socketUrl}${widget.otherUserPhoto}',
                    )
                  : null,
              child:
                  widget.otherUserPhoto == null ||
                      widget.otherUserPhoto!.isEmpty
                  ? Text(
                      widget.otherUserName.isNotEmpty
                          ? widget.otherUserName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cosmicPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(1),
                const SizedBox(width: 4),
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
              gradient: const LinearGradient(
                colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cosmicPink.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatAgainBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.2),
                Colors.black.withOpacity(0.8),
              ],
            ),
            border: Border(
              top: BorderSide(color: Colors.orange.withOpacity(0.4), width: 1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'This chat session has ended',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _reactivateChat,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.cosmicPurple, AppColors.cosmicPink],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.cosmicPurple.withOpacity(0.5),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Chat Again',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final bool isDisabled = !_canSendMessage;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.cosmicPurple.withOpacity(0.15),
                Colors.black.withOpacity(0.8),
              ],
            ),
            border: Border(
              top: BorderSide(
                color: AppColors.cosmicPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              GestureDetector(
                onTap: (_isSendingImage || isDisabled)
                    ? null
                    : _showAttachmentOptions,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isDisabled
                        ? LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.3),
                              Colors.grey.withOpacity(0.2),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              AppColors.cosmicPurple.withOpacity(0.3),
                              AppColors.cosmicPink.withOpacity(0.2),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDisabled
                          ? Colors.grey.withOpacity(0.3)
                          : AppColors.cosmicPurple.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: _isSendingImage
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.cosmicPink,
                          ),
                        )
                      : Icon(
                          Icons.add_photo_alternate_rounded,
                          color: isDisabled
                              ? Colors.grey
                              : AppColors.cosmicPink,
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Message input field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.cosmicPurple.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTyping,
                    enabled: !isDisabled,
                    cursorColor: AppColors.cosmicPink,
                    style: TextStyle(
                      color: isDisabled
                          ? Colors.white.withOpacity(0.4)
                          : Colors.white,
                      fontSize: 15,
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isDisabled
                          ? 'Waiting for reply...'
                          : 'Type a message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 15,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Send button
              GestureDetector(
                onTap: isDisabled ? null : _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isDisabled
                        ? LinearGradient(
                            colors: [
                              Colors.grey.withOpacity(0.5),
                              Colors.grey.withOpacity(0.4),
                            ],
                          )
                        : const LinearGradient(
                            colors: [
                              AppColors.cosmicPurple,
                              AppColors.cosmicPink,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isDisabled
                        ? []
                        : [
                            BoxShadow(
                              color: AppColors.cosmicPurple.withOpacity(0.5),
                              blurRadius: 12,
                              spreadRadius: 2,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: Icon(
                    isDisabled ? Icons.lock_rounded : Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
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
              color: AppColors.cosmicPurple.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                    : null,
                color: AppColors.cosmicPink,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: AppColors.cosmicPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
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
          color: AppColors.cosmicPurple.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.image_rounded, color: Colors.white38, size: 48),
      );
    }

    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(16), child: imageWidget),
        if (isSending)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.cosmicPink,
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
