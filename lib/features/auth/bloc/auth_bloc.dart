import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/api/api_config.dart';
import '../../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc({required AuthRepository authRepository})
      // ignore: prefer_initializing_formals
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<OtpVerificationRequested>(_onOtpVerificationRequested);
    on<ForgotPasswordRequested>(_onForgotPasswordRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    final user = _authRepository.currentUser;
    if (user != null && ApiConfig.isAuthenticated) {
      emit(AuthAuthenticated(user: user));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.login(event.mobile, event.password);
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await _authRepository.register(
        name: event.name,
        mobile: event.mobile,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
      );
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('ApiException: ', '').replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onOtpVerificationRequested(
    OtpVerificationRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final verified = await _authRepository.verifyOtp(event.mobile, event.otp);
      if (verified) {
        final user = _authRepository.currentUser;
        if (user != null) {
          emit(AuthOtpVerified(user: user));
          emit(AuthAuthenticated(user: user));
        } else {
          emit(const AuthFailure(message: 'User session not found after OTP verification'));
        }
      } else {
        emit(const AuthFailure(message: 'Invalid OTP. Please try again.'));
      }
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onForgotPasswordRequested(
    ForgotPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.forgotPassword(event.mobile);
      emit(AuthForgotPasswordSent(mobile: event.mobile));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.logout();
    emit(const AuthUnauthenticated());
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final updated = await _authRepository.updateProfile(event.updatedUser);
      emit(AuthProfileUpdated(user: updated));
      emit(AuthAuthenticated(user: updated));
    } catch (e) {
      emit(AuthFailure(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
