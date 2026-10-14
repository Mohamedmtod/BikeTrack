import 'package:biketrack/domain/activity/activity_classifier_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityClassifierConfig', () {
    test('ActivityClassifierConfig(w1: 0.8) throws AssertionError', () {
      expect(
        () => ActivityClassifierConfig(w1: 0.8),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ActivityClassifierConfig(w2: -0.1) throws AssertionError', () {
      expect(
        () => ActivityClassifierConfig(w2: -0.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('default const config does not throw', () {
      expect(() => const ActivityClassifierConfig(), returnsNormally);
    });
  });
}
