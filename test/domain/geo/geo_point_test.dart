import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GeoPoint', () {
    test('GeoPoint value equality and hashCode', () {
      const p1 = GeoPoint(10.0, 20.0);
      const p2 = GeoPoint(10.0, 20.0);
      const p3 = GeoPoint(10.0, 20.1);

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1.toString(), contains('GeoPoint'));
    });
  });
}
