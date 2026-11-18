import 'package:shared_preferences/shared_preferences.dart';

/// Central API Configuration for Smart City Analytics application.
class ApiConfig {
  ApiConfig._();

  // ── Base URLs ─────────────────────────────────────────────────────────────
  static const String productionBaseUrl = 'https://smartcity.techsparkventures.in/api/v1';
  static const String localDevelopmentBaseUrl = 'http://localhost:5000/api/v1';

  static const String _keyUseLocalDev = 'api_use_local_dev';
  static const String _keyCustomBaseUrl = 'api_custom_base_url';
  static const String _keyAuthToken = 'api_auth_token';

  static bool _isLocalDev = false;
  static String? _customBaseUrl;
  static String? _authToken;

  /// Initialize config from SharedPreferences
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isLocalDev = prefs.getBool(_keyUseLocalDev) ?? false;
      _customBaseUrl = prefs.getString(_keyCustomBaseUrl);
      _authToken = prefs.getString(_keyAuthToken);
    } catch (_) {}
  }

  /// Current active Base URL (production by default)
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    return _isLocalDev ? localDevelopmentBaseUrl : productionBaseUrl;
  }

  /// Whether local development mode is active
  static bool get isLocalDev => _isLocalDev;

  /// Switch between production and local development URL
  static Future<void> setUseLocalDev(bool value) async {
    _isLocalDev = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyUseLocalDev, value);
    } catch (_) {}
  }

  /// Override with a custom base URL (e.g., staging or specific IP)
  static Future<void> setCustomBaseUrl(String? url) async {
    _customBaseUrl = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (url != null && url.isNotEmpty) {
        await prefs.setString(_keyCustomBaseUrl, url);
      } else {
        await prefs.remove(_keyCustomBaseUrl);
      }
    } catch (_) {}
  }

  /// Auth token management
  static String? get authToken => _authToken;

  static Future<void> setAuthToken(String? token) async {
    _authToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null && token.isNotEmpty) {
        await prefs.setString(_keyAuthToken, token);
      } else {
        await prefs.remove(_keyAuthToken);
      }
    } catch (_) {}
  }

  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';
  static const String incidents = '/incidents';
  static const String trafficRoutes = '/traffic/routes';
  static const String healthcareFacilities = '/healthcare/facilities';
  static const String wastewaterObservations = '/wastewater/observations';
  static const String alerts = '/alerts';
  static const String mapFeatures = '/map/features';
  static const String reportsExport = '/reports/export';
  static const String authLogin = '/auth/app-login';
  static const String authRegister = '/auth/register';
  static const String aiOverview = '/ai/overview';
  static const String aiPredict = '/ai/predict';
  static const String aiChat = '/ai/chat';
}
