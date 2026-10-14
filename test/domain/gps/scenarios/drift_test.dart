import 'dart:math';

import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/gps_helpers.dart';

const _origin = origin;
const _cfg = defaultCfg;
const _offset = offset;
const _sample = sample;

void main() {
  group('Stationary drift — 30 min, 1 pt/s, isStationary=true → total = 0', () {
    test('total distance = 0 regardless of noise', () {
      final rng = Random(42); // seeded for determinism
      var state = const FilterState();
      var total = 0.0;

      for (var i = 0; i < 30 * 60; i++) {
        final northNoise = (rng.nextDouble() - 0.5) * 2 * 10; // ±10 m
        final eastNoise = (rng.nextDouble() - 0.5) * 2 * 10;
        final p = _sample(
          tsMs: i * 1000,
          position: _offset(_origin, northNoise, eastNoise),
          hAccuracyM: 5.0,
        );
        final r = GpsFilter.step(
          state,
          p,
          nowMs: i * 1000,
          isStationary: true,
          cfg: _cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }
      expect(total, 0.0);
    });
  });

  group(
    'Stationary drift — isStationary=false, noise ≤ 8 m, acc 10 m → total = 0',
    () {
      test('jitter filter keeps phantom distance at 0', () {
        // Noise of ±4 m on a single axis:
        //   • jitter threshold = max(3, 0.5*(10+10)) = 10 m; max displacement = 4 m → always jitter.
        //   • vInst = 4 m / 1 s = 4 m/s; accel = |4-prevSpeed|/1; at worst 4 m/s² (= threshold,
        //     NOT strictly greater) → does not trigger spike. Distance stays 0 every step.
        final rng = Random(99);
        var state = const FilterState();
        var total = 0.0;

        for (var i = 0; i < 30 * 60; i++) {
          final northNoise =
              (rng.nextDouble() - 0.5) * 2 * 4; // ±4 m single-axis
          final p = _sample(
            tsMs: i * 1000,
            position: _offset(_origin, northNoise, 0),
            hAccuracyM: 10.0,
          );
          final r = GpsFilter.step(
            state,
            p,
            nowMs: i * 1000,
            isStationary: false,
            cfg: _cfg,
          );
          state = r.newState;
          total += r.distanceAddedM;
        }
        // All points are within jitter bubble → total must be 0.
        expect(total, 0.0);
      });
    },
  );

  group('Property — distance never increases while stationary', () {
    test('any random walk with isStationary=true produces 0 total', () {
      final rng = Random(1337);
      var state = const FilterState();
      var total = 0.0;

      for (var i = 0; i < 500; i++) {
        final northNoise = (rng.nextDouble() - 0.5) * 20;
        final eastNoise = (rng.nextDouble() - 0.5) * 20;
        final p = _sample(
          tsMs: i * 1000,
          position: _offset(_origin, northNoise, eastNoise),
          hAccuracyM: rng.nextDouble() * 10 + 1,
        );
        final r = GpsFilter.step(
          state,
          p,
          nowMs: i * 1000,
          isStationary: true,
          cfg: _cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }
      expect(total, 0.0);
    });
  });

  group('E — known limitation: non-stationary drift', () {
    // Static positions oscillating -8,-4,0,+4,+8,+4,0,-4,-8 m north,
    // acc 10, 1 Hz, isStationary=false.
    // The jitter filter cannot prevent all phantom distance when
    // cumulative drift exceeds the uncertainty bubble.
    // Measured total: 24 m (asserted exactly ±0.5 m).
    test('known limitation: non-stationary drift', () {
      final cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      const northOffsets = [-8.0, -4.0, 0.0, 4.0, 8.0, 4.0, 0.0, -4.0, -8.0];
      var state = const FilterState();
      var total = 0.0;

      for (var i = 0; i < northOffsets.length; i++) {
        final p = GpsSample(
          tsMs: i * 1000,
          position: _offset(_origin, northOffsets[i], 0),
          hAccuracyM: 10.0,
        );
        final r = GpsFilter.step(
          state,
          p,
          nowMs: i * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      // Measured total is 24 m (±0.5 m).
      // Explanation: jitter threshold = 10 m; anchor advances when cumulative
      // drift from anchor exceeds 10 m (at +12 m from -8 and -12 m from +4).
      expect(total, closeTo(24.0, 0.5));
    });
  });
}
