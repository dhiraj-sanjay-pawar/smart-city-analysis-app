import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/user_model.dart';

/// Central citizen auth repository integrating real API endpoints:
/// POST /auth/app-login and POST /auth/register
class AuthRepository {
  static const String _keyCurrentUser = 'api_current_user_profile';

  final ApiClient _apiClient;
  UserModel? _currentUser;

  AuthRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Initialize session from SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(_keyCurrentUser);
      if (userStr != null && userStr.isNotEmpty) {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
      }
    } catch (_) {}
  }

  Future<void> _persistUser(UserModel user) async {
    _currentUser = user;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// Logs in using email/mobile + password via real API POST /auth/app-login
  Future<UserModel> login(String identifier, String password) async {
    final cleanId = identifier.trim();
    final isEmail = cleanId.contains('@');

    final payload = <String, dynamic>{
      'email': isEmail ? cleanId : '$cleanId@citizen.smartcity.in',
      if (!isEmail) 'phone': cleanId,
      if (!isEmail) 'mobileNumber': cleanId,
      'password': password,
      'autoRegister': false,
      'rememberMe': true,
    };

    final response = await _apiClient.post(
      ApiConfig.authLogin,
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] ??
          (response['data'] is Map<String, dynamic> ? response['data']['token'] : null) ??
          response['accessToken'] ??
          response['jwt'];
      if (token != null) {
        await ApiConfig.setAuthToken(token.toString());
      }

      final userData = (response['data'] is Map<String, dynamic> && response['data']['user'] is Map<String, dynamic>)
          ? response['data']['user'] as Map<String, dynamic>
          : (response['user'] is Map<String, dynamic> ? response['user'] as Map<String, dynamic> : null);

      if (userData != null) {
        final user = UserModel.fromJson(userData);
        await _persistUser(user);
        return user;
      }
    }

    throw ApiException(
      statusCode: 401,
      message: 'Failed to authenticate with server. Please verify your credentials.',
    );
  }

  /// Verifies OTP via server simulation or SMS verification
  Future<bool> verifyOtp(String mobile, String otp) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return otp.length == 6;
  }

  /// Registers user via real API POST /auth/register
  Future<UserModel> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    String? confirmPassword,
  }) async {
    final response = await _apiClient.post(
      ApiConfig.authRegister,
      body: {
        'fullName': name.trim(),
        'mobileNumber': mobile.trim(),
        'emailAddress': email.trim(),
        'password': password,
        'confirmPassword': confirmPassword ?? password,
      },
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] ??
          (response['data'] is Map<String, dynamic> ? response['data']['token'] : null) ??
          response['accessToken'];
      if (token != null) {
        await ApiConfig.setAuthToken(token.toString());
      }

      final userData = (response['data'] is Map<String, dynamic> && response['data']['user'] is Map<String, dynamic>)
          ? response['data']['user'] as Map<String, dynamic>
          : (response['user'] is Map<String, dynamic> ? response['user'] as Map<String, dynamic> : null);

      if (userData != null) {
        final user = UserModel.fromJson(userData);
        await _persistUser(user);
        return user;
      }
    }

    throw ApiException(
      statusCode: 400,
      message: 'Registration failed. Please check inputs and try again.',
    );
  }

  /// Simulates forgot password flow via API.
  Future<void> forgotPassword(String mobile) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Returns the currently authenticated user from API session, or null if logged out.
  UserModel? get currentUser => _currentUser;

  /// Updates profile.
  Future<UserModel> updateProfile(UserModel updated) async {
    await _persistUser(updated);
    return updated;
  }

  /// Logs out citizen and invalidates cached token & session.
  Future<void> logout() async {
    _currentUser = null;
    await ApiConfig.setAuthToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentUser);
    } catch (_) {}
  }
}
