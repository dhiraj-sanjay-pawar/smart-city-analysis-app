import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/api/api_config.dart';
import '../models/map_marker_model.dart';

/// Map repository integrating real API GET /map/features using Dio and Bearer token.
class MapRepository {
  final Dio _dio;
  MapFeaturesData? _cachedData;

  MapRepository({Dio? dio}) : _dio = dio ?? Dio();

  MapCenter? get center => _cachedData?.center;
  double? get centerLat => _cachedData?.center.lat;
  double? get centerLng => _cachedData?.center.lng;
  double? get defaultZoom => _cachedData?.center.defaultZoom;

  /// Fetches geocoded features and layers from GET /map/features using Dio and Bearer token
  Future<MapFeaturesData> getMapFeatures() async {
    final headers = <String, dynamic>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'User-Agent': 'SmartCityNashikApp/1.0.0',
    };

    final token = ApiConfig.authToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final options = Options(
      headers: headers,
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    );

    final cleanUrl = '${ApiConfig.baseUrl}${ApiConfig.mapFeatures}';

    try {
      final response = await _dio.get(cleanUrl, options: options);

      dynamic rawData = response.data;
      if (rawData is String && rawData.isNotEmpty) {
        try {
          rawData = jsonDecode(rawData);
        } catch (_) {}
      }

      if (rawData is Map<String, dynamic>) {
        final data = MapFeaturesData.fromJson(rawData);
        _cachedData = data;
        return data;
      }

      throw Exception('Invalid map features response format from server.');
    } on DioException catch (e) {
      final resData = e.response?.data;
      String message = 'Network error connecting to municipal map server.';
      if (resData is Map && resData.containsKey('message')) {
        message = resData['message'].toString();
      } else if (e.message != null && e.message!.isNotEmpty) {
        message = e.message!;
      }
      throw Exception(message);
    }
  }

  /// Backwards-compatible method returning flat list of all markers
  Future<List<MapMarker>> getFeatures() async {
    final data = await getMapFeatures();
    return data.allMarkers;
  }
}
