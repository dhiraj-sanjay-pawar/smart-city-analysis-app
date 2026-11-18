import 'package:flutter_test/flutter_test.dart';
import 'package:smart_city_app/data/models/map_marker_model.dart';

void main() {
  group('Map Features & Coordinate Parsing Tests', () {
    test('parseCoordinate handles numbers, strings, null, and invalid inputs safely', () {
      expect(MapMarker.parseCoordinate(19.9931), 19.9931);
      expect(MapMarker.parseCoordinate('19.9931000'), 19.9931);
      expect(MapMarker.parseCoordinate('73.7869000'), 73.7869);
      expect(MapMarker.parseCoordinate(null), isNull);
      expect(MapMarker.parseCoordinate(''), isNull);
      expect(MapMarker.parseCoordinate('   '), isNull);
      expect(MapMarker.parseCoordinate('invalid_coord'), isNull);
      expect(MapMarker.parseCoordinate(double.nan), isNull);
      expect(MapMarker.parseCoordinate(double.infinity), isNull);
    });

    test('Parses exact user API response successfully into layers and center', () {
      final sampleApiResponse = {
        "success": true,
        "message": "Map features loaded.",
        "data": {
          "center": {
            "lat": 19.9931,
            "lng": 73.7869,
            "defaultZoom": 15,
            "hasPoints": true,
            "pointCount": 1
          },
          "layers": {
            "incidents": [
              {
                "id": 11,
                "ref_number": "INC-2026-7917",
                "category": "water",
                "title": "water supply",
                "description": "water supply",
                "location_name": "Live GPS (20.0143° N, 73.8118° E) • Nashik, MH",
                "lat": "19.9931000",
                "lng": "73.7869000",
                "priority": "Medium",
                "status": "Reported",
                "department_name": "Municipal & Sanitation Services"
              }
            ],
            "facilities": [],
            "ambulances": [],
            "wastewaterPoints": [
              {
                "id": 1,
                "point_code": "WW-PT-01",
                "name": "Mori Gate Main Pumping Station",
                "type": "Pumping Station",
                "lat": "25.4300000",
                "lng": "81.8800000",
                "risk_level": "Critical",
                "last_water_level": "3.85",
                "last_status_level": "Critical"
              }
            ]
          }
        }
      };

      final mapData = MapFeaturesData.fromJson(sampleApiResponse);

      // Verify Center
      expect(mapData.center.lat, 19.9931);
      expect(mapData.center.lng, 73.7869);
      expect(mapData.center.defaultZoom, 15.0);
      expect(mapData.center.hasPoints, true);
      expect(mapData.center.pointCount, 1);

      // Verify Incidents Layer
      expect(mapData.incidents.length, 1);
      final incident = mapData.incidents.first;
      expect(incident.id, '11');
      expect(incident.refNumber, 'INC-2026-7917');
      expect(incident.category, 'water');
      expect(incident.title, 'water supply');
      expect(incident.description, 'water supply');
      expect(incident.locationName, 'Live GPS (20.0143° N, 73.8118° E) • Nashik, MH');
      expect(incident.lat, 19.9931);
      expect(incident.lng, 73.7869);
      expect(incident.priority, 'Medium');
      expect(incident.status, 'Reported');
      expect(incident.departmentName, 'Municipal & Sanitation Services');
      expect(incident.type, MapMarkerType.incident);

      // Verify Wastewater Points Layer
      expect(mapData.wastewaterPoints.length, 1);
      final ww = mapData.wastewaterPoints.first;
      expect(ww.id, '1');
      expect(ww.pointCode, 'WW-PT-01');
      expect(ww.title, 'Mori Gate Main Pumping Station');
      expect(ww.description, 'Pumping Station');
      expect(ww.lat, 25.43);
      expect(ww.lng, 81.88);
      expect(ww.riskLevel, 'Critical');
      expect(ww.lastWaterLevel, '3.85');
      expect(ww.lastStatusLevel, 'Critical');
      expect(ww.type, MapMarkerType.wastewater);

      // Empty layers are handled safely
      expect(mapData.facilities, isEmpty);
      expect(mapData.ambulances, isEmpty);
      expect(mapData.allMarkers.length, 2);
    });

    test('Discards markers with missing or invalid coordinates without crashing', () {
      final invalidData = {
        "center": {"lat": "invalid", "lng": null, "defaultZoom": 12},
        "layers": {
          "incidents": [
            {"id": 1, "title": "Missing Coords"},
            {"id": 2, "title": "Invalid Lat", "lat": "not_a_number", "lng": "73.5"},
            {"id": 3, "title": "Valid Incident", "lat": "20.01", "lng": "73.82"}
          ],
          "facilities": null,
          "ambulances": "not a list"
        }
      };

      final mapData = MapFeaturesData.fromJson(invalidData);
      expect(mapData.center.lat, 0.0);
      expect(mapData.center.lng, 0.0);
      expect(mapData.center.defaultZoom, 12.0);
      // Only the valid incident should be accepted
      expect(mapData.incidents.length, 1);
      expect(mapData.incidents.first.title, 'Valid Incident');
      expect(mapData.facilities, isEmpty);
      expect(mapData.ambulances, isEmpty);
    });

    test('matchesCategory and MapLoaded filter specific issue categories correctly', () {
      final sampleApiResponse = {
        "success": true,
        "data": {
          "center": {"lat": 19.9931, "lng": 73.7869, "defaultZoom": 15},
          "layers": {
            "incidents": [
              {
                "id": 11,
                "category": "water",
                "title": "Water supply burst",
                "lat": "19.9931",
                "lng": "73.7869",
              },
              {
                "id": 12,
                "category": "road",
                "title": "Pothole on Main Road",
                "lat": "19.9950",
                "lng": "73.7880",
              },
            ],
            "wastewaterPoints": [
              {
                "id": 1,
                "name": "Mori Gate Main Pumping Station",
                "type": "Pumping Station",
                "lat": "25.43",
                "lng": "81.88",
              }
            ],
          }
        }
      };

      final mapData = MapFeaturesData.fromJson(sampleApiResponse);
      expect(mapData.allMarkers.length, 3);

      final waterMarker = mapData.incidents.first;
      expect(waterMarker.matchesCategory('water'), true);
      expect(waterMarker.matchesCategory('road'), false);

      final roadMarker = mapData.incidents[1];
      expect(roadMarker.matchesCategory('road'), true);
      expect(roadMarker.matchesCategory('water'), false);
    });
  });
}
