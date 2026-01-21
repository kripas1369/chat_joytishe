import 'dart:io';

import 'package:chat_jyotishi/features/profile/service/profile_service.dart';

import '../models/profile_model.dart';

class ProfileRepository {
  final ProfileService profileService;

  ProfileRepository(this.profileService);

  /// Get current user profile
  Future<ProfileModel> getCurrentUserProfile() async {
    try {
      final data = await profileService.getCurrentUserProfile();
      return ProfileModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Complete profile setup
  Future<ProfileModel> completeProfileSetup({
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
    try {
      final data = await profileService.completeUserProfileSetup(
        name: name,
        email: email,
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        placeOfBirth: placeOfBirth,
        currentAddress: currentAddress,
        permanentAddress: permanentAddress,
        zoadicSign: zoadicSign,
        gender: gender,
      );
      return ProfileModel.fromJson(data['data']['user']);
    } catch (e) {
      throw Exception('Failed to complete profile setup: $e');
    }
  }

  /// Update user profile (name, email)
  Future<ProfileModel> updateUserProfile({String? name, String? email}) async {
    try {
      final data = await profileService.updateUserProfile(
        name: name,
        email: email,
      );
      return ProfileModel.fromJson(data['data']);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
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
    try {
      final data = await profileService.updateBirthDetails(
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        placeOfBirth: placeOfBirth,
        currentAddress: currentAddress,
        permanentAddress: permanentAddress,
        zoadicSign: zoadicSign,
        gender: gender,
      );
      return data['data'];
    } catch (e) {
      throw Exception('Failed to update birth details: $e');
    }
  }

  /// Upload profile photo
  Future<String> uploadProfilePhoto(File photo) async {
    try {
      final data = await profileService.uploadProfilePhoto(photo);
      return data['data']['profilePhoto'];
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Remove profile photo
  Future<void> removeProfilePhoto() async {
    try {
      await profileService.removeProfilePhoto();
    } catch (e) {
      throw Exception('Failed to remove profile photo: $e');
    }
  }

  // /// Get chatable users
  // Future<List<UserModel>> getChatableUsers() async {
  //   try {
  //     final data = await _profileService.getChatableUsers();
  //     final List<dynamic> usersData = data['data'];
  //     return usersData.map((json) => UserModel.fromJson(json)).toList();
  //   } catch (e) {
  //     throw Exception('Failed to get chatable users: $e');
  //   }
  // }
}
