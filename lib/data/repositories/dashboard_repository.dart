import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/dashboard_summary_model.dart';

/// Dashboard repository integrating real API GET /dashboard/summary
class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches real KPIs, statistics, and charts from GET /dashboard/summary
  Future<DashboardSummaryModel> getSummary() async {
    final response = await _apiClient.get(ApiConfig.dashboardSummary);
    if (response is Map<String, dynamic>) {
      return DashboardSummaryModel.fromJson(response);
    }
    throw ApiException(
      statusCode: 500,
      message: 'Failed to retrieve municipal dashboard summary from API.',
    );
  }
}
