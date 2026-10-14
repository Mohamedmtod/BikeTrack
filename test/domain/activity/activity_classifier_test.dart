import 'dart:math' as math;

import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActivityClassifier (§7.6, D-022)', () {
    test('1 clear cycling: cm={cycling}, high, cadence 0, speed 5 -> cycling, score 1.0', () {
      const w = ActivityWindow(
        cmTypes: {ActivityType.cycling},
        cmConfidence: Confidence.high,
        cadenceSps: 0.0,
        speedMps: 5.0,
      );
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.cycling);
      expect(r.scores[ActivityType.cycling], closeTo(1.0, 1e-9));
    });

    test('2 clear walking: cm={walking}, high, cadence 1.8, speed 1.4 -> walking, score 1.0', () {
      const w = ActivityWindow(
        cmTypes: {ActivityType.walking},
        cmConfidence: Confidence.high,
        cadenceSps: 1.8,
        speedMps: 1.4,
      );
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.walking);
      expect(r.scores[ActivityType.walking], closeTo(1.0, 1e-9));
    });

    test('3 stationary: cm={stationary}, high, speed 0.2, cadence null -> stationary, score 0.85', () {
      const w = ActivityWindow(
        cmTypes: {ActivityType.stationary},
        cmConfidence: Confidence.high,
        speedMps: 0.2,
      );
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.stationary);
      expect(r.scores[ActivityType.stationary], closeTo(0.85, 1e-9));
    });

    test('4 speed alone is not enough: cm={}, conf null, cadence null, speed 8.5 -> unknown; cycling score 0.30, automotive 0.30', () {
      const w = ActivityWindow(speedMps: 8.5);
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.unknown);
      expect(r.scores[ActivityType.cycling], closeTo(0.30, 1e-9));
      expect(r.scores[ActivityType.automotive], closeTo(0.30, 1e-9));
    });

    test('5 no data at all: cm={}, all null -> unknown, all scores 0', () {
      const w = ActivityWindow();
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.unknown);
      for (final s in r.scores.values) {
        expect(s, closeTo(0.0, 1e-9));
      }
    });

    test('6 weak evidence: cm={walking}, low, others null -> unknown, walking score 0.165', () {
      const w = ActivityWindow(
        cmTypes: {ActivityType.walking},
        cmConfidence: Confidence.low,
      );
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.unknown);
      expect(r.scores[ActivityType.walking], closeTo(0.165, 1e-9));
    });

    test('7 low-confidence cycling with speed: cm={cycling}, low, speed 5, cadence null -> cycling, score 0.465', () {
      const w = ActivityWindow(
        cmTypes: {ActivityType.cycling},
        cmConfidence: Confidence.low,
        speedMps: 5.0,
      );
      final r = ActivityClassifier.classify(w);
      expect(r.type, ActivityType.cycling);
      expect(r.scores[ActivityType.cycling], closeTo(0.465, 1e-9));
    });

    test('8 missing cadence adds no bias: cm={}, speed 5, cadence null -> cycling score exactly 0.30 and walking 0', () {
      const w = ActivityWindow(speedMps: 5.0);
      final r = ActivityClassifier.classify(w);
      expect(r.scores[ActivityType.cycling], closeTo(0.30, 1e-9));
      expect(r.scores[ActivityType.walking], closeTo(0.0, 1e-9));
    });

    test('10 property: for 200 deterministic pseudo-random windows (seeded Random(42)), every score is in [0, 1]', () {
      final rng = math.Random(42);
      for (var i = 0; i < 200; i++) {
        final cmTypes = <ActivityType>{};
        if (rng.nextBool()) cmTypes.add(ActivityType.cycling);
        if (rng.nextBool()) cmTypes.add(ActivityType.walking);
        if (rng.nextBool()) cmTypes.add(ActivityType.automotive);
        if (rng.nextBool()) cmTypes.add(ActivityType.stationary);

        final cmConfidence = rng.nextBool()
            ? Confidence.values[rng.nextInt(Confidence.values.length)]
            : null;

        final cadenceSps = rng.nextBool() ? rng.nextDouble() * 4.0 : null;
        final speedMps = rng.nextBool() ? rng.nextDouble() * 50.0 : null;
        final stopPatternScore = rng.nextBool() ? rng.nextDouble() : null;

        final w = ActivityWindow(
          cmTypes: cmTypes,
          cmConfidence: cmConfidence,
          cadenceSps: cadenceSps,
          speedMps: speedMps,
          stopPatternScore: stopPatternScore,
        );
        final r = ActivityClassifier.classify(w);
        for (final score in r.scores.values) {
          expect(score, greaterThanOrEqualTo(0.0));
          expect(score, lessThanOrEqualTo(1.0 + 1e-9));
        }
      }
    });
  });
}
