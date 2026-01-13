// lib/features/profile/repository/profile_repository.dart

import 'dart:io';
import 'package:chat_jyotishi/features/profile/service/profile_service.dart';

import '../models/user_profile_model.dart';
import '../models/astrologer_profile_model.dart';

class ProfileRepository {
  final ProfileService profileService;

  ProfileRepository(this.profileService);

  /// Get User Profile
  Future<UserProfileModel> getUserProfile() async {
    try {
      final data = await profileService.getUserProfile();
      return UserProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update User Profile
  Future<UserProfileModel> updateUserProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    String? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    String? zodiacSign,
    String? gender,
    File? profileImage,
  }) async {
    try {
      final data = await profileService.updateUserProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
        dateOfBirth: dateOfBirth,
        timeOfBirth: timeOfBirth,
        placeOfBirth: placeOfBirth,
        zodiacSign: zodiacSign,
        gender: gender,
        profileImage: profileImage,
      );
      return UserProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get Astrologer Profile
  Future<AstrologerProfileModel> getAstrologerProfile() async {
    try {
      final data = await profileService.getAstrologerProfile();
      return AstrologerProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to get astrologer profile: $e');
    }
  }

  /// Update Astrologer Profile
  Future<AstrologerProfileModel> updateAstrologerProfile({
    String? name,
    String? email,
    String? phone,
    String? address,
    int? experienceYears,
    String? expertise,
    String? languages,
    String? bio,
    double? pricePerMinute,
    String? gender,
    bool? isAvailable,
    File? profileImage,
  }) async {
    try {
      final data = await profileService.updateAstrologerProfile(
        name: name,
        email: email,
        phone: phone,
        address: address,
        experienceYears: experienceYears,
        expertise: expertise,
        languages: languages,
        bio: bio,
        pricePerMinute: pricePerMinute,
        gender: gender,
        isAvailable: isAvailable,
        profileImage: profileImage,
      );
      return AstrologerProfileModel.fromJson(data);
    } catch (e) {
      throw Exception('Failed to update astrologer profile: $e');
    }
  }
}
