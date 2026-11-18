import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/ai_overview_model.dart';
import '../models/ai_predict_model.dart';
import '../models/ai_chat_model.dart';

/// Repository for AI & Predictive Analytics endpoints.
///
/// Citizen app boundary rules:
/// - GET /ai/overview  → citizen safety insights only.
/// - POST /ai/predict  → citizen-facing safety prediction (no admin dispatch).
/// - POST /ai/chat     → AI assistant responses.
/// - POST /ai/recommendation/execute → EXCLUDED (admin-only field dispatch).
/// - POST /ai/generate-report        → EXCLUDED (admin-only classified reports).
class AiRepository {
  final ApiClient _apiClient;

  AiRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches multi-domain safety insights from GET /ai/overview.
  /// Returns null on network failure to allow graceful dashboard degradation.
  Future<AiOverviewModel?> getCitizenOverview() async {
    try {
      final response = await _apiClient.get(ApiConfig.aiOverview);
      if (response is Map<String, dynamic>) {
        return AiOverviewModel.fromData(response);
      }
    } catch (_) {
      // Graceful fallback: dashboard still loads without AI data
    }
    return null;
  }

  /// Submits a safety prediction request to POST /ai/predict.
  /// Only validated, user-selectable inputs are forwarded.
  Future<AiPredictionResult> simulatePrediction(AiPredictRequest request) async {
    final response = await _apiClient.post(
      ApiConfig.aiPredict,
      body: request.toJson(),
    );
    if (response is Map<String, dynamic>) {
      return AiPredictionResult.fromData(response);
    }
    throw ApiException(
      statusCode: 0,
      message: 'Unexpected response format from prediction API.',
    );
  }

  /// Sends a citizen message to the AI assistant via POST /ai/chat.
  /// Citizen-facing only: no admin commands are forwarded.
  Future<AiChatResponse> sendChatMessage(String message) async {
    final response = await _apiClient.post(
      ApiConfig.aiChat,
      body: {'message': message},
    );
    if (response is Map<String, dynamic>) {
      return AiChatResponse.fromData(response);
    }
    throw ApiException(
      statusCode: 0,
      message: 'Unexpected response format from AI assistant.',
    );
  }
}
