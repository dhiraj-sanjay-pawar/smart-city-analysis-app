import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_city_app/core/api/api_client.dart';
import 'package:smart_city_app/data/models/complaint_model.dart';
import 'package:smart_city_app/data/repositories/complaint_repository.dart';

void main() {
  group('My Reports User-Specific Isolation & Submission Tests', () {
    test('getMyReports strictly isolates reports by authenticated user ID', () async {
      // Mock HTTP client returning a mix of complaints from different users (like the live backend does)
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/incidents')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'incidents': [
                  {
                    'id': 101,
                    'ref_number': 'INC-2026-USER-A-1',
                    'title': 'User A Complaint 1',
                    'description': 'Pothole on Street 1',
                    'category': 'road',
                    'status': 'Reported',
                    'created_by_user_id': 13,
                    'created_by_name': 'User A',
                  },
                  {
                    'id': 102,
                    'ref_number': 'INC-2026-USER-B-1',
                    'title': 'User B Complaint 1',
                    'description': 'Garbage issue on Street 2',
                    'category': 'sanitation',
                    'status': 'Assigned',
                    'created_by_user_id': 42,
                    'created_by_name': 'User B',
                  },
                  {
                    'id': 103,
                    'ref_number': 'INC-2026-ADMIN-1',
                    'title': 'Admin Action on Street 3',
                    'description': 'Municipal drainage dispatch',
                    'category': 'water',
                    'status': 'In Progress',
                    'created_by_user_id': 1,
                    'created_by_name': 'Admin User',
                  },
                  {
                    'id': 104,
                    'ref_number': 'INC-2026-USER-A-2',
                    'title': 'User A Complaint 2',
                    'description': 'Streetlight broken',
                    'category': 'electricity',
                    'status': 'Resolved',
                    'created_by_user_id': 13,
                    'created_by_name': 'User A',
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = ComplaintRepository(apiClient: apiClient);

      // 1. Fetch My Reports for User A (ID: 13)
      final userAReports = await repo.getMyReports(userId: '13');

      // Verify User A only sees their 2 complaints
      expect(userAReports.length, 2);
      expect(userAReports.map((c) => c.refNumber).toList(), containsAll(['INC-2026-USER-A-1', 'INC-2026-USER-A-2']));
      expect(userAReports.every((c) => c.createdByUserId == '13'), isTrue);

      // Verify User A NEVER sees User B or Admin complaints
      expect(userAReports.any((c) => c.refNumber == 'INC-2026-USER-B-1'), isFalse);
      expect(userAReports.any((c) => c.refNumber == 'INC-2026-ADMIN-1'), isFalse);

      // 2. Fetch My Reports for User B (ID: 42)
      final userBReports = await repo.getMyReports(userId: '42');

      // Verify User B only sees their 1 complaint
      expect(userBReports.length, 1);
      expect(userBReports.first.refNumber, 'INC-2026-USER-B-1');
      expect(userBReports.first.createdByUserId, '42');

      // Verify User B NEVER sees User A complaints
      expect(userBReports.any((c) => c.refNumber == 'INC-2026-USER-A-1'), isFalse);
    });

    test('submitComplaint registers new report and appears in getMyReports', () async {
      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/incidents')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Incident successfully registered.',
              'data': {
                'id': 200,
                'refNumber': 'INC-2026-9999',
              },
            }),
            201,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path.contains('/incidents/200')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'incident': {
                  'id': 200,
                  'ref_number': 'INC-2026-9999',
                  'title': 'Leaking Water Pipe',
                  'description': 'Continuous water leakage on sidewalk',
                  'category': 'water',
                  'status': 'Reported',
                  'location_name': 'Gangapur Road, Nashik',
                  'created_by_user_id': 13,
                  'created_by_name': 'User A',
                  'created_at': '2026-10-27 10:00:00',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = ComplaintRepository(apiClient: apiClient);

      // Submit new complaint for User A
      final submitted = await repo.submitComplaint(
        title: 'Leaking Water Pipe',
        description: 'Continuous water leakage on sidewalk',
        category: ComplaintCategory.water,
        location: 'Gangapur Road, Nashik',
        userId: '13',
        userName: 'User A',
      );

      expect(submitted.refNumber, 'INC-2026-9999');
      expect(submitted.status, ComplaintStatus.submitted);
      expect(submitted.createdByUserId, '13');

      // Verify it appears in User A's reports
      final myReports = await repo.getMyReports(userId: '13');
      expect(myReports.length, 1);
      expect(myReports.first.refNumber, 'INC-2026-9999');

      // Verify it DOES NOT appear in User B's reports
      final userBReports = await repo.getMyReports(userId: '99');
      expect(userBReports.isEmpty, isTrue);
    });

    test('Healthcare issue reporting sends correct category and appears in My Reports', () async {
      String? sentCategory;
      String? sentPhotoPath;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.contains('/incidents')) {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentCategory = body['category']?.toString();
          sentPhotoPath = body['imageUrl']?.toString();

          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Healthcare grievance logged.',
              'data': {
                'id': 55,
                'refNumber': 'INC-2026-HEALTH-01',
                'incident': {
                  'id': 55,
                  'ref_number': 'INC-2026-HEALTH-01',
                  'title': 'Emergency Clinic Shortage',
                  'description': 'Medical supplies shortage at primary health clinic',
                  'category': 'healthcare',
                  'status': 'Reported',
                  'location_name': 'Nashik Civil Hospital',
                  'created_by_user_id': 13,
                  'created_by_name': 'Citizen User',
                  'created_at': '2026-10-29 10:00:00',
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Not found', 404);
      });

      final apiClient = ApiClient(httpClient: mockClient);
      final repo = ComplaintRepository(apiClient: apiClient);

      final submitted = await repo.submitComplaint(
        title: 'Emergency Clinic Shortage',
        description: 'Medical supplies shortage at primary health clinic',
        category: ComplaintCategory.healthcare,
        location: 'Nashik Civil Hospital',
        latitude: 19.9975,
        longitude: 73.7898,
        imageUrl: '/photos/clinic.jpg',
        userId: '13',
        userName: 'Citizen User',
      );

      expect(sentCategory, 'healthcare');
      expect(sentPhotoPath, '/photos/clinic.jpg');
      expect(submitted.refNumber, 'INC-2026-HEALTH-01');
      expect(submitted.category, ComplaintCategory.healthcare);
      expect(submitted.categoryLabel, 'Healthcare');

      // Verify it appears in user's reports
      final myReports = await repo.getMyReports(userId: '13');
      expect(myReports.length, 1);
      expect(myReports.first.category, ComplaintCategory.healthcare);
      expect(myReports.first.categoryLabel, 'Healthcare');
    });

    test('ComplaintCategory parses healthcare variations correctly', () {
      expect(ComplaintModel.parseCategory('healthcare'), ComplaintCategory.healthcare);
      expect(ComplaintModel.parseCategory('Public Health Clinic'), ComplaintCategory.healthcare);
      expect(ComplaintModel.parseCategory('hospital ward'), ComplaintCategory.healthcare);
      expect(ComplaintModel.parseCategory('medical aid post'), ComplaintCategory.healthcare);
    });
  });
}
