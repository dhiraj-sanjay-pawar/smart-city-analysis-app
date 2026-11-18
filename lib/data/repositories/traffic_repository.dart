import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/traffic_model.dart';

/// Traffic repository integrating real API GET /traffic/routes.
class TrafficRepository {
  final ApiClient _apiClient;
  List<TrafficCondition> _cachedConditions = [];

  List<TrafficCondition> get cachedConditions => _cachedConditions;

  TrafficRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Returns routes and congestion status from GET /traffic/routes
  Future<List<TrafficCondition>> getAllConditions() async {
    final response = await _apiClient.get(ApiConfig.trafficRoutes);
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['routes'] is List) {
        items = data['routes'] as List;
      } else if (response['routes'] is List) {
        items = response['routes'] as List;
      }
    }

    final routes = items
        .whereType<Map<String, dynamic>>()
        .map((e) => TrafficCondition.fromJson(e))
        .toList();
    _cachedConditions = routes;
    return routes;
  }

  /// Returns conditions filtered by severity.
  Future<List<TrafficCondition>> getConditionsBySeverity(TrafficSeverity severity) async {
    final list = await getAllConditions();
    return list.where((c) => c.severity == severity).toList();
  }

  /// Returns all active traffic alerts from GET /alerts
  Future<List<TrafficAlert>> getAlerts() async {
    try {
      final response = await _apiClient.get(ApiConfig.alerts);
      List<dynamic> items = [];
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic> && data['alerts'] is List) {
          items = data['alerts'] as List;
        } else if (response['alerts'] is List) {
          items = response['alerts'] as List;
        }
      }

      return items
          .whereType<Map<String, dynamic>>()
          .where((j) {
            final type = (j['type'] ?? j['category'] ?? '').toString().toLowerCase();
            return type.contains('traffic') || type.contains('route') || type.contains('road');
          })
          .map((e) => TrafficAlert.fromJson(e))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Returns road closures.
  Future<List<TrafficCondition>> getRoadClosures() async {
    final list = await getAllConditions();
    return list.where((c) => c.severity == TrafficSeverity.closed).toList();
  }

  /// Searches traffic conditions by road name or area.
  Future<List<TrafficCondition>> searchConditions(String query) async {
    final list = await getAllConditions();
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((c) {
      return c.roadName.toLowerCase().contains(q) || c.area.toLowerCase().contains(q);
    }).toList();
  }
}
