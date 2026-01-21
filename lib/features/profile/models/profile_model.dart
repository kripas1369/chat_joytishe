import 'package:equatable/equatable.dart';

class ProfileModel extends Equatable {
  // Common fields (from API response)
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String? profilePhoto;
  final String role; // CLIENT or ASTROLOGER
  final String? gender;

  // Client-specific fields
  final String? zodiacSign;
  final DateTime? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? currentAddress;
  final String? permanentAddress;
  final bool profileCompleted;
  final bool hasPassword;
  final int coins;

  // Astrologer-specific fields
  final String? category;
  final int? experienceYears;
  final String? expertise;
  final String? languages;
  final String? bio;
  final double? pricePerMinute;
  final bool? isAvailable;
  final bool? isOnline;

  const ProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    this.profilePhoto,
    required this.role,
    this.gender,
    // Client fields
    this.zodiacSign,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.currentAddress,
    this.permanentAddress,
    required this.profileCompleted,
    required this.hasPassword,
    required this.coins,
    // Astrologer fields
    this.category,
    this.experienceYears,
    this.expertise,
    this.languages,
    this.bio,
    this.pricePerMinute,
    this.isAvailable,
    this.isOnline,
  });

  /// Check if user is a client
  bool get isClient => role == 'CLIENT';

  /// Check if user is an astrologer
  bool get isAstrologer => role == 'ASTROLOGER';

  /// Get display price (formatted)
  String? get formattedPrice {
    if (pricePerMinute != null) {
      return '₹${pricePerMinute!.toStringAsFixed(0)}/day';
    }
    return null;
  }

  /// Get experience display text
  String? get experienceText {
    if (experienceYears != null) {
      return '$experienceYears+ years';
    }
    return null;
  }

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'] ?? '',
      profilePhoto: json['profilePhoto'] ?? json['profileImagePath'],
      role: json['role'] ?? 'CLIENT',
      gender: json['gender'],
      // Client fields
      zodiacSign: json['zodiacSign'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      timeOfBirth: json['timeOfBirth'],
      placeOfBirth: json['placeOfBirth'],
      currentAddress: json['currentAddress'] ?? json['address'],
      permanentAddress: json['permanentAddress'],
      profileCompleted: json['profileCompleted'] ?? false,
      hasPassword: json['hasPassword'] ?? false,
      coins: json['coins'] ?? 0,
      // Astrologer fields
      category: json['category'],
      experienceYears: json['experienceYears'],
      expertise: json['expertise'],
      languages: json['languages'],
      bio: json['bio'],
      pricePerMinute: json['pricePerMinute'] != null
          ? (json['pricePerMinute'] as num).toDouble()
          : null,
      isAvailable: json['isAvailable'],
      isOnline: json['isOnline'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      if (profilePhoto != null) 'profilePhoto': profilePhoto,
      'role': role,
      if (gender != null) 'gender': gender,
      // Client fields
      if (zodiacSign != null) 'zodiacSign': zodiacSign,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (timeOfBirth != null) 'timeOfBirth': timeOfBirth,
      if (placeOfBirth != null) 'placeOfBirth': placeOfBirth,
      if (currentAddress != null) 'currentAddress': currentAddress,
      if (permanentAddress != null) 'permanentAddress': permanentAddress,
      'profileCompleted': profileCompleted,
      'hasPassword': hasPassword,
      'coins': coins,
      // Astrologer fields
      if (category != null) 'category': category,
      if (experienceYears != null) 'experienceYears': experienceYears,
      if (expertise != null) 'expertise': expertise,
      if (languages != null) 'languages': languages,
      if (bio != null) 'bio': bio,
      if (pricePerMinute != null) 'pricePerMinute': pricePerMinute,
      if (isAvailable != null) 'isAvailable': isAvailable,
      if (isOnline != null) 'isOnline': isOnline,
    };
  }

  ProfileModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? profilePhoto,
    String? role,
    String? gender,
    String? zodiacSign,
    DateTime? dateOfBirth,
    String? timeOfBirth,
    String? placeOfBirth,
    String? currentAddress,
    String? permanentAddress,
    bool? profileCompleted,
    bool? hasPassword,
    int? coins,
    String? category,
    int? experienceYears,
    String? expertise,
    String? languages,
    String? bio,
    double? pricePerMinute,
    bool? isAvailable,
    bool? isOnline,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      timeOfBirth: timeOfBirth ?? this.timeOfBirth,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      profileCompleted: profileCompleted ?? this.profileCompleted,
      hasPassword: hasPassword ?? this.hasPassword,
      coins: coins ?? this.coins,
      category: category ?? this.category,
      experienceYears: experienceYears ?? this.experienceYears,
      expertise: expertise ?? this.expertise,
      languages: languages ?? this.languages,
      bio: bio ?? this.bio,
      pricePerMinute: pricePerMinute ?? this.pricePerMinute,
      isAvailable: isAvailable ?? this.isAvailable,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phoneNumber,
    profilePhoto,
    role,
    gender,
    zodiacSign,
    dateOfBirth,
    timeOfBirth,
    placeOfBirth,
    currentAddress,
    permanentAddress,
    profileCompleted,
    hasPassword,
    coins,
    category,
    experienceYears,
    expertise,
    languages,
    bio,
    pricePerMinute,
    isAvailable,
    isOnline,
  ];

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, role: $role, isOnline: $isOnline)';
  }
}
