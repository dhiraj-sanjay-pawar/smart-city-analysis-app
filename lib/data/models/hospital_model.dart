import 'package:equatable/equatable.dart';

enum HospitalType { government, private, clinic, medicalCamp, firstAid }

class HospitalModel extends Equatable {
  final String id;
  final String name;
  final String address;
  final HospitalType type;
  final String phone;
  final double distanceKm;
  final bool isOpen24Hours;
  final bool hasEmergency;
  final List<String> specialties;
  final double rating;
  final String? timings;
  final String? imageUrl;
  final int totalBeds;
  final int availableBeds;
  final int icuBeds;
  final double? occupancyRate;
  final String? operationalStatus;

  const HospitalModel({
    required this.id,
    required this.name,
    required this.address,
    required this.type,
    required this.phone,
    required this.distanceKm,
    required this.isOpen24Hours,
    required this.hasEmergency,
    required this.specialties,
    required this.rating,
    this.timings,
    this.imageUrl,
    this.totalBeds = 100,
    this.availableBeds = 25,
    this.icuBeds = 10,
    this.occupancyRate,
    this.operationalStatus,
  });

  static HospitalType parseType(dynamic val) {
    if (val == null) return HospitalType.government;
    final s = val.toString().toLowerCase();
    if (s.contains('private')) return HospitalType.private;
    if (s.contains('clinic')) return HospitalType.clinic;
    if (s.contains('camp')) return HospitalType.medicalCamp;
    if (s.contains('first') || s.contains('aid')) return HospitalType.firstAid;
    return HospitalType.government;
  }

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    double parseDbl(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    int parseInt(dynamic v, [int def = 0]) {
      if (v == null) return def;
      if (v is int) return v;
      return int.tryParse(v.toString()) ?? def;
    }

    List<String> specs = [];
    if (json['services_offered'] is List) {
      specs = (json['services_offered'] as List).map((e) => e.toString()).toList();
    } else if (json['services_offered'] is String && (json['services_offered'] as String).isNotEmpty) {
      specs = (json['services_offered'] as String).split(',').map((e) => e.trim()).toList();
    } else if (json['specialties'] is List) {
      specs = (json['specialties'] as List).map((e) => e.toString()).toList();
    } else if (json['facilities'] is List) {
      specs = (json['facilities'] as List).map((e) => e.toString()).toList();
    } else {
      specs = ['General Medicine', 'Emergency Care'];
    }

    final total = parseInt(json['totalBeds'] ?? json['bedCapacity'] ?? json['total_beds'], 80);
    final avail = parseInt(json['availableBeds'] ?? json['bedsAvailable'] ?? json['available_beds'], 20);
    final double calcOccupancy = total > 0 ? ((total - avail) / total * 100) : 75.0;

    return HospitalModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? 'HOSP-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? json['facilityName']?.toString() ?? 'Nashik Health Facility',
      address: json['address']?.toString() ?? json['location']?.toString() ?? 'Nashik, Maharashtra',
      type: parseType(json['type'] ?? json['facilityType']),
      phone: json['contact_number']?.toString() ?? json['phone']?.toString() ?? json['contact']?.toString() ?? '+91 253 257 2000',
      distanceKm: parseDbl(json['distanceKm'] ?? json['distance'], 1.2),
      isOpen24Hours: json['isOpen24Hours'] == true || json['isOpen24Hours'] == 'true' || json['is24x7'] == true,
      hasEmergency: json['hasEmergency'] == true || json['hasEmergency'] == 'true' || json['emergencyAvailable'] == true,
      specialties: specs,
      rating: parseDbl(json['rating'], 4.5),
      timings: json['timings']?.toString() ?? (json['isOpen24Hours'] == true ? '24 Hours Open' : '8:00 AM - 9:00 PM'),
      imageUrl: json['imageUrl']?.toString() ?? json['image']?.toString(),
      totalBeds: total,
      availableBeds: avail,
      icuBeds: parseInt(json['icuBeds'] ?? json['icu_beds'], 12),
      occupancyRate: json['occupancyRate'] != null ? parseDbl(json['occupancyRate']) : calcOccupancy,
      operationalStatus: json['operational_status']?.toString() ?? 'Operational',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'type': type.name,
        'phone': phone,
        'distanceKm': distanceKm,
        'isOpen24Hours': isOpen24Hours,
        'hasEmergency': hasEmergency,
        'specialties': specialties,
        'rating': rating,
        'timings': timings,
        'imageUrl': imageUrl,
        'totalBeds': totalBeds,
        'availableBeds': availableBeds,
        'icuBeds': icuBeds,
        'occupancyRate': occupancyRate,
      };

  String get typeLabel {
    switch (type) {
      case HospitalType.government: return 'Government';
      case HospitalType.private: return 'Private';
      case HospitalType.clinic: return 'Clinic';
      case HospitalType.medicalCamp: return 'Medical Camp';
      case HospitalType.firstAid: return 'First Aid';
    }
  }

  @override
  List<Object?> get props => [id, name, type, distanceKm, totalBeds, availableBeds];
}
