import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/hospital_model.dart';

/// Healthcare repository integrating real API GET /healthcare/facilities.
class HospitalRepository {
  final ApiClient _apiClient;
  List<HospitalModel> _cachedFacilities = [];

  List<HospitalModel> get cachedFacilities => _cachedFacilities;

  HospitalRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches facilities, bed capacity, and occupancy from GET /healthcare/facilities
  Future<List<HospitalModel>> getAllHospitals() async {
    final response = await _apiClient.get(ApiConfig.healthcareFacilities);
    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['facilities'] is List) {
        items = data['facilities'] as List;
      } else if (data is Map<String, dynamic> && data['hospitals'] is List) {
        items = data['hospitals'] as List;
      } else if (response['facilities'] is List) {
        items = response['facilities'] as List;
      } else if (response['hospitals'] is List) {
        items = response['hospitals'] as List;
      }
    }

    final facilities = items
        .whereType<Map<String, dynamic>>()
        .map((e) => HospitalModel.fromJson(e))
        .toList();
    _cachedFacilities = facilities;
    return facilities;
  }

  /// Returns hospitals within a given distance (km).
  Future<List<HospitalModel>> getNearbyHospitals({double maxDistanceKm = 10.0}) async {
    final list = await getAllHospitals();
    return list
        .where((h) => h.distanceKm <= maxDistanceKm)
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }

  /// Returns all medical camps and first-aid posts from live API facilities.
  Future<List<HospitalModel>> getMedicalCamps() async {
    final list = await getAllHospitals();
    return list.where((h) => h.type == HospitalType.medicalCamp || h.type == HospitalType.firstAid).toList();
  }

  /// Searches hospitals by name or specialty.
  Future<List<HospitalModel>> searchHospitals(String query) async {
    final list = await getAllHospitals();
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((h) {
      return h.name.toLowerCase().contains(q) ||
          h.address.toLowerCase().contains(q) ||
          h.specialties.any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  /// Returns closest hospitals for the home dashboard.
  Future<List<HospitalModel>> getHomeHospitals() async {
    final list = await getAllHospitals();
    return list.take(3).toList();
  }
}
