import '../data/database/app_database.dart';
import '../data/trips/projected_trip_repository.dart';
import '../domain/geo/geo_point.dart';
import '../domain/geo/haversine.dart';
import '../domain/gps/reject_reason.dart';
import '../domain/trip/distance_status.dart';
import '../domain/trip/segment_type.dart';

class RideRoute {
  const RideRoute(this.pieces, this.distanceM, this.status);

  final List<List<GeoPoint>> pieces;
  final double? distanceM;
  final DistanceStatus status;

  static RideRoute fromEvidence(ProjectedTripEvidence evidence) {
    final bySegment = <String, List<GpsPoint>>{};
    for (final point in evidence.points) {
      bySegment.putIfAbsent(point.segmentId, () => []).add(point);
    }
    final pieces = <List<GeoPoint>>[];
    double distance = 0;
    var measurable = false;
    var incomplete = evidence.segments.isEmpty;

    for (final segment in evidence.segments) {
      if (segment.type == SegmentType.gap) {
        incomplete = true;
        continue;
      }
      final rows = bySegment[segment.segmentId] ?? [];
      var current = <GeoPoint>[];
      GeoPoint? anchor;
      var segmentMeasurable = false;
      void finish() {
        if (current.isNotEmpty) pieces.add(current);
        current = <GeoPoint>[];
        anchor = null;
      }

      for (final point in rows) {
        if (!point.accepted) {
          incomplete = true;
          if (point.rejectReason == RejectReason.impossibleSpeed.name ||
              point.rejectReason == RejectReason.spike.name) {
            finish();
          }
          continue;
        }
        final reason = point.rejectReason;
        if (reason == RejectReason.anchorReset.name && current.isNotEmpty) {
          incomplete = true;
          finish();
        }
        if (reason == RejectReason.stationaryGate.name) {
          incomplete = true;
          finish();
          continue;
        }
        final coordinate = GeoPoint(point.lat, point.lon);
        current.add(coordinate);
        // Jitter is accepted evidence but does not move the filter's distance anchor.
        if (reason != RejectReason.jitter.name) {
          final previous = anchor;
          if (previous != null) {
            final step = haversineMeters(previous, coordinate);
            if (step > 0) {
              distance += step;
              measurable = true;
              segmentMeasurable = true;
            }
          }
          anchor = coordinate;
        }
      }
      finish();
      if (!segmentMeasurable) incomplete = true;
    }
    return RideRoute(
      pieces,
      measurable ? distance : null,
      !measurable
          ? DistanceStatus.unknown
          : incomplete
          ? DistanceStatus.partial
          : DistanceStatus.measured,
    );
  }
}
