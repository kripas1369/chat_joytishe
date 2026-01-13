import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/api_endpoints.dart';

class ProfileService {
  Future<Map<String, dynamic>> getUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.getUserProfile);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
    );

    debugPrint('Get User Profile Response Status: ${response.statusCode}');
    debugPrint('Get User Profile Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get user profile');
    }
  }

  // Update User Profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String? name,
    required String? email,
    required String? phone,
    required String? address,
    required String? dateOfBirth,
    required String? timeOfBirth,
    required String? placeOfBirth,
    required String? zodiacSign,
    required String? gender,
    required File? profileImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.getUserProfile);

    // If there's an image, use multipart request
    if (profileImage != null) {
      var request = http.MultipartRequest('PUT', url);

      request.headers.addAll({'Cookie': 'accessToken=$accessToken'});

      // Add fields
      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['address'] = address;
      if (dateOfBirth != null) request.fields['dateOfBirth'] = dateOfBirth;
      if (timeOfBirth != null) request.fields['timeOfBirth'] = timeOfBirth;
      if (placeOfBirth != null) request.fields['placeOfBirth'] = placeOfBirth;
      if (zodiacSign != null) request.fields['zodiacSign'] = zodiacSign;
      if (gender != null) request.fields['gender'] = gender;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Update User Profile Response Status: ${response.statusCode}');
      debugPrint('Update User Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user profile');
      }
    } else {
      // JSON request without image
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
      if (timeOfBirth != null) body['timeOfBirth'] = timeOfBirth;
      if (placeOfBirth != null) body['placeOfBirth'] = placeOfBirth;
      if (zodiacSign != null) body['zodiacSign'] = zodiacSign;
      if (gender != null) body['gender'] = gender;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken',
        },
        body: jsonEncode(body),
      );

      debugPrint('Update User Profile Response Status: ${response.statusCode}');
      debugPrint('Update User Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update user profile');
      }
    }
  }

  // Get Astrologer Profile
  Future<Map<String, dynamic>> getAstrologerProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('astrologerAccessToken');

    final url = Uri.parse(ApiEndpoints.getAstrologerProfile);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
    );

    debugPrint(
      'Get Astrologer Profile Response Status: ${response.statusCode}',
    );
    debugPrint('Get Astrologer Profile Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get astrologer profile');
    }
  }

  // Update Astrologer Profile
  Future<Map<String, dynamic>> updateAstrologerProfile({
    required String? name,
    required String? email,
    required String? phone,
    required String? address,
    required int? experienceYears,
    required String? expertise,
    required String? languages,
    required String? bio,
    required double? pricePerMinute,
    required String? gender,
    required bool? isAvailable,
    required File? profileImage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('astrologerAccessToken');

    final url = Uri.parse(ApiEndpoints.getAstrologerProfile);

    // If there's an image, use multipart request
    if (profileImage != null) {
      var request = http.MultipartRequest('PUT', url);

      request.headers.addAll({'Cookie': 'accessToken=$accessToken'});

      // Add fields
      if (name != null) request.fields['name'] = name;
      if (email != null) request.fields['email'] = email;
      if (phone != null) request.fields['phone'] = phone;
      if (address != null) request.fields['address'] = address;
      if (experienceYears != null) {
        request.fields['experienceYears'] = experienceYears.toString();
      }
      if (expertise != null) request.fields['expertise'] = expertise;
      if (languages != null) request.fields['languages'] = languages;
      if (bio != null) request.fields['bio'] = bio;
      if (pricePerMinute != null) {
        request.fields['pricePerMinute'] = pricePerMinute.toString();
      }
      if (gender != null) request.fields['gender'] = gender;
      if (isAvailable != null) {
        request.fields['isAvailable'] = isAvailable.toString();
      }

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath('profileImage', profileImage.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint(
        'Update Astrologer Profile Response Status: ${response.statusCode}',
      );
      debugPrint('Update Astrologer Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update astrologer profile');
      }
    } else {
      // JSON request without image
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;
      if (phone != null) body['phone'] = phone;
      if (address != null) body['address'] = address;
      if (experienceYears != null) body['experienceYears'] = experienceYears;
      if (expertise != null) body['expertise'] = expertise;
      if (languages != null) body['languages'] = languages;
      if (bio != null) body['bio'] = bio;
      if (pricePerMinute != null) body['pricePerMinute'] = pricePerMinute;
      if (gender != null) body['gender'] = gender;
      if (isAvailable != null) body['isAvailable'] = isAvailable;

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'accessToken=$accessToken',
        },
        body: jsonEncode(body),
      );

      debugPrint(
        'Update Astrologer Profile Response Status: ${response.statusCode}',
      );
      debugPrint('Update Astrologer Profile Response Body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update astrologer profile');
      }
    }
  }
}
