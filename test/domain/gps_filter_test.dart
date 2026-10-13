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

  group('Check 4 — outOfOrder (tsMs ≤ lastRawTsMs)', () {
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
      // Conservative anchor policy (D-019): anchor is cleared.
      expect(r.newState.anchor, isNull);
    });
  });

  group('Check 7 — spike (acceleration)', () {
    test('sudden large acceleration is rejected as spike', () {
      // p0 at t=0: anchorReset at origin, prevSpeed=0.
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // p1 at t=5000 ms, 6 m north over 5 s → vInst = 1.2 m/s.
      // accel = |1.2 - 0| / 5 = 0.24 m/s² ≤ 4 ✓; d = 6 m > threshold 5 m (not jitter).
      // Anchor advances to p1, prevSpeed ≈ 1.2 m/s.
      final p1 = GpsSample(
        tsMs: 5000,
        position: _offset(_origin, 6, 0),
        hAccuracyM: 5.0,
      );
      state = GpsFilter.step(
        state,
        p1,
        nowMs: 5000,
        isStationary: false,
        cfg: _cfg,
      ).newState;
      expect(state.anchor?.tsMs, 5000); // anchor = p1
      expect(state.prevSpeedMps, closeTo(1.2, 0.1));

      // p2 at t=6000 ms, 6+14=20 m north over 1 s.
      // vInst (p1→p2) = 14 m/s; accel = |14 - 1.2| / 1 ≈ 12.8 m/s² > 4 → spike.
      // d from anchor (p1 at 6 m) = 14 m; vFromAnchor = 14/1 = 14 ≤ 16.7 → no impossibleSpeed ✓.
      final p2 = GpsSample(
        tsMs: 6000,
        position: _offset(_origin, 6 + 14, 0),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        state,
        p2,
        nowMs: 6000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.spike);
      // Conservative anchor policy (D-019): anchor is cleared.
      expect(r.newState.anchor, isNull);
    });
  });

  group('Check 8 — stationaryGate', () {
    test('isStationary=true → accepted, distance 0, anchor CLEARED (D-019)', () {
      // Use a 2-second interval so vInst = 2m/2s = 1 m/s; accel = |1-0|/2 = 0.5 → no spike.
      final p1 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p1,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;
      expect(state.anchor, isNotNull); // anchor was set

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
      // Conservative anchor policy (D-019): anchor cleared, not preserved.
      expect(r.newState.anchor, isNull);
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

  group('Straight line at 5 m/s, acc 5 m, 1 pt/s → within 1% of true distance', () {
    test('accumulated distance within 1% of haversine true distance', () {
      // threshold = max(3, 0.5*(5+5)) = 5 m; step = 5 m; 5 >= 5 → barely passes
      // (we use >threshold strictly — 5 m step, threshold 5 → jitter? Let's check:
      //  d < threshold → jitter. 5 < 5 is false → accepted. ✓)
      const dPerStep = 5.0; // metres per second
      const acc = 5.0;
      var state = const FilterState();
      var total = 0.0;

      // Compute true distance as haversine sum of path segments.
      double trueDist = 0.0;
      GeoPoint? prevPos;
      for (var i = 0; i <= 200; i++) {
        // 200 steps × 5 m = 1000 m
        final pos = _offset(_origin, i * dPerStep, 0);
        if (prevPos != null) {
          trueDist += haversineMeters(prevPos, pos);
        }
        prevPos = pos;

        final p = _sample(tsMs: i * 1000, position: pos, hAccuracyM: acc);
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
      // Within 1% of true haversine distance (+ 0.01 m epsilon).
      expect(total, greaterThanOrEqualTo(trueDist * 0.99 - 0.01));
      expect(total, lessThanOrEqualTo(trueDist + 0.01));
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
      expect(state.lastTrusted, isNotNull); // lastTrusted preserved

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

  // -------------------------------------------------------------------------
  // T-006R required tests (A–G)
  // -------------------------------------------------------------------------

  group('A — Regression: exact Codex sequence produces 0 phantom distance', () {
    // 1 Hz, acc 10, isStationary=false; anchor at 0 m t=0;
    // points at 100 m north for t=1..7 → total distance == 0.
    // Jitter threshold = max(3, 0.5*(10+10)) = 10 m.
    // All points 100 m from anchor; vFromAnchor = 100/t ≤ 16.7 for t ≥ 6 s,
    // but accel spike fires on the first jump (100 m/s from prevSpeed=0).
    // After spike the anchor is cleared (D-019); next point gets anchorReset.
    // The oscillation around anchor 0 with 100 m steps either spikes or is
    // accepted with distance, but the key assertion is total == 0.
    //
    // Actual behaviour: t=1 → impossibleSpeed (100 m/s > 16.7); anchor cleared.
    // t=2 → anchorReset (anchor was null). t=3..7 → impossibleSpeed (50,33,25,20,14 m/s
    // but anchor keeps getting cleared). Total = 0.
    test('total distance == 0', () {
      final cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      var state = const FilterState();

      // t=0: anchor at 0 m north
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 10.0);
      var r = GpsFilter.step(
        state,
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: cfg,
      );
      state = r.newState;
      var total = r.distanceAddedM;

      // t=1..7: points at 100 m north
      for (var t = 1; t <= 7; t++) {
        final p = GpsSample(
          tsMs: t * 1000,
          position: _offset(_origin, 100, 0),
          hAccuracyM: 10.0,
        );
        r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      expect(total, 0.0);
    });
  });

  group('B — Stationary then move: first valid moving point → anchorReset', () {
    test('after isStationary=true sample, first moving point gets anchorReset, distance 0', () {
      // Step 1: establish anchor
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 5.0);
      var state = GpsFilter.step(
        const FilterState(),
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Step 2: stationary sample — anchor should be cleared
      final p1 = GpsSample(
        tsMs: 1000,
        position: _offset(_origin, 1, 0),
        hAccuracyM: 5.0,
      );
      state = GpsFilter.step(
        state,
        p1,
        nowMs: 1000,
        isStationary: true,
        cfg: _cfg,
      ).newState;
      expect(state.anchor, isNull); // anchor cleared by stationary gate

      // Step 3: first valid moving point → anchorReset, distance 0
      final p2 = GpsSample(
        tsMs: 2000,
        position: _offset(_origin, 50, 0),
        hAccuracyM: 5.0,
      );
      final r2 = GpsFilter.step(
        state,
        p2,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r2.reason, RejectReason.anchorReset);
      expect(r2.distanceAddedM, 0.0);
    });
  });

  group('C — prevSpeed consistency: instantaneous speed after jitter and accepted steps', () {
    test('newState.prevSpeedMps equals instantaneous speed (±1e-6)', () {
      // Establish anchor at origin
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 10.0);
      var state = GpsFilter.step(
        const FilterState(),
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: _cfg,
      ).newState;

      // Jitter step: 4 m in 1 s → jitter (threshold=10 m)
      // instantaneous speed = 4/1 = 4 m/s
      final p1 = GpsSample(
        tsMs: 1000,
        position: _offset(_origin, 4, 0),
        hAccuracyM: 10.0,
      );
      final r1 = GpsFilter.step(
        state,
        p1,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r1.reason, RejectReason.jitter);
      final expectedSpeedJitter =
          haversineMeters(_origin, _offset(_origin, 4, 0)) / 1.0;
      expect(r1.newState.prevSpeedMps, closeTo(expectedSpeedJitter, 1e-6));
      state = r1.newState;

      // Accepted step: 15 m in 1 s from lastTrusted (at 4 m north)
      // instantaneous from lastTrusted: haversine(4m north, 19m north) / 1s ≈ 15 m/s
      // accel = |15 - 4| / 1 = 11 > 4 → spike! Use a gentler step.
      // Instead: 3 m more in 1 s (from 4 m north to 7 m north), vInst=3/1=3
      // accel = |3-4|/1 = 1 ≤ 4; anchor still p0, d from anchor = 7 m < 10 m → jitter again
      // Use bigger movement: go to 15 m north from p0 anchor (11 m from p1 at 4m).
      // vInst = 11/1 = 11; accel = |11-4|/1 = 7 > 4 → spike. Hmm.
      // Use gentle accel: go to 6 m north from p0 (2 m from p1 at 4m)
      // vInst=2/1=2; accel=|2-4|/1=2≤4; d from anchor=6<10 → jitter again
      // For accepted: d from anchor must exceed 10 m, move to 11 m north from p0
      // from p1 (at 4m): 7 m in 1 s → vInst=7; accel=|7-4|/1=3≤4; d=11>10 → accepted!
      final p2 = GpsSample(
        tsMs: 2000,
        position: _offset(_origin, 11, 0),
        hAccuracyM: 10.0,
      );
      final r2 = GpsFilter.step(
        state,
        p2,
        nowMs: 2000,
        isStationary: false,
        cfg: _cfg,
      );
      // Should be accepted (distance > 0)
      expect(r2.accepted, isTrue);
      expect(r2.reason, isNull); // genuine movement
      final expectedSpeedAccepted =
          haversineMeters(_offset(_origin, 4, 0), _offset(_origin, 11, 0)) /
          1.0;
      expect(r2.newState.prevSpeedMps, closeTo(expectedSpeedAccepted, 1e-6));
    });
  });

  group('D — NaN/Infinity in hAccuracyM, latDeg, lonDeg → invalid', () {
    test('NaN hAccuracyM → invalid', () {
      final p = GpsSample(
        tsMs: 1000,
        position: _origin,
        hAccuracyM: double.nan,
      );
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.invalid);
    });

    test('Infinity hAccuracyM → invalid', () {
      final p = GpsSample(
        tsMs: 1000,
        position: _origin,
        hAccuracyM: double.infinity,
      );
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.invalid);
    });

    test('NaN latDeg → invalid', () {
      final p = GpsSample(
        tsMs: 1000,
        position: GeoPoint(double.nan, 31.0),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.invalid);
    });

    test('Infinity lonDeg → invalid', () {
      final p = GpsSample(
        tsMs: 1000,
        position: GeoPoint(30.0, double.infinity),
        hAccuracyM: 5.0,
      );
      final r = GpsFilter.step(
        const FilterState(),
        p,
        nowMs: 1000,
        isStationary: false,
        cfg: _cfg,
      );
      expect(r.accepted, isFalse);
      expect(r.reason, RejectReason.invalid);
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

  group('F — Realistic restart: stationary then accelerate, total ≥ 95% true distance', () {
    // After stationary, accelerate 0→6 m/s at 1.5 m/s² then cruise.
    // 1 Hz, acc 5, 120 s total. True distance ≈ cruise portion after accel.
    test('total ≥ 95% of true distance', () {
      const cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );

      const accel = 1.5; // m/s²
      const targetSpeed = 6.0; // m/s
      // Time to reach target speed: 6/1.5 = 4 s
      const accelTime = targetSpeed / accel; // 4 s
      // Distance during accel: 0.5 * a * t² = 0.5 * 1.5 * 16 = 12 m
      const accelDist = 0.5 * accel * accelTime * accelTime;
      // Cruise time: 120 - 4 = 116 s; cruise distance = 6 * 116 = 696 m
      const totalSecs = 120;
      const cruiseDist = targetSpeed * (totalSecs - accelTime);
      const trueDist = accelDist + cruiseDist; // 12 + 696 = 708 m

      var state = const FilterState();
      var total = 0.0;
      double posN = 0.0;

      // t=0: stationary (anchor established then cleared by stationaryGate)
      final p0 = GpsSample(
        tsMs: 0,
        position: _offset(_origin, posN, 0),
        hAccuracyM: 5.0,
      );
      var r = GpsFilter.step(state, p0, nowMs: 0, isStationary: true, cfg: cfg);
      state = r.newState;
      total += r.distanceAddedM;

      for (var t = 1; t <= totalSecs; t++) {
        final speed = t <= accelTime ? accel * t : targetSpeed;
        posN += speed;
        final p = GpsSample(
          tsMs: t * 1000,
          position: _offset(_origin, posN, 0),
          hAccuracyM: 5.0,
        );
        r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      expect(total, greaterThanOrEqualTo(trueDist * 0.95));
    });
  });

  group('G — Mid-ride outlier: cruise 5 m/s, one 60 m off-track point at t=30', () {
    // Start from a FilterState already cruising: lastTrusted and anchor at t=-1 s,
    // position -5 m north (one step behind origin), prevSpeed 5 m/s,
    // lastRawTsMs = -1000 ms. Cruise 5 m/s for 60 s (t=0..59).
    // Outlier 60 m east at t=30. True distance = haversine sum of 60 s cruise.
    // Assert total ∈ [true - 15 m, true] (+ 0.01 m epsilon).
    test('outlier does not inflate total by more than 15 m', () {
      const cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      const speed = 5.0; // m/s
      const cruiseSecs = 60;

      // Pre-built cruising state (D-020): lastTrusted + anchor at t=-1 s / -5 m north.
      final anchorPos = _offset(_origin, -speed, 0); // -5 m north
      final anchorSample = GpsSample(
        tsMs: -1000,
        position: anchorPos,
        hAccuracyM: 5.0,
      );
      var state = FilterState(
        lastRawTsMs: -1000,
        lastTrusted: anchorSample,
        anchor: anchorSample,
        prevSpeedMps: 5.0,
      );
      var total = 0.0;

      // Compute true distance as haversine sum of 60 cruise points.
      double trueDist = 0.0;
      GeoPoint prevPos = anchorPos;
      for (var t = 0; t < cruiseSecs; t++) {
        final pos = _offset(
          _origin,
          t * speed,
          0,
        ); // each step is 5 m north from origin
        trueDist += haversineMeters(prevPos, pos);
        prevPos = pos;
      }

      // Cruise loop.
      const outlierT = 30;
      for (var t = 0; t < cruiseSecs; t++) {
        final normalPos = _offset(_origin, t * speed, 0);
        final GeoPoint pos = (t == outlierT)
            ? _offset(_origin, t * speed, 60) // 60 m east outlier
            : normalPos;
        final p = GpsSample(tsMs: t * 1000, position: pos, hAccuracyM: 5.0);
        final r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }
      // Total within [true - 15 m, true] (+ 0.01 m epsilon).
      expect(total, greaterThanOrEqualTo(trueDist - 15.0 - 0.01));
      expect(total, lessThanOrEqualTo(trueDist + 0.01));
    });
  });

  group('H — Two consecutive outliers 60 m off-track mid-cruise → total within [true - 20 m, true]', () {
    // Start from cruising state (same as G). Two consecutive outliers at t=30, t=31.
    // Assert total ∈ [true - 20 m, true] (+ 0.01 m epsilon).
    test('two consecutive outliers do not inflate total', () {
      const cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      const speed = 5.0; // m/s
      const cruiseSecs = 60;

      final anchorPos = _offset(_origin, -speed, 0);
      final anchorSample = GpsSample(
        tsMs: -1000,
        position: anchorPos,
        hAccuracyM: 5.0,
      );
      var state = FilterState(
        lastRawTsMs: -1000,
        lastTrusted: anchorSample,
        anchor: anchorSample,
        prevSpeedMps: 5.0,
      );
      var total = 0.0;

      // True distance as haversine sum.
      double trueDist = 0.0;
      GeoPoint prevPos = anchorPos;
      for (var t = 0; t < cruiseSecs; t++) {
        final pos = _offset(_origin, t * speed, 0);
        trueDist += haversineMeters(prevPos, pos);
        prevPos = pos;
      }

      for (var t = 0; t < cruiseSecs; t++) {
        final normalPos = _offset(_origin, t * speed, 0);
        final GeoPoint pos = (t == 30 || t == 31)
            ? _offset(_origin, t * speed, 60) // two consecutive outliers
            : normalPos;
        final p = GpsSample(tsMs: t * 1000, position: pos, hAccuracyM: 5.0);
        final r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }
      // Total within [true - 20 m, true] (+ 0.01 m epsilon).
      expect(total, greaterThanOrEqualTo(trueDist - 20.0 - 0.01));
      expect(total, lessThanOrEqualTo(trueDist + 0.01));
    });
  });

  group('I — After outlier, next normal point is NOT rejected as spike', () {
    // Start from cruising state. Single outlier at t=30.
    // The point at t=31 (normal, on-track) must be accepted (anchorReset or genuine movement),
    // NOT rejected as spike (D-020: spike check uses lastTrusted which is not the outlier).
    test('point after outlier is not rejected as spike', () {
      const cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      const speed = 5.0; // m/s

      final anchorPos = _offset(_origin, -speed, 0);
      final anchorSample = GpsSample(
        tsMs: -1000,
        position: anchorPos,
        hAccuracyM: 5.0,
      );
      var state = FilterState(
        lastRawTsMs: -1000,
        lastTrusted: anchorSample,
        anchor: anchorSample,
        prevSpeedMps: 5.0,
      );

      // Cruise up to t=29.
      for (var t = 0; t < 30; t++) {
        final p = GpsSample(
          tsMs: t * 1000,
          position: _offset(_origin, t * speed, 0),
          hAccuracyM: 5.0,
        );
        state = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        ).newState;
      }

      // Outlier at t=30.
      final outlier = GpsSample(
        tsMs: 30000,
        position: _offset(_origin, 30 * speed, 60), // 60 m east
        hAccuracyM: 5.0,
      );
      final rOutlier = GpsFilter.step(
        state,
        outlier,
        nowMs: 30000,
        isStationary: false,
        cfg: cfg,
      );
      state = rOutlier.newState;
      // Outlier must be rejected (spike or impossibleSpeed).
      expect(rOutlier.accepted, isFalse);

      // Normal point at t=31.
      final normalNext = GpsSample(
        tsMs: 31000,
        position: _offset(_origin, 31 * speed, 0), // back on-track
        hAccuracyM: 5.0,
      );
      final rNext = GpsFilter.step(
        state,
        normalNext,
        nowMs: 31000,
        isStationary: false,
        cfg: cfg,
      );
      // Must NOT be rejected as spike.
      expect(rNext.reason, isNot(RejectReason.spike));
      expect(rNext.accepted, isTrue);
    });
  });

  group('J — three consecutive outliers mid-cruise', () {
    test('three consecutive outliers do not inflate total', () {
      const cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      const speed = 5.0; // m/s
      const cruiseSecs = 60;

      final anchorPos = _offset(_origin, -speed, 0);
      final anchorSample = GpsSample(
        tsMs: -1000,
        position: anchorPos,
        hAccuracyM: 5.0,
      );
      var state = FilterState(
        lastRawTsMs: -1000,
        lastTrusted: anchorSample,
        anchor: anchorSample,
        prevSpeedMps: 5.0,
      );
      var total = 0.0;

      // True distance as haversine sum of 60 cruise points.
      double trueDist = 0.0;
      GeoPoint prevPos = anchorPos;
      for (var t = 0; t < cruiseSecs; t++) {
        final pos = _offset(_origin, t * speed, 0);
        trueDist += haversineMeters(prevPos, pos);
        prevPos = pos;
      }

      for (var t = 0; t < cruiseSecs; t++) {
        final normalPos = _offset(_origin, t * speed, 0);
        final GeoPoint pos = (t == 30 || t == 31 || t == 32)
            ? _offset(_origin, t * speed, 60)
            : normalPos;
        final p = GpsSample(tsMs: t * 1000, position: pos, hAccuracyM: 5.0);
        final r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      expect(total, greaterThanOrEqualTo(trueDist - 20.0 - 0.01));
      expect(total, lessThanOrEqualTo(trueDist + 0.01));
    });
  });

  group('K — persistent 100 m offset for 20 s', () {
    test('total distance == 0', () {
      final cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      var state = const FilterState();

      // t=0: anchor at 0 m north
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 10.0);
      var r = GpsFilter.step(
        state,
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: cfg,
      );
      state = r.newState;
      var total = r.distanceAddedM;

      // t=1..20: points at 100 m north
      for (var t = 1; t <= 20; t++) {
        final p = GpsSample(
          tsMs: t * 1000,
          position: _offset(_origin, 100, 0),
          hAccuracyM: 10.0,
        );
        r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      expect(total, 0.0);
    });
  });

  group('L — persistent 100 m offset for 60 s', () {
    test('total distance == 0', () {
      final cfg = GpsFilterConfig(
        maxHAccuracyM: 25,
        maxSpeedMps: 16.7,
        maxAccelMps2: 4.0,
        minStepM: 3.0,
        staleMs: 10000,
        gapMs: 30000,
      );
      var state = const FilterState();

      // t=0: anchor at 0 m north
      final p0 = GpsSample(tsMs: 0, position: _origin, hAccuracyM: 10.0);
      var r = GpsFilter.step(
        state,
        p0,
        nowMs: 0,
        isStationary: false,
        cfg: cfg,
      );
      state = r.newState;
      var total = r.distanceAddedM;

      // t=1..60: points at 100 m north
      for (var t = 1; t <= 60; t++) {
        final p = GpsSample(
          tsMs: t * 1000,
          position: _offset(_origin, 100, 0),
          hAccuracyM: 10.0,
        );
        r = GpsFilter.step(
          state,
          p,
          nowMs: t * 1000,
          isStationary: false,
          cfg: cfg,
        );
        state = r.newState;
        total += r.distanceAddedM;
      }

      expect(total, 0.0);
    });
  });
}
