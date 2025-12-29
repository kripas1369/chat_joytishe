class ApiEndpoints {
  static const String baseUrl = 'http://192.168.0.206:4000/api/v1';
  static const String sendOtp = '$baseUrl/auth/send-otp';
  static const String verifyOtp = '$baseUrl/auth/verify-otp';
  static const String setPassword = '$baseUrl/auth/set-password';
  static const String loginWithPassword = '$baseUrl/auth/login';
  static const String loginWithOtp = '$baseUrl/auth/login-with-otp';
  static const String verifyLoginOtp = '$baseUrl/auth/verify-login-otp';
  static const String changePassword = '$baseUrl/auth/change-password';
}
