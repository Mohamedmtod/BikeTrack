import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/gps_helpers.dart';

const _origin = origin;
const _cfg = defaultCfg;
const _offset = offset;
const _sample = sample;

void main() {
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
