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


