import 'package:chat_jyotishi/features/chat/models/active_user_model.dart';
import 'package:chat_jyotishi/features/chat/service/chat_service.dart';
import 'package:chat_jyotishi/features/chat/service/chat_end_service.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  final ChatService _chatService;
  final ChatEndService _chatEndService;

  ChatRepository({ChatService? chatService, ChatEndService? chatEndService})
    : _chatService = chatService ?? ChatService(),
      _chatEndService = chatEndService ?? ChatEndService();

  Future<List<ActiveAstrologerModel>> getActiveAstrologers() async {
    final response = await _chatService.fetchActiveAstrologers();

    if (response['success'] == true && response['data'] is List) {
      return (response['data'] as List)
          .map((e) => ActiveAstrologerModel.fromJson(e))
          .toList();
    }

    return [];
  }

  Future<Map<String, dynamic>> endChat({required String chatId}) async {
    try {
      final response = await _chatEndService.endChat(chatId: chatId);

      if (response['success'] == true && response['data'] != null) {
        final chatData = response['data']['chat'] as Map<String, dynamic>;

        return {
          'chatId': chatData['id'] as String,
          'status': chatData['status'] as String,
          'endedBy': chatData['endedBy'] as String,
          'endedAt': DateTime.parse(chatData['endedAt'] as String),
          'isLocked': chatData['isLocked'] as bool? ?? true,
        };
      } else {
        throw Exception('Invalid response format');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final message =
            e.response!.data?['message'] ??
            e.response!.data?['error'] ??
            'Failed to end chat';

        switch (statusCode) {
          case 400:
            throw Exception('Invalid request: $message');
          case 401:
            throw Exception('Unauthorized. Please login again.$message');
          case 403:
            throw Exception('You do not have permission to end this chat.');
          case 404:
            throw Exception('Chat not found.');
          case 500:
            throw Exception('Server error. Please try again later.');
          default:
            throw Exception(message);
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          'Connection timeout. Please check your internet connection.',
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('No internet connection. Please check your network.');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to end chat: ${e.toString()}');
    }
  }
}
