class LoginPasswordResponseModel {
  final bool success;
  final AstrologerData? data;

  LoginPasswordResponseModel({required this.success, this.data});

  factory LoginPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginPasswordResponseModel(
      success: json['success'] ?? false,
      data: json['data'] != null ? AstrologerData.fromJson(json['data']) : null,
    );
  }
}

class AstrologerData {
  final Astrologer astrologer;

  AstrologerData({required this.astrologer});

  factory AstrologerData.fromJson(Map<String, dynamic> json) {
    return AstrologerData(astrologer: Astrologer.fromJson(json['astrologer']));
  }
}

class Astrologer {
  final String id;
  final String phone;
  final String email;
  final String name;
  final String? profilePhoto;
  final String bio;
  final List<String> specialization;
  final int experience;
  final int rating;
  final String category;
  final bool isActive;
  final bool isOnline;
  final bool isVerified;

  Astrologer({
    required this.id,
    required this.phone,
    required this.email,
    required this.name,
    this.profilePhoto,
    required this.bio,
    required this.specialization,
    required this.experience,
    required this.rating,
    required this.category,
    required this.isActive,
    required this.isOnline,
    required this.isVerified,
  });

  factory Astrologer.fromJson(Map<String, dynamic> json) {
    return Astrologer(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      profilePhoto: json['profilePhoto'],
      bio: json['bio'] ?? '',
      specialization: List<String>.from(json['specialization'] ?? []),
      experience: json['experience'] ?? 0,
      rating: json['rating'] ?? 0,
      category: json['category'] ?? '',
      isActive: json['isActive'] ?? false,
      isOnline: json['isOnline'] ?? false,
      isVerified: json['isVerified'] ?? false,
    );
  }
}
