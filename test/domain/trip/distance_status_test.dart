import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('DistanceStatus contains all expected values (D-011)', () {
      expect(
        DistanceStatus.values.map((e) => e.name).toList(),
        equals(['measured', 'partial', 'unknown']),
      );
    });
  });
}
