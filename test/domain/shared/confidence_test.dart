import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('Confidence contains all expected values', () {
      expect(
        Confidence.values.map((e) => e.name).toList(),
        equals(['low', 'medium', 'high']),
      );
    });
  });
}
