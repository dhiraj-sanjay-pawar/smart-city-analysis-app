import 'package:equatable/equatable.dart';

class DashboardKpis extends Equatable {
  final int totalIncidents;
  final int resolvedIncidents;
  final int activeIncidents;
  final int openIncidents;
  final int criticalIncidents;
  final int activeAlerts;
  final int totalHospitals;
  final int availableBeds;
  final double trafficCongestionIndex;
  final int wastewaterAlerts;

  const DashboardKpis({
    this.totalIncidents = 0,
    this.resolvedIncidents = 0,
    this.activeIncidents = 0,
    this.openIncidents = 0,
    this.criticalIncidents = 0,
    this.activeAlerts = 0,
    this.totalHospitals = 0,
    this.availableBeds = 0,
    this.trafficCongestionIndex = 0.0,
    this.wastewaterAlerts = 0,
  });

  factory DashboardKpis.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, [int def = 0]) {
      if (val == null) return def;
      if (val is int) return val;
      if (val is double) return val.toInt();
      return int.tryParse(val.toString()) ?? def;
    }

    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      return double.tryParse(val.toString()) ?? def;
    }

    final total = parseInt(json['totalIncidents'] ?? json['total_incidents'] ?? json['totalGrievances']);
    final open = parseInt(json['openIncidents'] ?? json['open_incidents'] ?? json['activeIncidents'] ?? json['active_incidents'] ?? json['pendingIncidents']);
    final critical = parseInt(json['criticalIncidents'] ?? json['critical_incidents']);
    final resolvedRaw = json['resolvedIncidents'] ?? json['resolved_incidents'] ?? json['resolvedGrievances'];
    final resolved = resolvedRaw != null
        ? parseInt(resolvedRaw)
        : (total >= open ? (total - open) : 0);

    return DashboardKpis(
      totalIncidents: total,
      resolvedIncidents: resolved,
      activeIncidents: open,
      openIncidents: open,
      criticalIncidents: critical,
      activeAlerts: parseInt(json['activeAlerts'] ?? json['active_alerts'] ?? json['totalAlerts'], critical),
      totalHospitals: parseInt(json['totalHospitals'] ?? json['total_hospitals'] ?? json['hospitalsCount'], 42),
      availableBeds: parseInt(json['availableBeds'] ?? json['available_beds'] ?? json['totalBedsAvailable'], 685),
      trafficCongestionIndex: parseDouble(json['trafficCongestionIndex'] ?? json['traffic_index'] ?? json['averageCongestion'], 38.0),
      wastewaterAlerts: parseInt(json['wastewaterAlerts'] ?? json['wastewater_alerts'] ?? json['drainageAlerts'], 0),
    );
  }

  @override
  List<Object?> get props => [
        totalIncidents,
        resolvedIncidents,
        activeIncidents,
        openIncidents,
        criticalIncidents,
        activeAlerts,
        totalHospitals,
        availableBeds,
        trafficCongestionIndex,
        wastewaterAlerts,
      ];
}

class DashboardSummaryModel extends Equatable {
  final DashboardKpis kpis;
  final Map<String, int> incidentsByCategory;
  final Map<String, int> incidentsByStatus;
  final List<double> weeklyTrends;
  final String? cityName;
  final DateTime lastUpdated;

  const DashboardSummaryModel({
    required this.kpis,
    this.incidentsByCategory = const {},
    this.incidentsByStatus = const {},
    this.weeklyTrends = const [],
    this.cityName = 'Nashik',
    required this.lastUpdated,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> rawJson) {
    final json = (rawJson['data'] is Map<String, dynamic>)
        ? rawJson['data'] as Map<String, dynamic>
        : rawJson;

    DashboardKpis kpis = const DashboardKpis();
    if (json.containsKey('kpis') && json['kpis'] is Map<String, dynamic>) {
      kpis = DashboardKpis.fromJson(json['kpis'] as Map<String, dynamic>);
    } else {
      kpis = DashboardKpis.fromJson(json);
    }

    final catMap = <String, int>{};
    if (json['incidentsByCategory'] is Map) {
      (json['incidentsByCategory'] as Map).forEach((k, v) {
        catMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    final statusMap = <String, int>{};
    if (json['incidentsByStatus'] is Map) {
      (json['incidentsByStatus'] as Map).forEach((k, v) {
        statusMap[k.toString()] = int.tryParse(v.toString()) ?? 0;
      });
    }

    final trends = <double>[];
    if (json['weeklyTrends'] is List) {
      for (final item in json['weeklyTrends'] as List) {
        trends.add(double.tryParse(item.toString()) ?? 0.0);
      }
    }

    DateTime updated = DateTime.now();
    if (json['lastUpdated'] != null) {
      updated = DateTime.tryParse(json['lastUpdated'].toString()) ?? DateTime.now();
    }

    return DashboardSummaryModel(
      kpis: kpis,
      incidentsByCategory: catMap,
      incidentsByStatus: statusMap,
      weeklyTrends: trends,
      cityName: json['cityName']?.toString() ?? 'Nashik',
      lastUpdated: updated,
    );
  }

  @override
  List<Object?> get props => [kpis, incidentsByCategory, incidentsByStatus, weeklyTrends, cityName, lastUpdated];
}
