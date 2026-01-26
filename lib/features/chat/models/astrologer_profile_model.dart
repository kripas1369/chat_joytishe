/// Model for detailed astrologer profile
class AstrologerProfile {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String? profilePhoto;
  final String role;
  final bool isOnline;
  final String? bio;
  final String? specialization;
  final List<String> expertise;
  final int experience; // years of experience
  final String? languages;
  final double rating;
  final int totalConsultations;
  final int totalReviews;
  final String astrologerType; // ORDINARY, PROFESSIONAL, PREMIUM, KATHA_VACHAK
  final int chatCostPerMessage;
  final bool isAvailable;
  final DateTime? createdAt;

  AstrologerProfile({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profilePhoto,
    required this.role,
    this.isOnline = false,
    this.bio,
    this.specialization,
    this.expertise = const [],
    this.experience = 0,
    this.languages,
    this.rating = 0.0,
    this.totalConsultations = 0,
    this.totalReviews = 0,
    this.astrologerType = 'ORDINARY',
    this.chatCostPerMessage = 2,
    this.isAvailable = true,
    this.createdAt,
  });

  factory AstrologerProfile.fromJson(Map<String, dynamic> json) {
    // Handle nested data structure
    final data = json['data'] ?? json;

    // Parse expertise - can be string or list
    List<String> parseExpertise(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return AstrologerProfile(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString(),
      phone: data['phone']?.toString(),
      profilePhoto: data['profilePhoto']?.toString(),
      role: data['role']?.toString() ?? 'ASTROLOGER',
      isOnline: data['isOnline'] == true,
      bio: data['bio']?.toString() ?? data['description']?.toString(),
      specialization: data['specialization']?.toString() ?? data['specialty']?.toString(),
      expertise: parseExpertise(data['expertise'] ?? data['skills']),
      experience: _parseInt(data['experience'] ?? data['yearsOfExperience']),
      languages: data['languages']?.toString(),
      rating: _parseDouble(data['rating'] ?? data['averageRating']),
      totalConsultations: _parseInt(data['totalConsultations'] ?? data['consultationCount']),
      totalReviews: _parseInt(data['totalReviews'] ?? data['reviewCount']),
      astrologerType: data['astrologerType']?.toString() ?? data['type']?.toString() ?? 'ORDINARY',
      chatCostPerMessage: _parseInt(data['chatCostPerMessage'] ?? data['chatCost']) > 0
          ? _parseInt(data['chatCostPerMessage'] ?? data['chatCost'])
          : 2,
      isAvailable: data['isAvailable'] != false,
      createdAt: data['createdAt'] != null
          ? DateTime.tryParse(data['createdAt'].toString())
          : null,
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Get display text for astrologer type
  String get typeDisplayName {
    switch (astrologerType.toUpperCase()) {
      case 'ORDINARY':
        return 'Astrologer';
      case 'PROFESSIONAL':
        return 'Professional Astrologer';
      case 'PREMIUM':
        return 'Premium Astrologer';
      case 'KATHA_VACHAK':
        return 'Katha Vachak';
      default:
        return 'Astrologer';
    }
  }

  /// Get chat cost description
  String get chatCostDescription {
    if (astrologerType.toUpperCase() == 'PREMIUM' ||
        astrologerType.toUpperCase() == 'KATHA_VACHAK') {
      return 'Appointment only';
    }
    return '$chatCostPerMessage coins/message';
  }

  /// Create from basic user data (when full profile not available)
  factory AstrologerProfile.fromBasicData({
    required String id,
    required String name,
    String? profilePhoto,
    bool isOnline = false,
  }) {
    return AstrologerProfile(
      id: id,
      name: name,
      profilePhoto: profilePhoto,
      role: 'ASTROLOGER',
      isOnline: isOnline,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'role': role,
      'isOnline': isOnline,
      'bio': bio,
      'specialization': specialization,
      'expertise': expertise,
      'experience': experience,
      'languages': languages,
      'rating': rating,
      'totalConsultations': totalConsultations,
      'totalReviews': totalReviews,
      'astrologerType': astrologerType,
      'chatCostPerMessage': chatCostPerMessage,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
