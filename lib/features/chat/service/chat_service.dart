import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';

class ChatService {
  Future<Map<String, dynamic>> fetchActiveAstrologers() async {
    final url = Uri.parse(ApiEndpoints.getActiveAstrologers);
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        "Cookie": "accessToken=$accessToken; refreshToken=$refreshToken",
      },
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    if (accessToken == null) {
      throw Exception('Access token missing');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Please login again');
    } else {
      throw Exception(
        'Failed to load active astrologers: ${response.statusCode}',
      );
    }
  }

  // Future<Map<String, dynamic>> fetchAstrologerProfile(
  //   String astrologerId,
  // ) async {
  //   final url = Uri.parse('${ApiEndpoints.getAstrologerProfile}/$astrologerId');
  //   final prefs = await SharedPreferences.getInstance();
  //   final accessToken = prefs.getString('accessToken');
  //
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $accessToken',
  //     },
  //   );
  //
  //   debugPrint('@@@@ Fetch Astrologer Profile @@@@');
  //   debugPrint('Status: ${response.statusCode}');
  //   debugPrint('Body: ${response.body}');
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else if (response.statusCode == 404) {
  //     throw Exception('Astrologer not found');
  //   } else if (response.statusCode == 401) {
  //     throw Exception('Unauthorized - Please login again');
  //   } else {
  //     throw Exception(
  //       'Failed to load astrologer profile: ${response.statusCode}',
  //     );
  //   }
  // }

  // Future<Map<String, dynamic>> fetchChatList() async {
  //   final url = Uri.parse(ApiEndpoints.getChatList);
  //   final prefs = await SharedPreferences.getInstance();
  //   final accessToken = prefs.getString('accessToken');
  //
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  //     },
  //   );
  //
  //   debugPrint('Response Status: ${response.statusCode}');
  //   debugPrint('Response Body: ${response.body}');
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else if (response.statusCode == 401) {
  //     throw Exception('Unauthorized - Please login again');
  //   } else {
  //     throw Exception('Failed to load chat list: ${response.statusCode}');
  //   }
  // }

  /// Chat Service - REST API
  /// Handles chat history, conversations, file uploads via HTTP

  static final ChatService _instance = ChatService._internal();

  factory ChatService() => _instance;

  ChatService._internal();

  late Dio _dio;
  bool _isInitialized = false;

  /// Initialize with Dio instance (pass from AuthService)
  void initialize(Dio dio) {
    _dio = dio;
    _isInitialized = true;
  }

  void _checkInitialized() {
    if (!_isInitialized) {
      throw Exception('ChatService not initialized. Call initialize() first.');
    }
  }

  /// Get all conversations
  Future<List<dynamic>> getConversations() async {
    _checkInitialized();
    try {
      final response = await _dio.get(ApiEndpoints.chatConversations);
      if (response.statusCode == 200) {
        return response.data['data'] as List;
      }
      throw Exception('Failed to get conversations');
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get or create chat with another user
  Future<Map<String, dynamic>> getOrCreateChat(String otherUserId) async {
    _checkInitialized();
    try {
      final response = await _dio.post(
        ApiEndpoints.chatChats,
        data: {'otherUserId': otherUserId},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data['data'];
      }
      throw Exception('Failed to create chat');
    } catch (e) {
      throw Exception('Failed to create chat: $e');
    }
  }

  /// Get chat by ID
  Future<Map<String, dynamic>> getChatById(String chatId) async {
    _checkInitialized();
    try {
      final response = await _dio.get('${ApiEndpoints.chatChats}/$chatId');
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Chat not found');
    } catch (e) {
      throw Exception('Failed to get chat: $e');
    }
  }

  /// Get chat history with pagination
  Future<List<dynamic>> getChatHistory({
    required String otherUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    _checkInitialized();
    try {
      final response = await _dio.get(
        '${ApiEndpoints.chatHistory}/$otherUserId',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200) {
        return response.data['data'] as List;
      }
      throw Exception('Failed to get chat history');
    } catch (e) {
      throw Exception('Failed to get chat history: $e');
    }
  }

  /// Send message (HTTP fallback - prefer Socket.IO)
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String receiverId,
    required String content,
    String type = 'TEXT',
    Map<String, dynamic>? metadata,
  }) async {
    _checkInitialized();
    try {
      final response = await _dio.post(
        ApiEndpoints.chatMessages,
        data: {
          'chatId': chatId,
          'receiverId': receiverId,
          'content': content,
          'type': type,
          if (metadata != null) 'metadata': metadata,
        },
      );
      if (response.statusCode == 201) {
        return response.data['data'];
      }
      throw Exception('Failed to send message');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Upload file for chat
  Future<Map<String, dynamic>> uploadFile(String filePath) async {
    _checkInitialized();
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post(
        ApiEndpoints.chatUploadFile,
        data: formData,
      );

      if (response.statusCode == 200) {
        return response.data['data'];
      }
      throw Exception('Failed to upload file');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, {List<String>? messageIds}) async {
    _checkInitialized();
    try {
      await _dio.put(
        '${ApiEndpoints.chatChats}/$chatId/read',
        data: {'messageIds': messageIds ?? []},
      );
    } catch (e) {
      throw Exception('Failed to mark as read: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    _checkInitialized();
    try {
      await _dio.delete('${ApiEndpoints.chatMessages}/$messageId');
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    _checkInitialized();
    try {
      final response = await _dio.get(ApiEndpoints.chatUnreadCount);
      if (response.statusCode == 200) {
        return response.data['data']['count'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// Search messages
  Future<List<dynamic>> searchMessages(String query, {int limit = 20}) async {
    _checkInitialized();
    try {
      final response = await _dio.get(
        ApiEndpoints.chatSearch,
        queryParameters: {'q': query, 'limit': limit},
      );
      if (response.statusCode == 200) {
        return response.data['data'] as List;
      }
      return [];
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  /// End a chat session
  /// API: PUT /api/v1/chats/:chatId/end
  Future<Map<String, dynamic>> endChat(String chatId) async {
    _checkInitialized();
    try {
      final response = await _dio.put('${ApiEndpoints.chatEnd}/$chatId/end');
      if (response.statusCode == 200) {
        return response.data['data'] ?? response.data['chat'] ?? {};
      }
      throw Exception('Failed to end chat');
    } catch (e) {
      throw Exception('Failed to end chat: $e');
    }
  }

  /// Get all chats for the current user
  /// API: GET /api/v1/chats
  Future<List<Map<String, dynamic>>> getAllChats() async {
    _checkInitialized();
    try {
      final response = await _dio.get(ApiEndpoints.chatEnd);
      if (response.statusCode == 200) {
        final chats = response.data['chats'] ?? response.data['data'];
        if (chats is List) {
          return List<Map<String, dynamic>>.from(chats);
        }
        return [];
      }
      throw Exception('Failed to get chats');
    } catch (e) {
      throw Exception('Failed to get chats: $e');
    }
  }

  /// Get active chat
  Future<Map<String, dynamic>?> getActiveChat() async {
    _checkInitialized();
    try {
      final response = await _dio.get(ApiEndpoints.chatActiveChat);
      if (response.statusCode == 200) {
        return response.data['data'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
