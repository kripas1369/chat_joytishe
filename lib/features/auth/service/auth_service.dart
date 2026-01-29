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
      print(response.body);
      print("###################");
      print("###################");
      return jsonDecode(response.body);
    } else {
      print(response.body);
      print("###################");
      print("###################");
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
      print(response.body);
      print("###################");
      print("###################");
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
      print(response.body);
      print("###################");
      print("###################");
      throw Exception('Failed to verify OTP');
    }
  }

  Future<Map<String, dynamic>> astrologerLoginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse(ApiEndpoints.astrologerLoginWithPassword);

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': identifier, 'password': password}),
    );

    debugPrint('@@@@ Password Login Response @@@@');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      final prefs = await SharedPreferences.getInstance();

      if (response.headers.containsKey('set-cookie')) {
        final cookies = response.headers['set-cookie']!.split(',');

        for (var cookie in cookies) {
          if (cookie.contains('accessToken=')) {
            final token = cookie.split('accessToken=')[1].split(';')[0];
            await prefs.setString('astrologerAccessToken', token);
          }
          if (cookie.contains('refreshToken=')) {
            final token = cookie.split('refreshToken=')[1].split(';')[0];
            await prefs.setString('astrologerRefreshToken', token);
          }
        }
      }
      final data = jsonDecode(response.body);
      final astrologerId = data['data']['astrologer']['id'];
      if (astrologerId != null) {
        await prefs.setString('astrologerId', astrologerId);
      }

      return data;
    } else {
      throw Exception('Failed to login with password');
    }
  }

  Future<void> logoutUser() async {
    try {
      final url = Uri.parse(ApiEndpoints.userLogout);
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');
      final refreshToken = prefs.getString('refreshToken');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
        },
      );

      debugPrint('@@@@ User Logout Response @@@@');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      // Clear user tokens from local storage regardless of API response
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');

      if (response.statusCode != 200) {
        debugPrint('Logout API call failed but tokens cleared locally');
      }
    } catch (e) {
      debugPrint('Logout error: $e');
      // Clear tokens even if API call fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('refreshToken');
      rethrow;
    }
  }

  // Future<void> logoutAstrologer() async {
  //   try {
  //     final url = Uri.parse(ApiEndpoints.astrologerLogout);
  //     final prefs = await SharedPreferences.getInstance();
  //     final accessToken = prefs.getString('astrologerAccessToken');
  //     final refreshToken = prefs.getString('astrologerRefreshToken');
  //
  //     final response = await http.post(
  //       url,
  //       headers: {
  //         'Content-Type': 'application/json',
  //         'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
  //       },
  //     );
  //
  //     debugPrint('@@@@ Astrologer Logout Response @@@@');
  //     debugPrint('Status: ${response.statusCode}');
  //     debugPrint('Body: ${response.body}');
  //
  //     // Clear astrologer tokens from local storage regardless of API response
  //     await prefs.remove('astrologerAccessToken');
  //     await prefs.remove('astrologerRefreshToken');
  //     await prefs.remove('astrologerId');
  //
  //     if (response.statusCode != 200) {
  //       debugPrint('Logout API call failed but tokens cleared locally');
  //     }
  //   } catch (e) {
  //     debugPrint('Astrologer logout error: $e');
  //     // Clear tokens even if API call fails
  //     final prefs = await SharedPreferences.getInstance();
  //     await prefs.remove('astrologerAccessToken');
  //     await prefs.remove('astrologerRefreshToken');
  //     await prefs.remove('astrologerId');
  //     rethrow;
  //   }
  // }

  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<bool> isAstrologerLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('astrologerAccessToken');
    return accessToken != null && accessToken.isNotEmpty;
  }
}