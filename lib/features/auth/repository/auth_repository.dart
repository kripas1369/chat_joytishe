import 'package:chat_jyotishi/features/auth/models/login_password_resp_model.dart';
import 'package:chat_jyotishi/features/auth/models/verified_otp_resp_model.dart';

import '../models/send_otp_resp_model.dart';
import '../service/auth_service.dart';

class AuthRepository {
  final AuthService authService;

  AuthRepository(this.authService);

  Future<SendOtpResponseModel> sendOtp({required String phoneNumber}) async {
    final data = await authService.sendOtp(phoneNumber: phoneNumber);

    return SendOtpResponseModel.fromJson(data);
  }

  Future<VerifiedOtpResponseModel> verifyOtp({
    required String phoneNumber,
    required String sessionId,
    required String otp,
  }) async {
    final data = await authService.verifyOtp(
      phoneNumber: phoneNumber,
      sessionId: sessionId,
      otp: otp,
    );
    return VerifiedOtpResponseModel.fromJson(data);
  }

  Future<LoginPasswordResponseModel> astrologerLoginWithPassword({
    required String identifier,
    required String password,
  }) async {
    final data = await authService.astrologerLoginWithPassword(
      identifier: identifier,
      password: password,
    );

    return LoginPasswordResponseModel.fromJson(data);
  }

  Future<void> logoutUser() async {
    await authService.logoutUser();
  }

  // Future<void> logoutAstrologer() async {
  //   await authService.logoutAstrologer();
  // }

  Future<bool> isUserLoggedIn() async {
    return await authService.isUserLoggedIn();
  }

  Future<bool> isAstrologerLoggedIn() async {
    return await authService.isAstrologerLoggedIn();
  }
}