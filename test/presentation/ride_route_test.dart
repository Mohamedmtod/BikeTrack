import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/trips/projected_trip_repository.dart';
import 'package:biketrack/domain/trip/distance_status.dart';
import 'package:biketrack/domain/trip/segment_type.dart';
import 'package:biketrack/presentation/ride_route.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/ride_fixture.dart';

void main() {
  late AppDatabase db;
  late ProjectedTripRepository repository;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = ProjectedTripRepository(db);
  });
  tearDown(() => db.close());

  Future<RideRoute> route() async =>
      RideRoute.fromEvidence((await repository.read('ride'))!);

  test('no evidence, lone accepted point or only rejected fixes never invent zero distance', () async {
    await seedTrip(db, 'ride');
    expect((await route()).status, DistanceStatus.unknown);
    expect((await route()).distanceM, isNull);
    await seedSegment(db, 'one', 'ride');
    await seedPoint(db, 1, 'one', accepted: false, reason: 'lowAccuracy');
    expect((await route()).distanceM, isNull);
    await seedPoint(db, 2, 'one', reason: 'anchorReset');
    expect((await route()).status, DistanceStatus.unknown);
    expect((await route()).distanceM, isNull);
  });

  test('accepted measured route excludes rejected outlier and jitter from distance anchor', () async {
    await seedTrip(db, 'ride');
    await seedSegment(db, 'one', 'ride');
    await seedPoint(db, 1, 'one', reason: 'anchorReset');
    await seedPoint(
      db,
      2,
      'one',
      lat: 10,
      accepted: false,
      reason: 'lowAccuracy',
    );
    await seedPoint(db, 3, 'one', lat: 0.0005, reason: 'jitter');
    await seedPoint(db, 4, 'one', lat: 0.001);
    final result = await route();
    expect(result.pieces, hasLength(1));
    expect(result.pieces.single, hasLength(3));
    expect(result.distanceM, closeTo(111.2, 0.5));
    expect(result.status, DistanceStatus.partial);
  });

  test('full segment with two reliable fixes is measured', () async {
    await seedTrip(db, 'ride');
    await seedSegment(db, 'one', 'ride');
    await seedPoint(db, 1, 'one', reason: 'anchorReset');
    await seedPoint(db, 2, 'one', lat: 0.001);
    expect((await route()).status, DistanceStatus.measured);
  });

  test(
    'gap and new segment cannot connect or add cross-gap distance',
    () async {
      await seedTrip(db, 'ride');
      await seedSegment(db, 'first', 'ride', start: 1000);
      await seedSegment(db, 'gap', 'ride', type: SegmentType.gap, start: 3000);
      await seedSegment(db, 'last', 'ride', start: 4000);
      await seedPoint(db, 1, 'first', reason: 'anchorReset');
      await seedPoint(db, 2, 'first', lat: 0.001);
      await seedPoint(db, 3, 'last', lat: 5, reason: 'anchorReset');
      await seedPoint(db, 4, 'last', lat: 5.001);
      final result = await route();
      expect(result.pieces.map((p) => p.length), [2, 2]);
      expect(result.distanceM, closeTo(222.4, 1));
      expect(result.status, DistanceStatus.partial);
    },
  );

  test('anchor reset within segment splits pieces and marks partial', () async {
    await seedTrip(db, 'ride');
    await seedSegment(db, 'first', 'ride');
    await seedPoint(db, 1, 'first', reason: 'anchorReset');
    await seedPoint(db, 2, 'first', lat: 0.001);
    await seedPoint(db, 3, 'first', lat: 10, reason: 'anchorReset');
    await seedPoint(db, 4, 'first', lat: 10.001);
    final result = await route();
    expect(result.pieces.map((p) => p.length), [2, 2]);
    expect(result.distanceM, closeTo(222.4, 1));
    expect(result.status, DistanceStatus.partial);
  });

  test(
    'conservative rejection and unmeasurable segment cannot count as complete',
    () async {
      await seedTrip(db, 'ride');
      await seedSegment(db, 'first', 'ride', start: 1000);
      await seedSegment(db, 'empty', 'ride', start: 4000);
      await seedPoint(db, 1, 'first', reason: 'anchorReset');
      await seedPoint(db, 2, 'first', lat: 0.001);
      await seedPoint(
        db,
        3,
        'first',
        lat: 100,
        accepted: false,
        reason: 'impossibleSpeed',
      );
      await seedPoint(db, 4, 'first', lat: 0.002, reason: 'anchorReset');
      final result = await route();
      expect(result.pieces.map((p) => p.length), [2, 1]);
      expect(result.distanceM, closeTo(111.2, 0.5));
      expect(result.status, DistanceStatus.partial);
    },
  );
}
