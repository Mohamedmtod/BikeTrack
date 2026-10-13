import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('ClassificationSource contains all expected values', () {
      expect(
        ClassificationSource.values.map((e) => e.name).toList(),
        equals(['coreMotion', 'fused', 'nfc', 'user']),
      );
    });
  });
}
