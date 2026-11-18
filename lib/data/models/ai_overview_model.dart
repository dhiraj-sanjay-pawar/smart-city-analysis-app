import 'package:equatable/equatable.dart';

/// Represents a single domain entry in the multi-domain radar from GET /ai/overview.
/// Maps `visualData.multiDomainRadar[i]`.
class RadarDomainModel extends Equatable {
  final String domain;
  final double current;
  final double threshold;
  final double fullMark;

  const RadarDomainModel({
    required this.domain,
    required this.current,
    required this.threshold,
    required this.fullMark,
  });

  factory RadarDomainModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, double fallback) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    return RadarDomainModel(
      domain: json['domain']?.toString() ?? 'Unknown',
      current: parseDouble(json['current'], 0),
      threshold: parseDouble(json['threshold'], 100),
      fullMark: parseDouble(json['fullMark'], 100),
    );
  }

  /// Whether the current score exceeds the threshold (at-risk).
  bool get isAtRisk => current >= threshold;

  /// Normalised 0.0–1.0 progress for UI bars.
  double get currentRatio => fullMark > 0 ? (current / fullMark).clamp(0.0, 1.0) : 0.0;
  double get thresholdRatio => fullMark > 0 ? (threshold / fullMark).clamp(0.0, 1.0) : 0.0;

  @override
  List<Object?> get props => [domain, current, threshold, fullMark];
}

/// Citizen-relevant AI overview data from GET /ai/overview.
/// Parses `data.visualData.multiDomainRadar`.
class AiOverviewModel extends Equatable {
  final List<RadarDomainModel> radarDomains;
  final DateTime fetchedAt;

  const AiOverviewModel({
    required this.radarDomains,
    required this.fetchedAt,
  });

  /// Convenience: the domain with the highest current score.
  RadarDomainModel? get highestRiskDomain {
    if (radarDomains.isEmpty) return null;
    return radarDomains.reduce((a, b) => a.current > b.current ? a : b);
  }

  /// Citizen-facing safety status derived from domain data.
  String get safetyStatus {
    final atRisk = radarDomains.where((d) => d.isAtRisk).length;
    if (atRisk >= 3) return 'Critical';
    if (atRisk >= 1) return 'Elevated';
    return 'Normal';
  }

  /// Citizen-facing advisory.
  String get safetyAdvisory {
    final atRisk = radarDomains.where((d) => d.isAtRisk).toList();
    if (atRisk.isEmpty) return 'All city systems are operating within safe thresholds.';
    final names = atRisk.map((d) => d.domain).join(', ');
    return 'Elevated activity detected in: $names. Stay alert and follow official guidance.';
  }

  /// Parses directly from the `data` map returned by ApiClient
  /// (ApiClient already unwraps the top-level `data` key).
  factory AiOverviewModel.fromData(Map<String, dynamic> data) {
    final List<RadarDomainModel> domains = [];

    final visualData = data['visualData'];
    if (visualData is Map<String, dynamic>) {
      final radarList = visualData['multiDomainRadar'];
      if (radarList is List) {
        for (final item in radarList) {
          if (item is Map<String, dynamic>) {
            domains.add(RadarDomainModel.fromJson(item));
          }
        }
      }
    }

    return AiOverviewModel(
      radarDomains: domains,
      fetchedAt: DateTime.now(),
    );
  }

  /// Fallback: parses from full JSON envelope (for compatibility).
  factory AiOverviewModel.fromJson(Map<String, dynamic> json) {
    // ApiClient unwraps `data` → but we guard for both shapes
    if (json.containsKey('visualData')) {
      return AiOverviewModel.fromData(json);
    }
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return AiOverviewModel.fromData(data);
    }
    return AiOverviewModel(radarDomains: const [], fetchedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [radarDomains, fetchedAt];
}
