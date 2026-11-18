import 'package:equatable/equatable.dart';

/// Request payload for POST /ai/predict.
/// Only fields supported by the backend are included.
class AiPredictRequest extends Equatable {
  final String sector;
  final String timeWindow;
  final double crowdDensity;
  final int vehicleInflow;
  final String weatherCondition;

  const AiPredictRequest({
    required this.sector,
    required this.timeWindow,
    required this.crowdDensity,
    required this.vehicleInflow,
    required this.weatherCondition,
  });

  Map<String, dynamic> toJson() => {
        'sector': sector,
        'timeWindow': timeWindow,
        'crowdDensity': crowdDensity,
        'vehicleInflow': vehicleInflow,
        'weatherCondition': weatherCondition,
      };

  @override
  List<Object?> get props =>
      [sector, timeWindow, crowdDensity, vehicleInflow, weatherCondition];
}

/// Parsed citizen-facing prediction from POST /ai/predict.
/// Maps `data.prediction` from the API response.
/// Admin/operational fields (dispatch, choke point probability) are NOT exposed.
class AiPredictionResult extends Equatable {
  final double overallRiskScore;
  final String riskLevel;
  final String confidenceInterval;
  final int estimatedIncidentVolume;
  final String primaryThreat;
  final List<String> actionableRecommendations;

  // Echo-back of the simulation inputs
  final String sector;
  final String timeWindow;
  final String weatherCondition;

  const AiPredictionResult({
    required this.overallRiskScore,
    required this.riskLevel,
    required this.confidenceInterval,
    required this.estimatedIncidentVolume,
    required this.primaryThreat,
    required this.actionableRecommendations,
    required this.sector,
    required this.timeWindow,
    required this.weatherCondition,
  });

  /// Parses from the `data` map (ApiClient unwraps top-level `data`).
  factory AiPredictionResult.fromData(Map<String, dynamic> data) {
    double parseDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int parseInt(dynamic v, int fallback) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    final prediction = data['prediction'] as Map<String, dynamic>? ?? {};
    final input = data['simulationInput'] as Map<String, dynamic>? ?? {};

    final List<String> recommendations = [];
    final rawRec = prediction['actionableRecommendations'];
    if (rawRec is List) {
      for (final r in rawRec) {
        if (r is String && r.isNotEmpty) recommendations.add(r);
      }
    }

    return AiPredictionResult(
      overallRiskScore: parseDouble(prediction['overallRiskScore'], 0),
      riskLevel: prediction['riskLevel']?.toString() ?? 'Unknown',
      confidenceInterval: prediction['confidenceInterval']?.toString() ?? 'N/A',
      estimatedIncidentVolume: parseInt(prediction['estimatedIncidentVolume'], 0),
      primaryThreat: prediction['primaryThreat']?.toString() ?? 'No threat identified.',
      actionableRecommendations: recommendations,
      sector: input['sector']?.toString() ?? '',
      timeWindow: input['timeWindow']?.toString() ?? '',
      weatherCondition:
          input['weatherCondition']?.toString() ?? '',
    );
  }

  /// Risk level colour helper (returns a hex string for use in UI).
  String get riskLevelColour {
    switch (riskLevel.toLowerCase()) {
      case 'critical':
        return '#DC2626';
      case 'high':
        return '#D97706';
      case 'moderate':
        return '#0284C7';
      case 'low':
        return '#16A34A';
      default:
        return '#64748B';
    }
  }

  @override
  List<Object?> get props => [
        overallRiskScore,
        riskLevel,
        confidenceInterval,
        estimatedIncidentVolume,
        primaryThreat,
        actionableRecommendations,
        sector,
        timeWindow,
        weatherCondition,
      ];
}
