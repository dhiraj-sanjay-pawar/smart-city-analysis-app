import 'package:equatable/equatable.dart';

enum ComplaintStatus { submitted, inProgress, resolved, rejected }

enum ComplaintCategory {
  road,
  water,
  electricity,
  sanitation,
  healthcare,
  crime,
  wastewater,
  traffic,
  other,
}

class ComplaintStatusHistory extends Equatable {
  final ComplaintStatus status;
  final DateTime timestamp;
  final String note;

  const ComplaintStatusHistory({
    required this.status,
    required this.timestamp,
    required this.note,
  });

  factory ComplaintStatusHistory.fromJson(Map<String, dynamic> json) {
    ComplaintStatus parseStatus(dynamic val) {
      final s = val?.toString().toLowerCase() ?? '';
      if (s.contains('progress') || s.contains('assigned')) return ComplaintStatus.inProgress;
      if (s.contains('resolve') || s.contains('closed')) return ComplaintStatus.resolved;
      if (s.contains('reject')) return ComplaintStatus.rejected;
      return ComplaintStatus.submitted;
    }

    return ComplaintStatusHistory(
      status: parseStatus(json['status']),
      timestamp: json['timestamp'] != null
          ? (DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
          : DateTime.now(),
      note: json['note']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        'note': note,
      };

  @override
  List<Object?> get props => [status, timestamp, note];
}

class ComplaintModel extends Equatable {
  final String id;
  final String? refNumber;
  final String title;
  final String description;
  final ComplaintCategory category;
  final ComplaintStatus status;
  final String location;
  final DateTime submittedAt;
  final String? imageUrl;
  final List<ComplaintStatusHistory> statusHistory;
  final double? latitude;
  final double? longitude;
  final String? priority;
  final String? createdByUserId;
  final String? createdByName;

  const ComplaintModel({
    required this.id,
    this.refNumber,
    required this.title,
    required this.description,
    required this.category,
    required this.status,
    required this.location,
    required this.submittedAt,
    this.imageUrl,
    this.statusHistory = const [],
    this.latitude,
    this.longitude,
    this.priority,
    this.createdByUserId,
    this.createdByName,
  });

  static ComplaintCategory parseCategory(dynamic val) {
    if (val == null) return ComplaintCategory.other;
    final s = val.toString().toLowerCase();
    if (s.contains('road') || s.contains('pothole')) return ComplaintCategory.road;
    if (s.contains('waste') || s.contains('drain') || s.contains('sewer')) return ComplaintCategory.wastewater;
    if (s.contains('water')) return ComplaintCategory.water;
    if (s.contains('electric') || s.contains('power') || s.contains('light')) return ComplaintCategory.electricity;
    if (s.contains('sanitat') || s.contains('garbage') || s.contains('clean')) return ComplaintCategory.sanitation;
    if (s.contains('health') || s.contains('hosp') || s.contains('medic') || s.contains('clinic')) return ComplaintCategory.healthcare;
    if (s.contains('crime') || s.contains('police') || s.contains('safety')) return ComplaintCategory.crime;
    if (s.contains('traffic')) return ComplaintCategory.traffic;
    return ComplaintCategory.other;
  }

  static ComplaintStatus parseStatus(dynamic val) {
    if (val == null) return ComplaintStatus.submitted;
    final s = val.toString().toLowerCase();
    if (s.contains('progress') || s.contains('assigned') || s.contains('investigating')) return ComplaintStatus.inProgress;
    if (s.contains('resolve') || s.contains('completed') || s.contains('closed')) return ComplaintStatus.resolved;
    if (s.contains('reject') || s.contains('cancelled')) return ComplaintStatus.rejected;
    return ComplaintStatus.submitted;
  }

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    List<ComplaintStatusHistory> history = [];
    if (json['statusHistory'] is List) {
      history = (json['statusHistory'] as List)
          .whereType<Map<String, dynamic>>()
          .map((h) => ComplaintStatusHistory.fromJson(h))
          .toList();
    }

    double? lat;
    double? lng;
    if (json['latitude'] != null) lat = double.tryParse(json['latitude'].toString());
    if (json['longitude'] != null) lng = double.tryParse(json['longitude'].toString());
    if (lat == null && json['location_coordinates'] is Map) {
      lat = double.tryParse(json['location_coordinates']['lat']?.toString() ?? '');
      lng = double.tryParse(json['location_coordinates']['lng']?.toString() ?? '');
    }

    final refNum = json['ref_number']?.toString() ?? json['refNumber']?.toString();
    final locName = json['location_name']?.toString() ?? json['location']?.toString() ?? json['address']?.toString() ?? 'Nashik, Maharashtra';
    final createdBy = (json['created_by_user_id'] ?? json['userId'] ?? json['created_by'])?.toString();
    final createdName = (json['created_by_name'] ?? json['userName'] ?? json['author'])?.toString();

    return ComplaintModel(
      id: refNum ?? json['id']?.toString() ?? json['_id']?.toString() ?? 'INC-${DateTime.now().millisecondsSinceEpoch}',
      refNumber: refNum,
      title: json['title']?.toString() ?? 'Civic Grievance',
      description: json['description']?.toString() ?? '',
      category: parseCategory(json['category'] ?? json['department'] ?? json['title']),
      status: parseStatus(json['status']),
      location: locName,
      submittedAt: json['submittedAt'] != null
          ? (DateTime.tryParse(json['submittedAt'].toString()) ?? DateTime.now())
          : (json['createdAt'] != null ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()) : DateTime.now()),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      statusHistory: history,
      latitude: lat,
      longitude: lng,
      priority: json['priority']?.toString(),
      createdByUserId: createdBy,
      createdByName: createdName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ref_number': refNumber,
        'title': title,
        'description': description,
        'category': category.name,
        'status': status.name,
        'location': location,
        'submittedAt': submittedAt.toIso8601String(),
        'imageUrl': imageUrl,
        'latitude': latitude,
        'longitude': longitude,
        'priority': priority,
        'created_by_user_id': createdByUserId,
        'created_by_name': createdByName,
      };

  String get categoryLabel {
    switch (category) {
      case ComplaintCategory.road: return 'Road Issue';
      case ComplaintCategory.water: return 'Water Supply';
      case ComplaintCategory.electricity: return 'Electricity';
      case ComplaintCategory.sanitation: return 'Sanitation';
      case ComplaintCategory.healthcare: return 'Healthcare';
      case ComplaintCategory.crime: return 'Crime';
      case ComplaintCategory.wastewater: return 'Wastewater';
      case ComplaintCategory.traffic: return 'Traffic';
      case ComplaintCategory.other: return 'Other';
    }
  }

  String get statusLabel {
    switch (status) {
      case ComplaintStatus.submitted: return 'Submitted';
      case ComplaintStatus.inProgress: return 'In Progress';
      case ComplaintStatus.resolved: return 'Resolved';
      case ComplaintStatus.rejected: return 'Rejected';
    }
  }

  ComplaintModel copyWith({
    String? id,
    String? refNumber,
    String? title,
    String? description,
    ComplaintCategory? category,
    ComplaintStatus? status,
    String? location,
    DateTime? submittedAt,
    String? imageUrl,
    List<ComplaintStatusHistory>? statusHistory,
    double? latitude,
    double? longitude,
    String? priority,
    String? createdByUserId,
    String? createdByName,
  }) {
    return ComplaintModel(
      id: id ?? this.id,
      refNumber: refNumber ?? this.refNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      location: location ?? this.location,
      submittedAt: submittedAt ?? this.submittedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      statusHistory: statusHistory ?? this.statusHistory,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      priority: priority ?? this.priority,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  @override
  List<Object?> get props => [
        id, refNumber, title, description, category, status,
        location, submittedAt, imageUrl, statusHistory, latitude, longitude, priority,
        createdByUserId, createdByName,
      ];
}
