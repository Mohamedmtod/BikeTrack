import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('ActivityType contains all expected values', () {
      expect(
        ActivityType.values.map((e) => e.name).toList(),
        equals([
          'stationary',
          'walking',
          'running',
          'cycling',
          'automotive',
          'unknown',
        ]),
      );
    });
  });
}
