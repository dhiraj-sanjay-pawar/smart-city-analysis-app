import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String name;
  final String mobile;
  final String email;
  final String? avatarUrl;
  final String city;
  final String ward;
  final DateTime joinedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.email,
    this.avatarUrl,
    required this.city,
    required this.ward,
    required this.joinedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['id'] ?? json['_id'] ?? 'usr_${DateTime.now().millisecondsSinceEpoch}').toString(),
      name: (json['fullName'] ?? json['name'] ?? 'Citizen User').toString(),
      mobile: (json['phone'] ?? json['mobileNumber'] ?? json['mobile'] ?? '').toString(),
      email: (json['email'] ?? json['emailAddress'] ?? '').toString(),
      avatarUrl: json['avatarUrl']?.toString() ?? json['avatar']?.toString(),
      city: json['city']?.toString() ?? 'Nashik',
      ward: json['ward']?.toString() ?? 'Kumbh Mela Central Zone',
      joinedAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'email': email,
        'avatarUrl': avatarUrl,
        'city': city,
        'ward': ward,
        'joinedAt': joinedAt.toIso8601String(),
      };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, 2).toUpperCase();
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? mobile,
    String? email,
    String? avatarUrl,
    String? city,
    String? ward,
    DateTime? joinedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      city: city ?? this.city,
      ward: ward ?? this.ward,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, mobile, email, avatarUrl, city, ward, joinedAt];
}
