import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final dynamic errors;

  ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  @override
  String toString() => 'ApiException [$statusCode]: $message';
}

class ApiClient {
  final http.Client _httpClient;

  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  Map<String, String> _buildHeaders({Map<String, String>? extraHeaders}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'SmartCityNashikApp/1.0.0',
    };

    final token = ApiConfig.authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    return headers;
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final base = ApiConfig.baseUrl.trim();
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    final uri = Uri.parse(fullUrl);
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }

    final queryMap = <String, dynamic>{...uri.queryParameters};
    queryParameters.forEach((key, value) {
      if (value != null) {
        queryMap[key] = value.toString();
      }
    });

    return uri.replace(queryParameters: queryMap);
  }

  /// Perform GET request
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _httpClient
          .get(uri, headers: _buildHeaders(extraHeaders: headers))
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Connection timed out. Please verify network connectivity.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: ${e.toString()}');
    }
  }

  /// Perform POST request
  Future<dynamic> post(String path, {dynamic body, Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final response = await _httpClient
          .post(
            uri,
            headers: _buildHeaders(extraHeaders: headers),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Connection timed out. Please verify network connectivity.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Network error: ${e.toString()}');
    }
  }

  /// Perform download (bytes) for PDF / Excel export
  Future<Uint8List> downloadBytes(String path, {Map<String, dynamic>? queryParameters, Map<String, String>? headers}) async {
    final uri = _buildUri(path, queryParameters);
    try {
      final reqHeaders = _buildHeaders(extraHeaders: headers);
      reqHeaders.remove('Accept'); // Allow binary responses
      final response = await _httpClient
          .get(uri, headers: reqHeaders)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.bodyBytes;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: 'Failed to download report (HTTP ${response.statusCode})',
      );
    } on TimeoutException {
      throw ApiException(statusCode: 408, message: 'Report download timed out.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(statusCode: 0, message: 'Download error: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic decoded;
    if (response.body.isNotEmpty) {
      try {
        decoded = jsonDecode(response.body);
      } catch (_) {
        decoded = response.body;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Return 'data' field if enclosed in standard API wrapper {success: true, data: ...}
      if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
        return decoded['data'];
      }
      return decoded;
    }

    String message = 'Server error (${response.statusCode})';
    dynamic errors;
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('message')) {
        message = decoded['message'].toString();
      }
      if (decoded.containsKey('errors')) {
        errors = decoded['errors'];
      }
    }

    throw ApiException(
      statusCode: response.statusCode,
      message: message,
      errors: errors,
    );
  }
}
