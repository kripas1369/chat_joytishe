import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_jyotishi/constants/api_endpoints.dart';

class ChatEndService {
  final Dio _dio = Dio();

  /// End a chat session
  Future<Map<String, dynamic>> endChat({required String chatId}) async {
    try {
      // Fetch tokens from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      if (accessToken == null || refreshToken == null) {
        throw Exception('Access token is missing. User may not be logged in.');
      }

      final url = '${ApiEndpoints.baseUrl}/chat/chats/$chatId/end';

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      };

      print('Chat ID: $chatId');

      print('Sending tokens via cookies: $accessToken && $refreshToken');

      final response = await _dio.put(url, options: Options(headers: headers));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to end chat: ${response.statusCode} - ${response.data}',
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
          'Failed to end chat: ${e.response?.statusCode} - ${e.response?.data}',
        );
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}
