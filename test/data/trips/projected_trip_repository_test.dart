import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/trips/projected_trip_repository.dart';
import 'package:biketrack/data/projection/projection_snapshot.dart';
import 'package:biketrack/data/projection/projection_state_repository.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/ride_fixture.dart';

void main() {
  late AppDatabase db;
  late ProjectedTripRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProjectedTripRepository(db);
  });
  tearDown(() => db.close());

  test('history includes terminal only and orders by start, segments and insertion ID', () async {
    await seedTrip(db, 'older', start: 1000);
    await seedTrip(db, 'review', start: 2000, status: TripStatus.needsReview);
    await seedTrip(
      db,
      'live',
      start: 4000,
      end: null,
      status: TripStatus.active,
    );
    await seedSegment(db, 'later', 'review', start: 3000);
    await seedSegment(db, 'earlier', 'review', start: 2000);
    await seedPoint(db, 9, 'earlier', ts: 9000);
    await seedPoint(db, 4, 'later', ts: 10000, accepted: false);
    await seedPoint(db, 3, 'earlier', ts: 11000);

    final history = await repository.history();
    expect(history.map((e) => e.trip.tripId), ['review', 'older']);
    expect(history.first.segments.map((e) => e.segmentId), [
      'earlier',
      'later',
    ]);
    expect(history.first.points.map((e) => e.id), [3, 4, 9]);
    expect(history.first.points[1].accepted, isFalse);
    expect((await repository.read('live'))?.trip.status, TripStatus.active);
    expect(await repository.read('missing'), isNull);
  });

  test('active reads only the projected snapshot trip, not the newest raw or terminal trip', () async {
    await seedTrip(db, 'completed');
    await seedTrip(db, 'active', status: TripStatus.active, end: null);
    await seedSegment(db, 'active-segment', 'active');
    await seedSegment(db, 'completed-segment', 'completed');
    await seedPoint(db, 5, 'completed-segment');
    await seedPoint(db, 6, 'active-segment');
    expect(await repository.active(), isNull);
    await ProjectionStateRepository(
      db,
    ).save(const ProjectionSnapshot.initial().copyWith(activeTripId: 'active'));
    final evidence = await repository.active();
    expect(evidence?.trip.tripId, 'active');
    expect(evidence?.points.map((p) => p.id), [6]);
  });
}
