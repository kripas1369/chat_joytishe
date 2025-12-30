class VerifiedOtpResponseModel {
  final bool success;

  final bool isNewUser;
  final String message;

  VerifiedOtpResponseModel({
    required this.success,

    required this.isNewUser,
    required this.message,
  });

  factory VerifiedOtpResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return VerifiedOtpResponseModel(
      success: json['success'] ?? false,

      isNewUser: data['isNewUser'] ?? false,
      message: data['message'] ?? '',
    );
  }
}

// Usage Example:
//
// final response = VerifiedOtpResponseModel.fromJson(jsonResponse);
//
// if (response.success) {
//   // Store tokens
//   await SecureStorage.saveAccessToken(response.accessToken);
//   await SecureStorage.saveRefreshToken(response.refreshToken);
//
//   // Navigate based on user status
//   if (response.isNewUser) {
//     Navigator.pushReplacementNamed(context, '/profile-setup');
//   } else {
//     Navigator.pushReplacementNamed(context, '/home');
//   }
// }
