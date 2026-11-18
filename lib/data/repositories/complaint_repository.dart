import '../../core/api/api_client.dart';
import '../../core/api/api_config.dart';
import '../models/complaint_model.dart';

/// Incident/Complaint repository integrating real API GET /incidents and POST /incidents.
class ComplaintRepository {
  final ApiClient _apiClient;
  final List<ComplaintModel> _localCache = [];

  ComplaintRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Fetches reports submitted specifically by the authenticated user.
  /// Never displays other users' reports.
  Future<List<ComplaintModel>> getMyReports({
    required String userId,
    ComplaintStatus? status,
    String? searchQuery,
    int page = 1,
    int limit = 50,
  }) async {
    final cleanUserId = userId.trim();

    // 1. Send the logged-in user's identity parameters to the backend API request
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'created_by_user_id': cleanUserId,
      'userId': cleanUserId,
    };
    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    try {
      final response = await _apiClient.get(
        ApiConfig.incidents,
        queryParameters: queryParams,
      );

      List<dynamic> items = [];
      if (response is List) {
        items = response;
      } else if (response is Map<String, dynamic>) {
        final data = response['data'];
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic> && data['incidents'] is List) {
          items = data['incidents'] as List;
        } else if (response['incidents'] is List) {
          items = response['incidents'] as List;
        } else if (response['items'] is List) {
          items = response['items'] as List;
        }
      }

      final apiComplaints = items
          .whereType<Map<String, dynamic>>()
          .map((json) => ComplaintModel.fromJson(json))
          .toList();

      // Merge into local cache
      for (final inc in apiComplaints) {
        final idx = _localCache.indexWhere(
          (c) => c.id == inc.id || (inc.refNumber != null && c.refNumber == inc.refNumber),
        );
        if (idx != -1) {
          _localCache[idx] = inc;
        } else {
          _localCache.add(inc);
        }
      }
    } catch (_) {
      // Allow viewing cached submitted complaints if network drops temporarily
    }

    // 2. Strict user isolation: filter reports to only those created by the logged-in user.
    // Never show other citizens' or administrative reports.
    var userReports = _localCache.where((c) {
      final creator = c.createdByUserId?.trim();
      if (creator == null || creator.isEmpty) return false;
      return creator == cleanUserId;
    }).toList();

    if (status != null) {
      userReports = userReports.where((c) => c.status == status).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      userReports = userReports
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q) ||
              (c.refNumber != null && c.refNumber!.toLowerCase().contains(q)))
          .toList();
    }

    // Sort newest first
    userReports.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    return userReports;
  }

  /// Fetches incidents with filters and pagination from GET /incidents
  Future<List<ComplaintModel>> getComplaints({
    ComplaintStatus? status,
    ComplaintCategory? category,
    String? searchQuery,
    String? departmentId,
    String? priority,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) {
      queryParams['status'] = status.name;
    }
    if (category != null) {
      queryParams['category'] = category.name;
    }
    if (departmentId != null && departmentId.isNotEmpty) {
      queryParams['departmentId'] = departmentId;
    }
    if (priority != null && priority.isNotEmpty) {
      queryParams['priority'] = priority;
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      queryParams['search'] = searchQuery;
    }

    final response = await _apiClient.get(
      ApiConfig.incidents,
      queryParameters: queryParams,
    );

    List<dynamic> items = [];
    if (response is List) {
      items = response;
    } else if (response is Map<String, dynamic>) {
      final data = response['data'];
      if (data is List) {
        items = data;
      } else if (data is Map<String, dynamic> && data['incidents'] is List) {
        items = data['incidents'] as List;
      } else if (response['incidents'] is List) {
        items = response['incidents'] as List;
      } else if (response['items'] is List) {
        items = response['items'] as List;
      }
    }

    final apiComplaints = items
        .whereType<Map<String, dynamic>>()
        .map((json) => ComplaintModel.fromJson(json))
        .toList();

    _localCache.clear();
    _localCache.addAll(apiComplaints);

    var result = List<ComplaintModel>.from(_localCache);
    if (status != null) {
      result = result.where((c) => c.status == status).toList();
    }
    if (category != null) {
      result = result.where((c) => c.category == category).toList();
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((c) =>
              c.title.toLowerCase().contains(q) ||
              c.location.toLowerCase().contains(q) ||
              c.description.toLowerCase().contains(q))
          .toList();
    }
    return result;
  }

  /// Fetches a single complaint by ID or reference number from API or cache.
  Future<ComplaintModel?> getComplaintById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.incidents}/$id');
      if (response is Map<String, dynamic>) {
        final data = response['data'] is Map<String, dynamic>
            ? response['data'] as Map<String, dynamic>
            : response;
        final incData = data['incident'] is Map<String, dynamic>
            ? data['incident'] as Map<String, dynamic>
            : data;
        return ComplaintModel.fromJson(incData);
      }
    } catch (_) {}

    try {
      return _localCache.firstWhere((c) => c.id == id || c.refNumber == id);
    } catch (_) {
      return null;
    }
  }

  /// Submits a new incident via real API POST /incidents with validation.
  Future<ComplaintModel> submitComplaint({
    required String title,
    required String description,
    required ComplaintCategory category,
    required String location,
    double? latitude,
    double? longitude,
    String? imageUrl,
    String? userId,
    String? userName,
  }) async {
    // Validation
    if (title.trim().isEmpty) throw Exception('Title cannot be empty');
    if (description.trim().isEmpty) throw Exception('Description cannot be empty');
    if (location.trim().isEmpty) throw Exception('Location cannot be empty');

    final payload = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'category': category.name,
      'location': location.trim(),
      'status': 'submitted',
      'priority': 'normal',
    };
    if (latitude != null) {
      payload['latitude'] = latitude;
      payload['lat'] = latitude.toString();
    }
    if (longitude != null) {
      payload['longitude'] = longitude;
      payload['lng'] = longitude.toString();
    }
    if (imageUrl != null) payload['imageUrl'] = imageUrl;
    if (userId != null && userId.isNotEmpty) {
      payload['userId'] = userId;
      payload['created_by_user_id'] = userId;
    }

    final response = await _apiClient.post(
      ApiConfig.incidents,
      body: payload,
    );

    int? newId;
    String? newRef;

    if (response is Map<String, dynamic>) {
      final dataObj = response['data'] is Map<String, dynamic>
          ? response['data'] as Map<String, dynamic>
          : response;
      newId = int.tryParse((dataObj['id'] ?? '').toString());
      newRef = dataObj['refNumber']?.toString() ?? dataObj['ref_number']?.toString();
    }

    ComplaintModel created;

    // After successful POST, fetch the official registered incident from GET /incidents/:id
    if (newId != null) {
      try {
        final fetched = await getComplaintById(newId.toString());
        if (fetched != null) {
          created = fetched.copyWith(
            createdByUserId: userId ?? fetched.createdByUserId,
            createdByName: userName ?? fetched.createdByName,
          );
          _localCache.removeWhere((c) => c.id == created.id || c.refNumber == created.refNumber);
          _localCache.insert(0, created);
          return created;
        }
      } catch (_) {}
    }

    // Synthesize created model with official registration number
    created = ComplaintModel(
      id: newRef ?? (newId != null ? newId.toString() : 'INC-${DateTime.now().millisecondsSinceEpoch}'),
      refNumber: newRef,
      title: title.trim(),
      description: description.trim(),
      category: category,
      status: ComplaintStatus.submitted,
      location: location.trim(),
      submittedAt: DateTime.now(),
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      createdByUserId: userId,
      createdByName: userName,
      statusHistory: [
        ComplaintStatusHistory(
          status: ComplaintStatus.submitted,
          timestamp: DateTime.now(),
          note: 'Grievance registered and queued for municipal resolution.',
        ),
      ],
    );

    _localCache.removeWhere((c) => c.id == created.id || (created.refNumber != null && c.refNumber == created.refNumber));
    _localCache.insert(0, created);
    return created;
  }

  /// Returns recent complaints submitted by the authenticated user for the home dashboard.
  Future<List<ComplaintModel>> getRecentComplaints({required String userId, int limit = 3}) async {
    final all = await getMyReports(userId: userId, limit: limit);
    return all.take(limit).toList();
  }
}
