import 'package:chat_jyotishi/features/auth/models/login_password_resp_model.dart';
import 'package:equatable/equatable.dart';
import '../models/send_otp_resp_model.dart';
import '../models/verified_otp_resp_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthOtpLoadedState extends AuthState {
  final String phoneNumber;
  final SendOtpResponseModel otpResponse;

  const AuthOtpLoadedState({
    required this.otpResponse,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props => [phoneNumber, otpResponse];
}

class AuthOtpVerifiedState extends AuthState {
  final VerifiedOtpResponseModel verifiedOtp;

  const AuthOtpVerifiedState({required this.verifiedOtp});

  @override
  List<Object?> get props => [verifiedOtp];
}

class AuthAstrologerPasswordLoginSuccessState extends AuthState {
  final LoginPasswordResponseModel loginResponse;

  const AuthAstrologerPasswordLoginSuccessState({required this.loginResponse});

  @override
  List<Object?> get props => [loginResponse];
}

class AuthErrorState extends AuthState {
  final String message;

  const AuthErrorState({required this.message});

  @override
  List<Object?> get props => [message];
}
