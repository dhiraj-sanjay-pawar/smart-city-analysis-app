import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/wastewater_model.dart';

/// Wastewater repository integrating real API GET /wastewater/observations.
class WastewaterRepository {
  final ApiClient _apiClient;
  final List<WastewaterIssue> _issues = [];

  WastewaterRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Returns water-level observations from GET /wastewater/observations
  Future<List<WastewaterIssue>> getIssues() async {
    final response = await _apiClient.get(ApiConfig.wastewaterObservations);
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['observations'] is List) {
        items = data['observations'] as List;
      } else if (response['observations'] is List) {
        items = response['observations'] as List;
      }
    }

    final observations = items
        .whereType<Map<String, dynamic>>()
        .map((e) => WastewaterIssue.fromJson(e))
        .toList();
    _issues.clear();
    _issues.addAll(observations);
    return List.unmodifiable(_issues);
  }

  /// Submits a new wastewater observation or issue via POST /wastewater/observations
  Future<WastewaterIssue> submitIssue({
    required WastewaterIssueType type,
    required String description,
    required String location,
    double? waterLevelMeters,
  }) async {
    final payload = <String, dynamic>{
      'type': type.name,
      'description': description.trim(),
      'location': location.trim(),
      'status': 'submitted',
    };
    if (waterLevelMeters != null) payload['waterLevel'] = waterLevelMeters;

    final response = await _apiClient.post(
      ApiConfig.wastewaterObservations,
      body: payload,
    );

    if (response is Map<String, dynamic>) {
      final item = (response['data'] is Map<String, dynamic>)
          ? response['data'] as Map<String, dynamic>
          : response;
      final created = WastewaterIssue.fromJson(item);
      _issues.insert(0, created);
      return created;
    }

    throw ApiException(
      statusCode: 500,
      message: 'Failed to record observation on municipal server.',
    );
  }
}
