import 'package:equatable/equatable.dart';

enum WastewaterIssueType { waterlogging, drainageBlockage, sewageOverflow, other }
enum WastewaterStatus { submitted, inProgress, resolved }

class WastewaterIssue extends Equatable {
  final String id;
  final WastewaterIssueType type;
  final String description;
  final String location;
  final WastewaterStatus status;
  final DateTime reportedAt;
  final String? imageUrl;
  final double? waterLevelMeters;
  final double? thresholdMeters;
  final double? flowRateLps;
  final String? sensorId;

  const WastewaterIssue({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    required this.status,
    required this.reportedAt,
    this.imageUrl,
    this.waterLevelMeters,
    this.thresholdMeters,
    this.flowRateLps,
    this.sensorId,
  });

  static WastewaterIssueType parseType(dynamic val) {
    if (val == null) return WastewaterIssueType.waterlogging;
    final s = val.toString().toLowerCase();
    if (s.contains('drain') || s.contains('block')) return WastewaterIssueType.drainageBlockage;
    if (s.contains('sew') || s.contains('overflow')) return WastewaterIssueType.sewageOverflow;
    if (s.contains('water') || s.contains('flood')) return WastewaterIssueType.waterlogging;
    return WastewaterIssueType.other;
  }

  static WastewaterStatus parseStatus(dynamic val) {
    if (val == null) return WastewaterStatus.submitted;
    final s = val.toString().toLowerCase();
    if (s.contains('progress') || s.contains('active')) return WastewaterStatus.inProgress;
    if (s.contains('resolve') || s.contains('normal')) return WastewaterStatus.resolved;
    return WastewaterStatus.submitted;
  }

  factory WastewaterIssue.fromJson(Map<String, dynamic> json) {
    double? parseDbl(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString());
    }

    final pointName = json['point_name']?.toString() ?? json['location']?.toString() ?? json['stationName']?.toString() ?? 'Godavari Basin Observation Point';

    return WastewaterIssue(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'WW-${DateTime.now().millisecondsSinceEpoch}',
      type: parseType(json['type'] ?? json['observationType'] ?? json['category']),
      description: json['description']?.toString() ?? json['observation']?.toString() ?? 'Water level recorded observation.',
      location: pointName,
      status: parseStatus(json['status_level'] ?? json['status'] ?? json['severity']),
      reportedAt: json['observation_timestamp'] != null
          ? (DateTime.tryParse(json['observation_timestamp'].toString()) ?? DateTime.now())
          : (json['reportedAt'] != null
              ? (DateTime.tryParse(json['reportedAt'].toString()) ?? DateTime.now())
              : (json['timestamp'] != null ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()) : DateTime.now())),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      waterLevelMeters: parseDbl(json['water_level_meters'] ?? json['waterLevel'] ?? json['water_level'] ?? json['level']),
      thresholdMeters: parseDbl(json['threshold'] ?? json['danger_level']),
      flowRateLps: parseDbl(json['flowRate'] ?? json['flow_rate']),
      sensorId: json['point_name']?.toString() ?? json['sensorId']?.toString() ?? json['sensor_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'description': description,
        'location': location,
        'status': status.name,
        'reportedAt': reportedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'waterLevelMeters': waterLevelMeters,
        'thresholdMeters': thresholdMeters,
        'flowRateLps': flowRateLps,
        'sensorId': sensorId,
      };

  String get typeLabel {
    switch (type) {
      case WastewaterIssueType.waterlogging: return 'Waterlogging';
      case WastewaterIssueType.drainageBlockage: return 'Drainage Blockage';
      case WastewaterIssueType.sewageOverflow: return 'Sewage Overflow';
      case WastewaterIssueType.other: return 'Other Observation';
    }
  }

  String get statusLabel {
    switch (status) {
      case WastewaterStatus.submitted: return 'Active / Submitted';
      case WastewaterStatus.inProgress: return 'Monitoring / In Progress';
      case WastewaterStatus.resolved: return 'Normal / Resolved';
    }
  }

  @override
  List<Object?> get props => [id, type, status, reportedAt, waterLevelMeters];
}
