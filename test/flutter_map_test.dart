import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

void main() {
  test('flutter_map 7.x and latlong2 smoke test', () {
    const point = LatLng(19.9931, 73.7869);
    expect(point.latitude, 19.9931);
    expect(point.longitude, 73.7869);

    final marker = Marker(
      point: point,
      width: 40,
      height: 40,
      child: const Icon(Icons.location_on),
    );
    expect(marker.point.latitude, 19.9931);
  });
}
