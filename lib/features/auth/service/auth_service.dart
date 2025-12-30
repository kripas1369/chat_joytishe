import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';

class AuthService {
  Future<Map<String, dynamic>> sendOtp({required String phoneNumber}) async {
    final url = Uri.parse(ApiEndpoints.sendOtp);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );

    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send OTP');
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String sessionId,
    required String otp,
  }) async {
    final url = Uri.parse(ApiEndpoints.verifyOtp);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'sessionId': sessionId,
        'otp': otp,
      }),
    );

    debugPrint('@@@@ Verify OTP Response @@@@');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');
    debugPrint('Headers: ${response.headers}');

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();

      if (response.headers.containsKey('set-cookie')) {
        final cookies = response.headers['set-cookie']!.split(',');

        for (var cookie in cookies) {
          if (cookie.contains('accessToken=')) {
            final token = cookie.split('accessToken=')[1].split(';')[0];
            await prefs.setString('accessToken', token);
          }
          if (cookie.contains('refreshToken=')) {
            final token = cookie.split('refreshToken=')[1].split(';')[0];
            await prefs.setString('refreshToken', token);
          }
        }
      }
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to verify OTP');
    }
  }
}
