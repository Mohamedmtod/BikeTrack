/// Immutable geographic point representation (latDeg, lonDeg) in degrees (D-017).
class GeoPoint {
  final double latDeg;
  final double lonDeg;

  const GeoPoint(this.latDeg, this.lonDeg);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          runtimeType == other.runtimeType &&
          latDeg == other.latDeg &&
          lonDeg == other.lonDeg;

  @override
  int get hashCode => Object.hash(latDeg, lonDeg);

  @override
  String toString() => 'GeoPoint($latDeg, $lonDeg)';
}
