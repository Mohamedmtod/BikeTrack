import 'dart:math' as math;

import 'geo_point.dart';

/// Mean Earth radius in meters according to engineering plan §7.1.
const double earthRadiusMeters = 6371000.0;

/// Converts degrees to radians.
double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

/// Calculates the great-circle distance in meters between two coordinates
/// using the Haversine formula as defined in engineering plan §7.1:
///
/// a = sin²(Δφ / 2) + cos(φ₁) * cos(φ₂) * sin²(Δλ / 2)
/// d = 2 * R * atan2(√a, √(1 - a))
///
/// where R = 6,371,000 meters.
double haversineMeters(GeoPoint a, GeoPoint b) {
  if (a == b || (a.latDeg == b.latDeg && a.lonDeg == b.lonDeg)) {
    return 0.0;
  }

  final phi1 = _degreesToRadians(a.latDeg);
  final phi2 = _degreesToRadians(b.latDeg);
  final deltaPhi = _degreesToRadians(b.latDeg - a.latDeg);
  final deltaLambda = _degreesToRadians(b.lonDeg - a.lonDeg);

  final sinHalfDeltaPhi = math.sin(deltaPhi / 2.0);
  final sinHalfDeltaLambda = math.sin(deltaLambda / 2.0);

  final aTerm =
      sinHalfDeltaPhi * sinHalfDeltaPhi +
      math.cos(phi1) * math.cos(phi2) * sinHalfDeltaLambda * sinHalfDeltaLambda;

  final clampedA = aTerm.clamp(0.0, 1.0);
  final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));

  return earthRadiusMeters * c;
}
