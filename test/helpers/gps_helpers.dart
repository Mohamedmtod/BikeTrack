import 'dart:math';

import 'package:biketrack/domain/domain.dart';

/// Lat offset: 1° ≈ 111 195 m
const double mPerDegLat = 111195.0;

/// Lon offset at equator: 1° ≈ 111 195 m. Adjust for actual latitude if needed.
const double mPerDegLon = 111195.0;

/// Returns a [GeoPoint] offset from [origin] by [northM] metres north and
/// [eastM] metres east (small-angle approximation, good for < 10 km).
GeoPoint offset(GeoPoint origin, double northM, double eastM) {
  return GeoPoint(
    origin.latDeg + northM / mPerDegLat,
    origin.lonDeg + eastM / (mPerDegLon * cos(origin.latDeg * pi / 180.0)),
  );
}

/// Build a [GpsSample] at [origin] offset by [northM]/[eastM].
GpsSample sample({
  required int tsMs,
  required GeoPoint position,
  double hAccuracyM = 5.0,
}) => GpsSample(tsMs: tsMs, position: position, hAccuracyM: hAccuracyM);

const origin = GeoPoint(30.0444, 31.2357); // Cairo-ish

const defaultCfg = GpsFilterConfig(); // all defaults from §6.4
