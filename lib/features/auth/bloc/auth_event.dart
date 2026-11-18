import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class LoginRequested extends AuthEvent {
  final String mobile;
  final String password;
  const LoginRequested({required this.mobile, required this.password});
  @override
  List<Object?> get props => [mobile, password];
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String mobile;
  final String email;
  final String password;
  final String? confirmPassword;

  const RegisterRequested({
    required this.name,
    required this.mobile,
    required this.email,
    required this.password,
    this.confirmPassword,
  });

  @override
  List<Object?> get props => [name, mobile, email, password, confirmPassword];
}

class OtpVerificationRequested extends AuthEvent {
  final String mobile;
  final String otp;
  const OtpVerificationRequested({required this.mobile, required this.otp});
  @override
  List<Object?> get props => [mobile, otp];
}

class ForgotPasswordRequested extends AuthEvent {
  final String mobile;
  const ForgotPasswordRequested({required this.mobile});
  @override
  List<Object?> get props => [mobile];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ProfileUpdateRequested extends AuthEvent {
  final UserModel updatedUser;
  const ProfileUpdateRequested({required this.updatedUser});
  @override
  List<Object?> get props => [updatedUser];
}
