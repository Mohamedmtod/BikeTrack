import 'package:drift/drift.dart';

import '../../domain/trip/trip_status.dart';
import '../database/app_database.dart';
import '../projection/projection_state_repository.dart';

class ProjectedTripEvidence {
  const ProjectedTripEvidence(this.trip, this.segments, this.points);

  final Trip trip;
  final List<Segment> segments;
  final List<GpsPoint> points;
}

class ProjectedTripRepository {
  ProjectedTripRepository(this._database);

  final AppDatabase _database;

  Future<ProjectedTripEvidence?> active() => _database.transaction(() async {
    final tripId = (await ProjectionStateRepository(
      _database,
    ).load()).activeTripId;
    return tripId == null ? null : _readTrip(tripId);
  });

  Future<ProjectedTripEvidence?> read(String tripId) =>
      _database.transaction(() => _readTrip(tripId));

  Future<List<ProjectedTripEvidence>> history() =>
      _database.transaction(() async {
        final trips = await _database
            .customSelect(
              'SELECT * FROM trips WHERE status IN (?, ?) '
              'ORDER BY start_time_utc DESC, rowid DESC',
              variables: [
                Variable.withString(TripStatus.completed.name),
                Variable.withString(TripStatus.needsReview.name),
              ],
              readsFrom: {_database.trips},
            )
            .map((row) => _database.trips.map(row.data))
            .get();
        final results = <ProjectedTripEvidence>[];
        for (final trip in trips) {
          results.add(await _evidence(trip));
        }
        return results;
      });

  Future<ProjectedTripEvidence?> _readTrip(String id) async {
    final trip = await (_database.select(
      _database.trips,
    )..where((trip) => trip.tripId.equals(id))).getSingleOrNull();
    return trip == null ? null : _evidence(trip);
  }

  Future<ProjectedTripEvidence> _evidence(Trip trip) async {
    final segments = await _database
        .customSelect(
          'SELECT * FROM segments WHERE trip_id = ? ORDER BY start_utc, rowid',
          variables: [Variable.withString(trip.tripId)],
          readsFrom: {_database.segments},
        )
        .map((row) => _database.segments.map(row.data))
        .get();
    if (segments.isEmpty) return ProjectedTripEvidence(trip, segments, []);
    final points =
        await (_database.select(_database.gpsPoints)
              ..where(
                (point) => point.segmentId.isIn(
                  segments.map((segment) => segment.segmentId).toList(),
                ),
              )
              ..orderBy([(point) => OrderingTerm.asc(point.id)]))
            .get();
    return ProjectedTripEvidence(trip, segments, points);
  }
}
