import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('RecordingState contains all expected values', () {
      expect(
        RecordingState.values.map((e) => e.name).toList(),
        equals(['off', 'lowPower', 'highAccuracy']),
      );
    });
  });
}
