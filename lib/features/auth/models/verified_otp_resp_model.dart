class VerifiedOtpResponseModel {
  final bool success;
  final VerifiedOtpData data;

  VerifiedOtpResponseModel({required this.success, required this.data});

  factory VerifiedOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return VerifiedOtpResponseModel(
      success: json['success'] ?? false,
      data: VerifiedOtpData.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {'success': success, 'data': data.toJson()};
}

class VerifiedOtpData {
  final String token;
  final User user;
  final bool isNewUser;
  final String message;

  VerifiedOtpData({
    required this.token,
    required this.user,
    required this.isNewUser,
    required this.message,
  });

  factory VerifiedOtpData.fromJson(Map<String, dynamic> json) {
    return VerifiedOtpData(
      token: json['token'] ?? '',
      user: User.fromJson(json['user']),
      isNewUser: json['isNewUser'] ?? false,
      message: json['message'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'user': user.toJson(),
    'isNewUser': isNewUser,
    'message': message,
  };
}

class User {
  final String? phone;
  final String? email;
  final String name;
  final String? profilePhoto;
  final bool profileCompleted;
  final String role;
  final String? dateOfBirth;
  final String? timeOfBirth;
  final String? placeOfBirth;
  final String? currentAddress;
  final String? permanentAddress;
  final String? zodiacSign;
  final String createdAt;
  final String updatedAt;
  final String phoneNumber;
  final bool hasPassword;

  User({
    this.phone,
    this.email,
    required this.name,
    this.profilePhoto,
    required this.profileCompleted,
    required this.role,
    this.dateOfBirth,
    this.timeOfBirth,
    this.placeOfBirth,
    this.currentAddress,
    this.permanentAddress,
    this.zodiacSign,
    required this.createdAt,
    required this.updatedAt,
    required this.phoneNumber,
    required this.hasPassword,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      phone: json['phone'] ?? '',
      email: json['email']?.isEmpty ?? true ? null : json['email'],
      name: json['name'] ?? '',
      profilePhoto: json['profilePhoto'],
      profileCompleted: json['profileCompleted'] ?? false,
      role: json['role'] ?? '',
      dateOfBirth: json['dateOfBirth'],
      timeOfBirth: json['timeOfBirth'],
      placeOfBirth: json['placeOfBirth'],
      currentAddress: json['currentAddress'],
      permanentAddress: json['permanentAddress'],
      zodiacSign: json['zodiacSign'],
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      hasPassword: json['hasPassword'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'phone': phone,
    'email': email,
    'name': name,
    'profilePhoto': profilePhoto,
    'profileCompleted': profileCompleted,
    'role': role,
    'dateOfBirth': dateOfBirth,
    'timeOfBirth': timeOfBirth,
    'placeOfBirth': placeOfBirth,
    'currentAddress': currentAddress,
    'permanentAddress': permanentAddress,
    'zodiacSign': zodiacSign,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'phoneNumber': phoneNumber,
    'hasPassword': hasPassword,
  };
}
