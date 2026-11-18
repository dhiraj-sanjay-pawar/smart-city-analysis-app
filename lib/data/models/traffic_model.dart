import 'package:equatable/equatable.dart';

enum TrafficSeverity { clear, moderate, heavy, closed }

class TrafficCondition extends Equatable {
  final String id;
  final String roadName;
  final String area;
  final TrafficSeverity severity;
  final String description;
  final String? alternativeRoute;
  final DateTime updatedAt;
  final double distance; // km from city center
  final double? congestionPercentage;
  final int? averageSpeedKmh;
  final String? startPoint;
  final String? endPoint;
  final dynamic coordinatesJson;

  const TrafficCondition({
    required this.id,
    required this.roadName,
    required this.area,
    required this.severity,
    required this.description,
    this.alternativeRoute,
    required this.updatedAt,
    required this.distance,
    this.congestionPercentage,
    this.averageSpeedKmh,
    this.startPoint,
    this.endPoint,
    this.coordinatesJson,
  });

  static TrafficSeverity parseSeverity(dynamic val) {
    if (val == null) return TrafficSeverity.clear;
    final s = val.toString().toLowerCase();
    if (s.contains('close') || s.contains('blocked')) return TrafficSeverity.closed;
    if (s.contains('heavy') || s.contains('congested') || s.contains('high') || s.contains('severe')) return TrafficSeverity.heavy;
    if (s.contains('mod') || s.contains('slow') || s.contains('medium')) return TrafficSeverity.moderate;
    return TrafficSeverity.clear;
  }

  factory TrafficCondition.fromJson(Map<String, dynamic> json) {
    double parseDbl(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    final start = json['start_point']?.toString();
    final end = json['end_point']?.toString();
    final autoDesc = (start != null && end != null) ? '$start → $end' : 'Normal traffic flow observed.';

    return TrafficCondition(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'TR-${DateTime.now().millisecondsSinceEpoch}',
      roadName: json['route_name']?.toString() ?? json['roadName']?.toString() ?? json['routeName']?.toString() ?? json['name']?.toString() ?? 'Nashik Corridor',
      area: json['affected_area']?.toString() ?? json['area']?.toString() ?? json['zone']?.toString() ?? 'Nashik Kumbh Mela Zone',
      severity: parseSeverity(json['status'] ?? json['severity'] ?? json['congestionStatus']),
      description: json['description']?.toString() ?? autoDesc,
      alternativeRoute: json['alternativeRoute']?.toString() ?? json['alternate_route']?.toString(),
      updatedAt: json['updatedAt'] != null
          ? (DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      distance: parseDbl(json['distance'] ?? json['distanceKm'], 2.5),
      congestionPercentage: json['congestionPercentage'] != null ? parseDbl(json['congestionPercentage']) : null,
      averageSpeedKmh: parseInt(json['averageSpeed'] ?? json['speed']),
      startPoint: start,
      endPoint: end,
      coordinatesJson: json['coordinates_json'] ?? json['coordinates'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'route_name': roadName,
        'roadName': roadName,
        'affected_area': area,
        'area': area,
        'status': severity.name,
        'severity': severity.name,
        'description': description,
        'start_point': startPoint,
        'end_point': endPoint,
        'coordinates_json': coordinatesJson,
        'alternativeRoute': alternativeRoute,
        'updatedAt': updatedAt.toIso8601String(),
        'distance': distance,
        'congestionPercentage': congestionPercentage,
        'averageSpeedKmh': averageSpeedKmh,
      };

  String get severityLabel {
    switch (severity) {
      case TrafficSeverity.clear: return 'Clear';
      case TrafficSeverity.moderate: return 'Moderate';
      case TrafficSeverity.heavy: return 'Heavy';
      case TrafficSeverity.closed: return 'Closed';
    }
  }

  @override
  List<Object?> get props => [id, roadName, severity, updatedAt];
}

class TrafficAlert extends Equatable {
  final String id;
  final String title;
  final String message;
  final String area;
  final DateTime issuedAt;
  final bool isActive;

  const TrafficAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.area,
    required this.issuedAt,
    this.isActive = true,
  });

  factory TrafficAlert.fromJson(Map<String, dynamic> json) {
    return TrafficAlert(
      id: json['id']?.toString() ?? 'TA-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? 'Traffic Advisory',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      area: json['area']?.toString() ?? 'Nashik',
      issuedAt: json['issuedAt'] != null
          ? (DateTime.tryParse(json['issuedAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      isActive: json['isActive'] == null ? true : (json['isActive'] == true || json['isActive'] == 'true'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'area': area,
        'issuedAt': issuedAt.toIso8601String(),
        'isActive': isActive,
      };

  @override
  List<Object?> get props => [id, title, isActive];
}
