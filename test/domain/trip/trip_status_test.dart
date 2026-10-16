import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('TripStatus contains all expected values', () {
      expect(
        TripStatus.values.map((e) => e.name).toList(),
        equals([
          'pending',
          'active',
          'paused',
          'suspectedForgotten',
          'needsReview',
          'completed',
          'cancelled',
        ]),
      );
    });
  });
}
