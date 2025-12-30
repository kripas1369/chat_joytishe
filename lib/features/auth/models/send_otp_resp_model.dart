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
    final data = json['data'] ?? {};
    return SendOtpResponseModel(
      success: json['success'] ?? false,
      sessionId: data['sessionId'] ?? '',
      isExistingUser: data['isExistingUser'] ?? false,
      message: data['message'] ?? '',
      otp: data['otp'] ?? '',
    );
  }
}
