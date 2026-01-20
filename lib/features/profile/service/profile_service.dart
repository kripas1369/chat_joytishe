import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_jyotishi/constants/api_endpoints.dart';

class ProfileService {
  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.getCurrentUserProfile);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
    );

    debugPrint(
      'Get Current User Profile Response Status: ${response.statusCode}',
    );
    debugPrint('Get Current User Profile Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get current user profile');
    }
  }

  /// Complete profile setup
  Future<Map<String, dynamic>> completeUserProfileSetup({
    required String name,
    required String email,
    required String dateOfBirth,
    required String timeOfBirth,
    required String placeOfBirth,
    required String currentAddress,
    required String permanentAddress,
    required String zoadicSign,
    required String gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.completeUserProfileSetup);

    final body = {
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'timeOfBirth': timeOfBirth,
      'placeOfBirth': placeOfBirth,
      'currentAddress': currentAddress,
      'permanentAddress': permanentAddress,
      'zoadicSign': zoadicSign,
      'gender': gender,
    };
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    print(zoadicSign);
    print(zoadicSign);
    print(zoadicSign);
    print(zoadicSign);
    print(zoadicSign);
    print(zoadicSign);
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('^^^^^^^^^^^^^^^^^^^');
    debugPrint('Complete Profile Setup Request URL: $url');
    debugPrint(
      'Complete Profile Setup Request Headers: '
      '{Content-Type: application/json, Cookie: accessToken=$accessToken}',
    );
    debugPrint('Complete Profile Setup Request Body: ${jsonEncode(body)}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
      body: jsonEncode(body),
    );

    debugPrint(
      'Complete Profile Setup Response Status: ${response.statusCode}',
    );
    debugPrint('Complete Profile Setup Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to complete profile setup');
    }
  }

  /// Update user profile (name, email)
  Future<Map<String, dynamic>> updateUserProfile({
    String? name,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.updateUserProfile);

    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;

    final response = await http.patch(
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

  /// Update birth details
  Future<Map<String, dynamic>> updateBirthDetails({
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    String? currentAddress,
    String? permanentAddress,
    String? zoadicSign,
    String? gender,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.updateUserBirthDetails);

    final body = <String, dynamic>{};
    if (dateOfBirth != null) body['dateOfBirth'] = dateOfBirth;
    if (timeOfBirth != null) body['timeOfBirth'] = timeOfBirth;
    if (placeOfBirth != null) body['placeOfBirth'] = placeOfBirth;
    if (currentAddress != null) body['currentAddress'] = currentAddress;
    if (permanentAddress != null) body['permanentAddress'] = permanentAddress;
    if (zoadicSign != null) body['zodiacSign'] = zoadicSign;
    if (gender != null) body['gender'] = gender;

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
      body: jsonEncode(body),
    );

    debugPrint('Update Birth Details Response Status: ${response.statusCode}');
    debugPrint('Update Birth Details Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update birth details');
    }
  }

  /// Upload profile photo
  Future<Map<String, dynamic>> uploadProfilePhoto(File photo) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.uploadProfilePhoto);

    final request = http.MultipartRequest('POST', url);

    request.headers.addAll({'Cookie': 'accessToken=$accessToken'});

    // 🔍 DEBUG: print file details
    debugPrint('Uploading file path: ${photo.path}');
    debugPrint('Uploading file name: ${path.basename(photo.path)}');
    debugPrint('Uploading file size: ${await photo.length()} bytes');

    final multipartFile = await http.MultipartFile.fromPath(
      'photo',
      photo.path,
      filename: path.basename(photo.path),
      contentType: MediaType('image', 'JPEG'),
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    debugPrint('Upload Profile Photo Response Status: ${response.statusCode}');
    debugPrint('Upload Profile Photo Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upload profile photo');
    }
  }

  /// Remove profile photo
  Future<Map<String, dynamic>> removeProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final url = Uri.parse(ApiEndpoints.removeProfilePhoto);

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Cookie': 'accessToken=$accessToken',
      },
    );

    debugPrint('Remove Profile Photo Response Status: ${response.statusCode}');
    debugPrint('Remove Profile Photo Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to remove profile photo');
    }
  }

  // /// Get chatable users (astrologers for clients)
  // Future<Map<String, dynamic>> getChatableUsers() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final accessToken = prefs.getString('accessToken');
  //
  //   final url = Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.getActiveAstrologers}');
  //
  //   final response = await http.get(
  //     url,
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Cookie': 'accessToken=$accessToken',
  //     },
  //   );
  //
  //   debugPrint('Get Chatable Users Response Status: ${response.statusCode}');
  //   debugPrint('Get Chatable Users Response Body: ${response.body}');
  //
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body);
  //   } else {
  //     throw Exception('Failed to get chatable users');
  //   }
  // }
}
