import 'dart:io';
import 'dart:math' as math;

import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Haversine distance (haversineMeters)', () {
    test('same point returns exactly 0.0', () {
      expect(
        haversineMeters(const GeoPoint(0.0, 0.0), const GeoPoint(0.0, 0.0)),
        equals(0.0),
      );
      expect(
        haversineMeters(
          const GeoPoint(30.0444, 31.2357),
          const GeoPoint(30.0444, 31.2357),
        ),
        equals(0.0),
      );
      expect(
        haversineMeters(
          const GeoPoint(-33.8688, 151.2093),
          const GeoPoint(-33.8688, 151.2093),
        ),
        equals(0.0),
      );
    });

    test('known value: 0.001° latitude is ~111.2 m (within ±0.5 m)', () {
      final distanceEquator = haversineMeters(
        const GeoPoint(0.0, 0.0),
        const GeoPoint(0.001, 0.0),
      );
      expect(distanceEquator, closeTo(111.2, 0.5));

      final distanceMeridian = haversineMeters(
        const GeoPoint(51.500, 10.0),
        const GeoPoint(51.501, 10.0),
      );
      expect(distanceMeridian, closeTo(111.2, 0.5));
    });

    test('antimeridian crossing calculates shortest great-circle path', () {
      // 0.002° total difference across the 180° meridian at equator
      final distanceAcrossAntimeridian = haversineMeters(
        const GeoPoint(0.0, 179.999),
        const GeoPoint(0.0, -179.999),
      );
      expect(distanceAcrossAntimeridian, closeTo(222.39, 0.5));

      // At 60° latitude, cos(60°) = 0.5, so 0.002° delta is ~111.2 m
      final distanceAt60Lat = haversineMeters(
        const GeoPoint(60.0, 179.999),
        const GeoPoint(60.0, -179.999),
      );
      expect(distanceAt60Lat, closeTo(111.2, 0.5));

      // 180° and -180° are identical meridians
      final sameMeridianDistance = haversineMeters(
        const GeoPoint(25.0, 180.0),
        const GeoPoint(25.0, -180.0),
      );
      expect(sameMeridianDistance, closeTo(0.0, 1e-6));
    });

    test('is symmetric: dist(a, b) == dist(b, a)', () {
      const p1 = GeoPoint(40.7128, -74.0060);
      const p2 = GeoPoint(34.0522, -118.2437);

      final d1 = haversineMeters(p1, p2);
      final d2 = haversineMeters(p2, p1);
      expect(d1, closeTo(d2, 1e-9));
    });

    test('antipodal points return half Earth circumference', () {
      // North pole to South pole
      final poleToPole = haversineMeters(
        const GeoPoint(90.0, 0.0),
        const GeoPoint(-90.0, 0.0),
      );
      final expected = math.pi * earthRadiusMeters;
      expect(poleToPole, closeTo(expected, 1.0));
    });
  });

  group('Pure Dart domain constraints', () {
    test('lib/domain/geo/haversine.dart contains no Flutter imports', () {
      final file = File('lib/domain/geo/haversine.dart');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content.contains('package:flutter'), isFalse);
    });
  });
}
