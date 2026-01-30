

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';

class BookingsAppointmentsService {
  /// Fetches user's bookings (Pandit, Katha Vachak, Vaastu)
  /// GET /jyotish-bookings/my?page=1&limit=10
  Future<Map<String, dynamic>> getMyBookings({
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/jyotish-bookings/my?page=$page&limit=$limit',
    );

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('@@@@ Get My Bookings Response @@@@');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to fetch bookings');
    }
  }

  /// Fetches user's appointments with astrologers
  /// GET /appointments/my?page=1&limit=10
  Future<Map<String, dynamic>> getMyAppointments({
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse(
      '${ApiEndpoints.baseUrl}/appointments/my?page=$page&limit=$limit',
    );

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('@@@@ Get My Appointments Response @@@@');
    debugPrint('Status: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to fetch appointments');
    }
  }
}
