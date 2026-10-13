import 'dart:math' as math;

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
double haversineDistance(
  double lat1,
  double lon1,
  double lat2,
  double lon2, {
  double radius = earthRadiusMeters,
}) {
  if (lat1 == lat2 && lon1 == lon2) {
    return 0.0;
  }

  final phi1 = _degreesToRadians(lat1);
  final phi2 = _degreesToRadians(lat2);
  final deltaPhi = _degreesToRadians(lat2 - lat1);
  final deltaLambda = _degreesToRadians(lon2 - lon1);

  final sinHalfDeltaPhi = math.sin(deltaPhi / 2.0);
  final sinHalfDeltaLambda = math.sin(deltaLambda / 2.0);

  final a =
      sinHalfDeltaPhi * sinHalfDeltaPhi +
      math.cos(phi1) * math.cos(phi2) * sinHalfDeltaLambda * sinHalfDeltaLambda;

  final clampedA = a.clamp(0.0, 1.0);
  final c = 2.0 * math.atan2(math.sqrt(clampedA), math.sqrt(1.0 - clampedA));

  return radius * c;
}

/// Alias for [haversineDistance] matching plan §7.1 naming.
double haversine(
  double lat1,
  double lon1,
  double lat2,
  double lon2, {
  double radius = earthRadiusMeters,
}) => haversineDistance(lat1, lon1, lat2, lon2, radius: radius);

/// Immutable geographic point representation (latitude and longitude).
class GeoPoint {
  final double latitude;
  final double longitude;

  const GeoPoint({required this.latitude, required this.longitude});

  /// Computes distance to [other] GeoPoint using Haversine formula.
  double distanceTo(GeoPoint other, {double radius = earthRadiusMeters}) =>
      haversineDistance(
        latitude,
        longitude,
        other.latitude,
        other.longitude,
        radius: radius,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);

  @override
  String toString() => 'GeoPoint(latitude: $latitude, longitude: $longitude)';
}
