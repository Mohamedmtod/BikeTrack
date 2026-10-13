/// Unit tests for GpsFilter (§7.2 / T-005).
///
/// One test per RejectReason + property / golden scenario tests.
/// All Random usage is seeded for determinism.
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:biketrack/domain/domain.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Lat offset: 1° ≈ 111 195 m
const double _mPerDegLat = 111195.0;

/// Lon offset at equator: 1° ≈ 111 195 m.  Adjust for actual latitude if needed.
const double _mPerDegLon = 111195.0;

/// Returns a [GeoPoint] offset from [origin] by [northM] metres north and
/// [eastM] metres east (small-angle approximation, good for < 10 km).
GeoPoint _offset(GeoPoint origin, double northM, double eastM) {
  return GeoPoint(
    origin.latDeg + northM / _mPerDegLat,
    origin.lonDeg + eastM / (_mPerDegLon * cos(origin.latDeg * pi / 180.0)),
  );
}

/// Build a [GpsSample] at [origin] offset by [northM]/[eastM].
GpsSample _sample({
  required int tsMs,
  required GeoPoint position,
  double hAccuracyM = 5.0,
}) => GpsSample(tsMs: tsMs, position: position, hAccuracyM: hAccuracyM);

const _origin = GeoPoint(30.0444, 31.2357); // Cairo-ish

const _cfg = GpsFilterConfig(); // all defaults from §6.4

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // One test per reject reason (checks 1-10)
  // -------------------------------------------------------------------------

  group('Check 1 — invalid (negative hAccuracy)', () {
    test('returns invalid, not accepted, distance 0', () {
      final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: -1.0);
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.invalid);
      expect(r.distanceAddedM, 0.0);
    });
  });

  group('Check 2 — lowAccuracy (hAccuracy > maxHAccuracyM)', () {
    test('returns lowAccuracy, not accepted, distance 0', () {
      final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 30.0);
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.lowAccuracy);
      expect(r.distanceAddedM, 0.0);
    });

    test('exactly at threshold (25 m) is accepted (boundary)', () {
      final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 25.0);
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      // 25.0 is NOT > 25.0 so it should pass check 2
      expect(r.reason, isNot(RejectReason.lowAccuracy));
    });
  });

  group('Check 3 — stale (age > staleMs)', () {
    test('returns stale, not accepted', () {
      final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 5.0);
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000 + _cfg.staleMs + 1, // 1 ms beyond threshold
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.stale);
    });

    test('exactly at staleMs boundary is accepted', () {
      final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 5.0);
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000 + _cfg.staleMs, // NOT > staleMs
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.reason, isNot(RejectReason.stale));
    });
  });

  group('Check 4 — outOfOrder (tsMs ≤ lastReceived.tsMs)', () {
    test('same timestamp rejected as outOfOrder', () {
      final first = GpsSample(tsMs: 2000, position: _origin, hAccuracyM: 5.0);
      var state = const FilterState();
      // Establish firstReceived
      state = GpsFilter.step(
        state,
        first,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      final dup = GpsSample(tsMs: 2000, position: _origin, hAccuracyM: 5.0);
      final r = GpsFilter.step(
        state,
        dup,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.outOfOrder);
    });

    test('earlier timestamp rejected as outOfOrder', () {
      final first = GpsSample(tsMs: 2000, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        first,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      final earlier = GpsSample(tsMs: 1500, position: _origin, hAccuracyM: 5.0);
      final r = GpsFilter.step(
        state,
        earlier,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.reason, RejectReason.outOfOrder);
    });
  });

  group('anchorReset — first point or after gap', () {
    test(
      'very first point sets anchor, distance = 0, reason = anchorReset',
      () {
        final p = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 5.0);
        final r = GpsFilter.step(
          const FilterState(),
          p,
          nowMs: 1000,
          isStationary: false,
          cfg: _cfg,
        );
        expect(r.accepted, isTrue);
        expect(r.reason, RejectReason.anchorReset);
        expect(r.distanceAddedM, 0.0);
        expect(r.newState.anchor, p);
      },
    );

    test('gap > gapMs resets anchor; next point gets anchorReset', () {
      final p1 = GpsSample(tsMs: 1000, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Move forward 100 m
      final p2 = GpsSample(
        tsMs: 1000 + _cfg.gapMs + 5000, // gap + 5 s
        position: _offset(_origin, 100, 0),
        hAccuracyM: 5.0,
      );
      final r2 = GpsFilter.step(
        state,
        p2,
        nowMs: p2.tsMs,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r2.reason, RejectReason.anchorReset);
      expect(r2.distanceAddedM, 0.0);
    });
  });

  group('Check 6 — impossibleSpeed', () {
    test('point implying > 16.7 m/s from anchor is rejected', () {
      final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // 1 km in 1 second = 1000 m/s >> 16.7 m/s
      final p2 = GpsSample(
        tsMs: 1000,
        position: _offset(_origin, 1000, 0),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        state,
        p2,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.impossibleSpeed);
    });
  });

  group('Check 7 — spike (acceleration)', () {
    test('sudden large acceleration is rejected as spike', () {
      // Establish anchor + lastReceived at rest
      final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Move 5 m in 1 s (normal, prevSpeed ≈ 5 m/s)
      final p2 = GpsSample(
        tsMs: 1000,
        position: _offset(_origin, 5, 0),
        hAccuracyM: 5.0,
      );
      state = GpsFilter.step(
        state,
        p2,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Now jump 100 m in 1 s (100 m/s — below speed cap from anchor but
      // acceleration |100 - 5| / 1 = 95 m/s² >> 4 m/s²).
      // We need a tricky scenario: keep speed plausible from anchor but
      // instantaneous accel from lastReceived very high.
      // Reset anchor so anchor is p2; then from p2 jump 14 m in 1 s (14 m/s)
      // while prevSpeed was 5 m/s → accel = 9 m/s² > 4.
      final p3 = GpsSample(
        tsMs: 2000,
        position: _offset(_origin, 5 + 14, 0),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        state,
        p3,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.spike);
    });
  });

  group('Check 8 — stationaryGate', () {
    test('isStationary=true → accepted, distance 0, anchor unchanged', () {
      // Use a 2-second interval so vInst = 2m/2s = 1 m/s; accel = |1-0|/2 = 0.5 → no spike.
      final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;
      final anchorBefore = state.anchor;

      // 2 m in 2 s → vInst = 1 m/s, accel from prevSpeed=0: |1-0|/2 = 0.5 ≤ 4 ✓
      // jitter threshold = max(3, 0.5*(5+5)) = 5 m; 2 m < 5 m → would be jitter if !stationary
      // But stationary gate (check 8) fires AFTER spike check (7) and BEFORE jitter (9)
      final p2 = GpsSample(
        tsMs: 2000,
        position: _offset(_origin, 2, 0),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        state,
        p2,
        nowMs: 2000,
        isStationary: true,
        cfg: _cfg,
      );
      expect(r.accepted, isTrue);
      expect(r.reason, RejectReason.stationaryGate);
      expect(r.distanceAddedM, 0.0);
      expect(r.newState.anchor, anchorBefore);
    });
  });

  group('Check 9 — jitter', () {
    test(
      'movement within uncertainty bubble is jitter: accepted, distance 0',
      () {
        const acc = 10.0; // hAccuracyM for both anchor and point
        // threshold = max(3, 0.5*(10+10)) = max(3, 10) = 10 m
        // move 9 m → jitter
        final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: acc);
        var state = GpsFilter.step(
          const FilterState(),
          p1,
          nowMs: 0,
          isStationary: false,
          cfg: _cfg,
        ).newState;

        final p2 = GpsSample(
          tsMs: 5000,
          position: _offset(_origin, 9, 0),
          hAccuracyM: acc,
        );
        final r = GpsFilter.step(
          state,
          p2,
          nowMs: 5000,
          isStationary: false,
          cfg: _cfg,
        );
        expect(r.accepted, isTrue);
        expect(r.reason, RejectReason.jitter);
        expect(r.distanceAddedM, 0.0);
        expect(r.newState.anchor, p1); // anchor stays
      },
    );

    test('movement above uncertainty bubble is accepted (no jitter)', () {
      const acc = 5.0;
      // threshold = max(3, 0.5*(5+5)) = max(3, 5) = 5 m
      // move 6 m → not jitter
      final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: acc);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      final p2 = GpsSample(
        tsMs: 5000,
        position: _offset(_origin, 6, 0),
        hAccuracyM: acc,
      );
      final r = GpsFilter.step(
        state,
        p2,
        nowMs: 5000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isTrue);
      expect(r.reason, isNull);
      expect(r.distanceAddedM, greaterThan(0));
    });
  });

  // -------------------------------------------------------------------------
  // Golden / property scenarios
  // -------------------------------------------------------------------------

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

  group('Stationary drift — isStationary=false, noise ≤ 8 m, acc 10 m → total < 20 m', () {
    test('jitter filter keeps phantom distance under 20 m', () {
      // Noise of ±4 m on a single axis:
      //   • jitter threshold = max(3, 0.5*(10+10)) = 10 m; max displacement = 4 m → always jitter.
      //   • vInst = 4 m / 1 s = 4 m/s; accel = |4-prevSpeed|/1; at worst 4 m/s² (= threshold,
      //     NOT strictly greater) → does not trigger spike. Distance stays 0 every step.
      final rng = Random(99);
      var state = const FilterState();
      var total = 0.0;

      for (var i = 0; i < 30 * 60; i++) {
        final northNoise = (rng.nextDouble() - 0.5) * 2 * 4; // ±4 m single-axis
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
  });

  group('Straight line 1000 m at 5 m/s, acc 5 m, 1 pt/s → within 1% of 1000', () {
    test('accumulated distance ≈ 1000 m ± 10 m', () {
      // threshold = max(3, 0.5*(5+5)) = 5 m; step = 5 m; 5 >= 5 → barely passes
      // (we use >threshold strictly — 5 m step, threshold 5 → jitter? Let's check:
      //  d < threshold → jitter. 5 < 5 is false → accepted. ✓)
      const dPerStep = 5.0; // metres per second
      const acc = 5.0;
      var state = const FilterState();
      var total = 0.0;

      for (var i = 0; i <= 200; i++) {
        // 200 steps × 5 m = 1000 m
        final p = _sample(
          tsMs: i * 1000,
          position: _offset(_origin, i * dPerStep, 0),
          hAccuracyM: acc,
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
      expect(total, closeTo(1000.0, 10.0)); // within 1%
    });
  });

  group('Resume after 60 s gap 200 m away → no distance added across gap', () {
    test('distance across gap is 0; anchor reset occurs', () {
      final p1 = _sample(tsMs: 0, position: _origin);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Normal movement: 50 m over 10 s
      final p2 = _sample(
        tsMs: 10000,
        position: _offset(_origin, 50, 0),
        hAccuracyM: 5.0,
      );
      final r2 = GpsFilter.step(
        state,
        p2,
        nowMs: 10000,
        isStationary: false,
        cfg: _cfg,
      );
      state = r2.newState;
      final distBefore = r2.distanceAddedM;

      // 60-second gap (> gapMs = 30 s), 200 m away
      final p3 = _sample(
        tsMs: 10000 + 60000, // 60 s gap
        position: _offset(_origin, 250, 0), // 200 m further
        hAccuracyM: 5.0,
      );
      final r3 = GpsFilter.step(
        state,
        p3,
        nowMs: p3.tsMs,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r3.reason, RejectReason.anchorReset);
      expect(r3.distanceAddedM, 0.0);
      // Only distBefore counts; gap adds nothing
      expect(distBefore, greaterThan(0));
    });
  });

  group('resetAnchor then next point → distance 0', () {
    test('caller resets anchor; first subsequent point gets anchorReset', () {
      final p1 = _sample(tsMs: 0, position: _origin);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Move normally
      final p2 = _sample(tsMs: 5000, position: _offset(_origin, 20, 0));
      state = GpsFilter.step(
        state,
        p2,
        nowMs: 5000,
        isStationary: false,
        cfg: _cfg,
      ).newState;
      expect(state.anchor, isNotNull);

      // Caller signals pause/segment-change
      state = GpsFilter.resetAnchor(state);
      expect(state.anchor, isNull);
      expect(state.lastReceived, isNotNull); // lastReceived preserved

      // Next point → anchorReset, distance 0
      final p3 = _sample(tsMs: 10000, position: _offset(_origin, 200, 0));
      final r3 = GpsFilter.step(
        state,
        p3,
        nowMs: 10000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r3.reason, RejectReason.anchorReset);
      expect(r3.distanceAddedM, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Property test: distance never increases while stationary
  // -------------------------------------------------------------------------
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
}
