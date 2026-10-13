import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/gps_helpers.dart';

const _origin = origin;
const _cfg = defaultCfg;

void main() {
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
