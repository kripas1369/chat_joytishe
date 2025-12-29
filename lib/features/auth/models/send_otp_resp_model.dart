class SendOtpResponseModel {
  final bool success;
  final String sessionId;
  final bool isExistingUser;
  final String message;
  final String otp;

  SendOtpResponseModel({
    required this.success,
    required this.sessionId,
    required this.isExistingUser,
    required this.message,
    required this.otp,
  });

  factory SendOtpResponseModel.fromJson(Map<String, dynamic> json) {
    return SendOtpResponseModel(
      success: json['success'] ?? false,
      sessionId: json['data']['sessionId'] ?? '',
      isExistingUser: json['data']['isExistingUser'] ?? false,
      message: json['data']['message'] ?? '',
      otp: json['data']['otp'] ?? '',
    );
  }
}
