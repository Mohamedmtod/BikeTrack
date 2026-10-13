import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/gps_helpers.dart';

const _origin = origin;
const _cfg = defaultCfg;
const _offset = offset;
const _sample = sample;

void main() {
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
}
