import 'package:equatable/equatable.dart';

enum NotificationType { emergency, traffic, announcement, complaintUpdate, health }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime receivedAt;
  final bool isRead;
  final String? severity;
  final String? area;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.receivedAt,
    this.isRead = false,
    this.severity,
    this.area,
  });

  static NotificationType parseType(dynamic val) {
    if (val == null) return NotificationType.announcement;
    final s = val.toString().toLowerCase();
    if (s.contains('emerg') || s.contains('critical') || s.contains('flood')) return NotificationType.emergency;
    if (s.contains('traffic') || s.contains('road') || s.contains('congestion')) return NotificationType.traffic;
    if (s.contains('health') || s.contains('camp') || s.contains('hospital')) return NotificationType.health;
    if (s.contains('complaint') || s.contains('grievance') || s.contains('incident')) return NotificationType.complaintUpdate;
    return NotificationType.announcement;
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'ALT-${DateTime.now().millisecondsSinceEpoch}',
      title: json['title']?.toString() ?? json['heading']?.toString() ?? 'Operational Alert',
      message: json['message']?.toString() ?? json['description']?.toString() ?? '',
      type: parseType(json['type'] ?? json['category'] ?? json['severity']),
      receivedAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : (json['receivedAt'] != null
              ? (DateTime.tryParse(json['receivedAt'].toString()) ?? DateTime.now())
              : (json['issuedAt'] != null
                  ? (DateTime.tryParse(json['issuedAt'].toString()) ?? DateTime.now())
                  : (json['createdAt'] != null
                      ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
                      : DateTime.now()))),
      isRead: json['isRead'] == true || json['isRead'] == 'true',
      severity: json['severity']?.toString() ?? 'Normal',
      area: json['area']?.toString() ?? 'Nashik',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
        'severity': severity,
        'area': area,
      };

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? receivedAt,
    bool? isRead,
    String? severity,
    String? area,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      severity: severity ?? this.severity,
      area: area ?? this.area,
    );
  }

  String get typeLabel {
    switch (type) {
      case NotificationType.emergency: return 'Emergency';
      case NotificationType.traffic: return 'Traffic';
      case NotificationType.announcement: return 'Announcement';
      case NotificationType.complaintUpdate: return 'Incident Update';
      case NotificationType.health: return 'Health';
    }
  }

  @override
  List<Object?> get props => [id, title, type, receivedAt, isRead];
}
