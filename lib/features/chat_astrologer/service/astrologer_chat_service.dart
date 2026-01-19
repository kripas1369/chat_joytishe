import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../models/astrologer_chat_models.dart';

/// Astrologer Chat Service
/// Handles all HTTP API calls for astrologer chat functionality
class AstrologerChatService {
  static final AstrologerChatService _instance = AstrologerChatService._internal();
  factory AstrologerChatService() => _instance;
  AstrologerChatService._internal();

  Dio? _dio;
  bool _isInitialized = false;

  /// Initialize with authentication
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('astrologerAccessToken') ??
                        prefs.getString('accessToken');
    final refreshToken = prefs.getString('astrologerRefreshToken') ??
                         prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated');
    }

    _dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));

    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized || _dio == null) {
      throw Exception('AstrologerChatService not initialized. Call initialize() first.');
    }
  }

  // ============================================================
  // CONVERSATIONS
  // ============================================================

  /// Get all chat conversations for the astrologer
  Future<List<ConversationModel>> getConversations() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.chatConversations);
      if (response.statusCode == 200) {
        final data = response.data;
        final conversations = data['conversations'] ?? data['data'] ?? data['chats'] ?? [];
        return (conversations as List)
            .map((c) => ConversationModel.fromJson(c))
            .toList();
      }
      throw Exception('Failed to get conversations');
    } on DioException catch (e) {
      debugPrint('DioError getting conversations: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Get all chats (alternative endpoint)
  Future<List<ConversationModel>> getAllChats() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.chatEnd);
      if (response.statusCode == 200) {
        final data = response.data;
        final chats = data['chats'] ?? data['data'] ?? [];
        return (chats as List)
            .map((c) => ConversationModel.fromJson(c))
            .toList();
      }
      throw Exception('Failed to get chats');
    } on DioException catch (e) {
      debugPrint('DioError getting chats: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // CHAT HISTORY
  // ============================================================

  /// Get chat history with a specific user
  Future<ChatHistoryResponse> getChatHistory({
    required String otherUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    _checkInitialized();
    try {
      final response = await _dio!.get(
        '${ApiEndpoints.chatHistory}/$otherUserId',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200) {
        return ChatHistoryResponse.fromJson(response.data);
      }
      throw Exception('Failed to get chat history');
    } on DioException catch (e) {
      debugPrint('DioError getting chat history: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // BROADCAST MESSAGES
  // ============================================================

  /// Get pending broadcast messages
  Future<List<BroadcastMessageModel>> getPendingBroadcasts() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.broadcastMessagesPending);
      if (response.statusCode == 200) {
        final data = response.data;
        final messages = data['messages'] ?? data['data'] ?? data['broadcasts'] ?? [];
        return (messages as List)
            .map((m) => BroadcastMessageModel.fromJson(m))
            .toList();
      }
      throw Exception('Failed to get pending broadcasts');
    } on DioException catch (e) {
      debugPrint('DioError getting pending broadcasts: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Get all broadcast messages
  Future<List<BroadcastMessageModel>> getAllBroadcasts() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.broadcastMessagesAll);
      if (response.statusCode == 200) {
        final data = response.data;
        final messages = data['messages'] ?? data['data'] ?? data['broadcasts'] ?? [];
        return (messages as List)
            .map((m) => BroadcastMessageModel.fromJson(m))
            .toList();
      }
      throw Exception('Failed to get all broadcasts');
    } on DioException catch (e) {
      debugPrint('DioError getting all broadcasts: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Accept a broadcast message (HTTP fallback)
  Future<AcceptBroadcastResponse> acceptBroadcast(String messageId) async {
    _checkInitialized();
    try {
      final response = await _dio!.post(
        '${ApiEndpoints.broadcastMessagesAccept}/$messageId/accept',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AcceptBroadcastResponse.fromJson(response.data);
      }
      throw Exception('Failed to accept broadcast');
    } on DioException catch (e) {
      debugPrint('DioError accepting broadcast: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Dismiss a broadcast message
  Future<void> dismissBroadcast(String messageId) async {
    _checkInitialized();
    try {
      final response = await _dio!.post(
        '${ApiEndpoints.broadcastMessagesDismiss}/$messageId/dismiss',
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to dismiss broadcast');
      }
    } on DioException catch (e) {
      debugPrint('DioError dismissing broadcast: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // INSTANT CHAT REQUESTS
  // ============================================================

  /// Get pending instant chat requests
  Future<List<InstantChatRequestModel>> getPendingInstantChats() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.instantChatPending);
      if (response.statusCode == 200) {
        final data = response.data;
        final requests = data['requests'] ?? data['data'] ?? [];
        return (requests as List)
            .map((r) => InstantChatRequestModel.fromJson(r))
            .toList();
      }
      throw Exception('Failed to get pending instant chats');
    } on DioException catch (e) {
      debugPrint('DioError getting pending instant chats: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Accept an instant chat request (HTTP fallback)
  Future<AcceptInstantChatResponse> acceptInstantChat(String requestId) async {
    _checkInitialized();
    try {
      final response = await _dio!.post(
        '${ApiEndpoints.instantChatAccept}/$requestId',
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return AcceptInstantChatResponse.fromJson(response.data);
      }
      throw Exception('Failed to accept instant chat');
    } on DioException catch (e) {
      debugPrint('DioError accepting instant chat: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Get instant chat status (online/offline)
  Future<OnlineStatusResponse> getOnlineStatus() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.instantChatStatus);
      if (response.statusCode == 200) {
        return OnlineStatusResponse.fromJson(response.data);
      }
      throw Exception('Failed to get online status');
    } on DioException catch (e) {
      debugPrint('DioError getting online status: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  /// Toggle online/offline status
  Future<OnlineStatusResponse> toggleOnlineStatus() async {
    _checkInitialized();
    try {
      final response = await _dio!.post(ApiEndpoints.astrologerToggleOnline);
      if (response.statusCode == 200) {
        return OnlineStatusResponse.fromJson(response.data);
      }
      throw Exception('Failed to toggle online status');
    } on DioException catch (e) {
      debugPrint('DioError toggling online status: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // CLIENT PROFILE
  // ============================================================

  /// Get client details (birth info, zodiac, etc.)
  Future<ClientProfileModel> getClientProfile(String clientId) async {
    _checkInitialized();
    try {
      final response = await _dio!.get(
        '${ApiEndpoints.userDetails}/$clientId/details',
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final user = data['user'] ?? data['data'] ?? data;
        return ClientProfileModel.fromJson(user);
      }
      throw Exception('Failed to get client profile');
    } on DioException catch (e) {
      debugPrint('DioError getting client profile: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // CHATABLE USERS
  // ============================================================

  /// Get all chatable users (clients)
  Future<List<ChatableUserModel>> getChatableUsers() async {
    _checkInitialized();
    try {
      final response = await _dio!.get(ApiEndpoints.chatableUsers);
      if (response.statusCode == 200) {
        final data = response.data;
        final users = data['users'] ?? data['data'] ?? [];
        return (users as List)
            .map((u) => ChatableUserModel.fromJson(u))
            .toList();
      }
      throw Exception('Failed to get chatable users');
    } on DioException catch (e) {
      debugPrint('DioError getting chatable users: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // FILE UPLOAD
  // ============================================================

  /// Upload a file (image/document)
  Future<FileUploadResponse> uploadFile(String filePath, String receiverId) async {
    _checkInitialized();
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
        'receiverId': receiverId,
      });

      final response = await _dio!.post(
        ApiEndpoints.chatUploadFile,
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FileUploadResponse.fromJson(response.data);
      }
      throw Exception('Failed to upload file');
    } on DioException catch (e) {
      debugPrint('DioError uploading file: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // END CHAT
  // ============================================================

  /// End a chat session
  Future<void> endChat(String chatId) async {
    _checkInitialized();
    try {
      final response = await _dio!.put('${ApiEndpoints.chatEnd}/$chatId/end');
      if (response.statusCode != 200) {
        throw Exception('Failed to end chat');
      }
    } on DioException catch (e) {
      debugPrint('DioError ending chat: ${e.message}');
      throw Exception(_handleDioError(e));
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final data = e.response!.data;

      if (statusCode == 401) {
        return 'Session expired. Please login again.';
      } else if (statusCode == 403) {
        return 'You do not have permission for this action.';
      } else if (statusCode == 404) {
        return 'Resource not found.';
      } else if (data is Map && data['message'] != null) {
        return data['message'];
      }
      return 'Server error: $statusCode';
    }

    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Connection timeout. Please check your internet.';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Server took too long to respond.';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection.';
    }

    return e.message ?? 'Unknown error occurred';
  }
}
