import 'package:equatable/equatable.dart';

enum MapMarkerType { incident, wastewater, facility, ambulance }

/// Central Map Marker Model supporting all Smart City GIS layers:
/// - Incidents (layers.incidents)
/// - Wastewater Points (layers.wastewaterPoints)
/// - Facilities (layers.facilities)
/// - Ambulances (layers.ambulances)
class MapMarker extends Equatable {
  final String id;
  final String title;
  final String description;
  final MapMarkerType type;
  final double lat;
  final double lng;
  final String locationName;
  final String? refNumber;
  final String? category;
  final String? priority;
  final String? status;
  final String? departmentName;
  final String? pointCode;
  final String? riskLevel;
  final String? lastWaterLevel;
  final String? lastStatusLevel;
  final Map<String, dynamic>? properties;

  const MapMarker({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.lat,
    required this.lng,
    required this.locationName,
    this.refNumber,
    this.category,
    this.priority,
    this.status,
    this.departmentName,
    this.pointCode,
    this.riskLevel,
    this.lastWaterLevel,
    this.lastStatusLevel,
    this.properties,
  });

  /// Helper to check if this marker matches an issue category keyword.
  bool matchesCategory(String key) {
    final k = key.toLowerCase();
    final cat = (category ?? '').toLowerCase();
    final tit = title.toLowerCase();
    final desc = description.toLowerCase();
    final dept = (departmentName ?? '').toLowerCase();
    return cat.contains(k) || tit.contains(k) || desc.contains(k) || dept.contains(k);
  }

  /// Safely parses latitude and longitude from string, number, or null.
  /// Returns null if the value is missing, invalid, or outside geographic bounds.
  static double? parseCoordinate(dynamic val) {
    if (val == null) return null;
    if (val is num) {
      if (val.isNaN || val.isInfinite) return null;
      return val.toDouble();
    }
    final s = val.toString().trim();
    if (s.isEmpty) return null;
    final parsed = double.tryParse(s);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) return null;
    return parsed;
  }

  /// Factory to construct a MapMarker from specific API layer objects.
  static MapMarker? fromLayerJson(Map<String, dynamic> json, MapMarkerType layerType) {
    final lat = parseCoordinate(json['lat'] ?? json['latitude'] ?? json['y']);
    final lng = parseCoordinate(json['lng'] ?? json['longitude'] ?? json['x']);

    // If coordinates are invalid or null, discard to preserve map accuracy
    if (lat == null || lng == null) return null;

    final id = json['id']?.toString() ??
        json['ref_number']?.toString() ??
        json['point_code']?.toString() ??
        '${layerType.name}_${DateTime.now().millisecondsSinceEpoch}';

    switch (layerType) {
      case MapMarkerType.incident:
        final title = json['title']?.toString() ?? json['ref_number']?.toString() ?? 'Citizen Grievance';
        final desc = json['description']?.toString() ?? '';
        final location = json['location_name']?.toString() ??
            json['location']?.toString() ??
            'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        final priority = json['priority']?.toString() ?? 'Normal';
        final status = json['status']?.toString() ?? 'Reported';
        final department = json['department_name']?.toString() ??
            json['department']?.toString() ??
            'Municipal Services';
        final refNum = json['ref_number']?.toString() ?? json['refNumber']?.toString();
        final cat = json['category']?.toString() ?? 'Incident';

        return MapMarker(
          id: id,
          title: title,
          description: desc,
          type: MapMarkerType.incident,
          lat: lat,
          lng: lng,
          locationName: location,
          refNumber: refNum,
          category: cat,
          priority: priority,
          status: status,
          departmentName: department,
          properties: json,
        );

      case MapMarkerType.wastewater:
        final name = json['name']?.toString() ??
            json['point_code']?.toString() ??
            'Wastewater Monitoring Point';
        final pointCode = json['point_code']?.toString() ?? json['code']?.toString() ?? 'WW-PT';
        final pointType = json['type']?.toString() ?? 'Pumping Station';
        final risk = json['risk_level']?.toString() ?? json['risk']?.toString() ?? 'Normal';
        final waterLevel = json['last_water_level']?.toString() ?? json['water_level']?.toString() ?? '';
        final statusLevel = json['last_status_level']?.toString() ?? json['status']?.toString() ?? 'Operational';
        final location = json['location']?.toString() ??
            '$name • Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';

        return MapMarker(
          id: id,
          title: name,
          description: pointType,
          type: MapMarkerType.wastewater,
          lat: lat,
          lng: lng,
          locationName: location,
          pointCode: pointCode,
          riskLevel: risk,
          priority: risk,
          status: statusLevel,
          lastWaterLevel: waterLevel,
          lastStatusLevel: statusLevel,
          properties: json,
        );

      case MapMarkerType.facility:
        final name = json['name']?.toString() ??
            json['facilityName']?.toString() ??
            'Healthcare Facility';
        final facilityType = json['type']?.toString() ?? json['facilityType']?.toString() ?? 'Hospital';
        final address = json['address']?.toString() ??
            json['location']?.toString() ??
            'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
        final status = json['status']?.toString() ?? json['operational_status']?.toString() ?? 'Operational';

        return MapMarker(
          id: id,
          title: name,
          description: facilityType,
          type: MapMarkerType.facility,
          lat: lat,
          lng: lng,
          locationName: address,
          status: status,
          priority: facilityType,
          properties: json,
        );

      case MapMarkerType.ambulance:
        final vehicle = json['vehicle_number']?.toString() ??
            json['code']?.toString() ??
            json['name']?.toString() ??
            'Emergency Ambulance';
        final status = json['status']?.toString() ?? 'On Duty';
        final loc = json['location']?.toString() ??
            'Active Location: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

        return MapMarker(
          id: id,
          title: vehicle,
          description: status,
          type: MapMarkerType.ambulance,
          lat: lat,
          lng: lng,
          locationName: loc,
          status: status,
          priority: 'Emergency',
          properties: json,
        );
    }
  }

  /// General JSON parser with backwards-compatibility for existing screens
  factory MapMarker.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? json['category'] ?? '').toString().toLowerCase();
    MapMarkerType type = MapMarkerType.incident;
    if (typeStr.contains('waste') || typeStr.contains('water') || typeStr.contains('drain') || typeStr.contains('pump')) {
      type = MapMarkerType.wastewater;
    } else if (typeStr.contains('hosp') || typeStr.contains('health') || typeStr.contains('facilit')) {
      type = MapMarkerType.facility;
    } else if (typeStr.contains('ambul') || typeStr.contains('medic')) {
      type = MapMarkerType.ambulance;
    }

    final marker = fromLayerJson(json, type);
    if (marker != null) return marker;

    return MapMarker(
      id: json['id']?.toString() ?? 'M-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? json['name']?.toString() ?? 'Feature',
      description: json['description']?.toString() ?? '',
      type: type,
      lat: parseCoordinate(json['lat']) ?? 0.0,
      lng: parseCoordinate(json['lng']) ?? 0.0,
      locationName: json['location_name']?.toString() ?? json['location']?.toString() ?? '',
      properties: json,
    );
  }

  String get typeLabel {
    switch (type) {
      case MapMarkerType.incident:
        return 'Incident';
      case MapMarkerType.wastewater:
        return 'Wastewater';
      case MapMarkerType.facility:
        return 'Facility';
      case MapMarkerType.ambulance:
        return 'Ambulance';
    }
  }

  @override
  List<Object?> get props => [id, type, lat, lng, title, priority, status];
}

/// Initial map center and zoom model from data.center
class MapCenter extends Equatable {
  final double lat;
  final double lng;
  final double defaultZoom;
  final bool hasPoints;
  final int pointCount;

  const MapCenter({
    required this.lat,
    required this.lng,
    this.defaultZoom = 15.0,
    this.hasPoints = false,
    this.pointCount = 0,
  });

  factory MapCenter.fromJson(Map<String, dynamic> json) {
    final lat = MapMarker.parseCoordinate(json['lat']) ?? 0.0;
    final lng = MapMarker.parseCoordinate(json['lng']) ?? 0.0;
    double zoom = 15.0;
    if (json['defaultZoom'] != null) {
      final z = double.tryParse(json['defaultZoom'].toString());
      if (z != null && z > 0) zoom = z;
    }
    return MapCenter(
      lat: lat,
      lng: lng,
      defaultZoom: zoom,
      hasPoints: json['hasPoints'] == true || json['hasPoints'] == 'true',
      pointCount: int.tryParse(json['pointCount']?.toString() ?? '') ?? 0,
    );
  }

  @override
  List<Object?> get props => [lat, lng, defaultZoom, hasPoints, pointCount];
}

/// Comprehensive Map Features Data Model parsing GET /map/features response
class MapFeaturesData extends Equatable {
  final MapCenter center;
  final List<MapMarker> incidents;
  final List<MapMarker> wastewaterPoints;
  final List<MapMarker> facilities;
  final List<MapMarker> ambulances;

  const MapFeaturesData({
    required this.center,
    this.incidents = const [],
    this.wastewaterPoints = const [],
    this.facilities = const [],
    this.ambulances = const [],
  });

  List<MapMarker> get allMarkers => [
        ...incidents,
        ...wastewaterPoints,
        ...facilities,
        ...ambulances,
      ];

  bool get isEmpty => allMarkers.isEmpty;

  factory MapFeaturesData.fromJson(Map<String, dynamic> json) {
    // Unpack data wrapper if present
    final data = json.containsKey('data') && json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final centerJson = data['center'] is Map<String, dynamic>
        ? data['center'] as Map<String, dynamic>
        : <String, dynamic>{};
    final center = MapCenter.fromJson(centerJson);

    final layers = data['layers'] is Map<String, dynamic>
        ? data['layers'] as Map<String, dynamic>
        : <String, dynamic>{};

    List<MapMarker> parseLayer(dynamic listData, MapMarkerType type) {
      if (listData is! List) return [];
      final result = <MapMarker>[];
      for (final item in listData) {
        if (item is Map<String, dynamic>) {
          final marker = MapMarker.fromLayerJson(item, type);
          if (marker != null) {
            result.add(marker);
          }
        }
      }
      return result;
    }

    final incidents = parseLayer(layers['incidents'], MapMarkerType.incident);
    final wastewater = parseLayer(layers['wastewaterPoints'], MapMarkerType.wastewater);
    final facilities = parseLayer(layers['facilities'], MapMarkerType.facility);
    final ambulances = parseLayer(layers['ambulances'], MapMarkerType.ambulance);

    return MapFeaturesData(
      center: center,
      incidents: incidents,
      wastewaterPoints: wastewater,
      facilities: facilities,
      ambulances: ambulances,
    );
  }

  @override
  List<Object?> get props => [center, incidents, wastewaterPoints, facilities, ambulances];
}
