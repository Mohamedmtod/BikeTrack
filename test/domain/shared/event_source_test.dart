import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('EventSource contains all expected values', () {
      expect(
        EventSource.values.map((e) => e.name).toList(),
        equals([
          'motion',
          'pedometer',
          'gps',
          'nfc',
          'user',
          'system',
          'health',
        ]),
      );
    });
  });
}
