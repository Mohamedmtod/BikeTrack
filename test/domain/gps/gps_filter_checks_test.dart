import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/gps_helpers.dart';

const _origin = origin;
const _cfg = defaultCfg;
const _offset = offset;
const _sample = sample;

void main() {
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
}
