import 'package:equatable/equatable.dart';
import '../../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  const AuthAuthenticated({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthOtpSent extends AuthState {
  final String mobile;
  const AuthOtpSent({required this.mobile});
  @override
  List<Object?> get props => [mobile];
}

class AuthOtpVerified extends AuthState {
  final UserModel user;
  const AuthOtpVerified({required this.user});
  @override
  List<Object?> get props => [user];
}

class AuthForgotPasswordSent extends AuthState {
  final String mobile;
  const AuthForgotPasswordSent({required this.mobile});
  @override
  List<Object?> get props => [mobile];
}

class AuthFailure extends AuthState {
  final String message;
  const AuthFailure({required this.message});
  @override
  List<Object?> get props => [message];
}

class AuthProfileUpdated extends AuthState {
  final UserModel user;
  const AuthProfileUpdated({required this.user});
  @override
  List<Object?> get props => [user];
}
