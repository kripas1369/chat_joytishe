import 'dart:convert';
import 'package:chat_jyotishi/constants/api_endpoints.dart';
import 'package:chat_jyotishi/features/home/models/rotating_question.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeClientService {
  Future<RotatingQuestionsResponse> fetchRotatingQuestions() async {
    try {
      debugPrint('🔄 Service: Fetching rotating questions...');

      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}/public/dashboard-rotating-copy'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Service: Questions loaded successfully');
        return RotatingQuestionsResponse.fromJson(data);
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Service Error: $e');
      throw Exception('Error fetching questions: $e');
    }
  }

  Future<Map<String, dynamic>> bookPandit({
    required String bookingDate,
    required String category,
    required String type,
    required String location,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    final response = await http.post(
      Uri.parse(ApiEndpoints.bookPandit),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
      body: jsonEncode({
        "type": type,
        "category": category,
        "bookingDate": bookingDate,
        "location": location,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('$response');
    }
  }
}
