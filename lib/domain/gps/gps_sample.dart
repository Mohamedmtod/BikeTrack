import '../geo/geo_point.dart';

/// An incoming GPS measurement.
///
/// [tsMs] — device timestamp in milliseconds since epoch (NOT wall time).
/// [position] — WGS-84 coordinates.
/// [hAccuracyM] — horizontal accuracy radius in metres (σ or 68th percentile).
class GpsSample {
  final int tsMs;
  final GeoPoint position;
  final double hAccuracyM;

  const GpsSample({
    required this.tsMs,
    required this.position,
    required this.hAccuracyM,
  });
}
