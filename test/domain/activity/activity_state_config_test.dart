import 'package:biketrack/domain/activity/activity_state_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityStateConfig', () {
    test('12 a hysteresis value of 0 throws AssertionError; default does not throw', () {
      expect(
        () => ActivityStateConfig(cyclingMs: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(() => const ActivityStateConfig(), returnsNormally);
    });
  });
}
