import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';
import '../models/chat_model.dart';

/// Appointment Service - REST API
/// Handles appointment booking and management
class AppointmentService {
  static final AppointmentService _instance = AppointmentService._internal();

  factory AppointmentService() => _instance;

  AppointmentService._internal();

  /// Book a new appointment with an astrologer
  Future<AppointmentModel> bookAppointment({
    required String astrologerId,
    required String date,
    required String timeSlot,
    required String description,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final response = await http.post(
      Uri.parse(ApiEndpoints.appointments),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
      body: jsonEncode({
        'astrologerId': astrologerId,
        'date': date,
        'timeSlot': timeSlot,
        'description': description,
      }),
    );

    debugPrint('Book Appointment Response: ${response.statusCode}');
    debugPrint('Body: ${response.body}');

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppointmentModel.fromJson(data['appointment']);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Invalid appointment data');
    } else if (response.statusCode == 409) {
      throw Exception('Time slot is already booked. Please choose another slot.');
    } else {
      throw Exception('Failed to book appointment: ${response.statusCode}');
    }
  }

  /// Get appointment by ID
  Future<AppointmentModel> getAppointment(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final response = await http.get(
      Uri.parse('${ApiEndpoints.appointmentById}/$appointmentId'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('Get Appointment Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppointmentModel.fromJson(data['appointment']);
    } else if (response.statusCode == 404) {
      throw Exception('Appointment not found');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception('Failed to get appointment: ${response.statusCode}');
    }
  }

  /// Get all appointments for the current user
  Future<List<AppointmentModel>> getMyAppointments({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (status != null) 'status': status,
    };

    final uri = Uri.parse(ApiEndpoints.appointments)
        .replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('Get My Appointments Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final appointmentsList = data['appointments'] as List;
      return appointmentsList
          .map((json) => AppointmentModel.fromJson(json))
          .toList();
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception('Failed to get appointments: ${response.statusCode}');
    }
  }

  /// Cancel an appointment
  Future<AppointmentModel> cancelAppointment(String appointmentId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final response = await http.put(
      Uri.parse('${ApiEndpoints.appointmentById}/$appointmentId/cancel'),
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('Cancel Appointment Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppointmentModel.fromJson(data['appointment']);
    } else if (response.statusCode == 404) {
      throw Exception('Appointment not found');
    } else if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Cannot cancel this appointment');
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception('Failed to cancel appointment: ${response.statusCode}');
    }
  }

  /// Get available time slots for an astrologer on a specific date
  Future<List<String>> getAvailableSlots({
    required String astrologerId,
    required String date,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    final refreshToken = prefs.getString('refreshToken');

    if (accessToken == null) {
      throw Exception('Not authenticated. Please login first.');
    }

    final uri = Uri.parse('${ApiEndpoints.appointments}/available-slots')
        .replace(queryParameters: {
      'astrologerId': astrologerId,
      'date': date,
    });

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken; refreshToken=$refreshToken',
      },
    );

    debugPrint('Get Available Slots Response: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<String>.from(data['slots'] ?? []);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized. Please login again.');
    } else {
      throw Exception('Failed to get available slots: ${response.statusCode}');
    }
  }
}
