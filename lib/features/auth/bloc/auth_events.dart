import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
}

class SendOtpEvent extends AuthEvent {
  final String phoneNumber;

  const SendOtpEvent({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

class VerifyOtpEvent extends AuthEvent {
  final String phoneNumber;
  final String sessionId;
  final String otp;

  const VerifyOtpEvent({
    required this.phoneNumber,
    required this.sessionId,
    required this.otp,
  });

  @override
  List<Object?> get props => [phoneNumber, sessionId, otp];
}

class AstrologerLoginWithPasswordEvent extends AuthEvent {
  final String identifier;
  final String password;

  const AstrologerLoginWithPasswordEvent({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutUserEvent extends AuthEvent {
  const LogoutUserEvent();

  @override
  List<Object?> get props => [];
}

class LogoutAstrologerEvent extends AuthEvent {
  const LogoutAstrologerEvent();

  @override
  List<Object?> get props => [];
}

class CheckLoginStatusEvent extends AuthEvent {
  const CheckLoginStatusEvent();

  @override
  List<Object?> get props => [];
}