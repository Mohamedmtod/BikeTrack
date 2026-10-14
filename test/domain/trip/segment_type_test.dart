import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('SegmentType contains all expected values', () {
      expect(
        SegmentType.values.map((e) => e.name).toList(),
        equals(['cycling', 'walking', 'automotive', 'unknown', 'gap']),
      );
    });
  });
}
