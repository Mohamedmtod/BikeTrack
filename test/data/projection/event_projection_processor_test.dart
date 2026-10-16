import 'dart:convert';
import 'dart:io';

import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/data/projection/event_projection_processor.dart';
import 'package:biketrack/data/projection/projection_id_generator.dart';
import 'package:biketrack/data/projection/projection_state_repository.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ids implements ProjectionIdGenerator {
  _Ids({this.throwOnSegment = false});

  final bool throwOnSegment;
  var _trip = 0;
  var _segment = 0;

  @override
  String nextSegmentId() {
    if (throwOnSegment) throw StateError('segment insert failure');
    return 'segment-${++_segment}';
  }

  @override
  String nextTripId() => 'trip-${++_trip}';
}

void main() {
  late AppDatabase database;
  late EventRepository events;
  late ProjectionStateRepository snapshots;
  late EventProjectionProcessor processor;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    events = EventRepository(database);
    snapshots = ProjectionStateRepository(database);
    processor = EventProjectionProcessor(database, _Ids());
  });
  tearDown(() => database.close());

  Future<void> append(
    String type,
    int timestamp,
    Map<String, Object?> payload, {
    EventSource source = EventSource.system,
  }) => events.append(
    NewEvent(
      tsUtc: timestamp,
      source: source,
      type: type,
      payloadJson: jsonEncode(payload),
    ),
  );

  Future<void> startConfirmed({
    String attemptId = 'attempt',
    int at = 100,
  }) async {
    await append('user_start', at, {
      'attemptId': attemptId,
    }, source: EventSource.user);
    await append('recorder_start_confirmed', at + 1, {
      'attemptId': attemptId,
      'rideId': 'native-ride',
    });
  }

  test('user_start alone creates no trip', () async {
    await append('user_start', 100, {
      'attemptId': 'attempt',
    }, source: EventSource.user);

    await processor.processAll();

    expect(await database.select(database.trips).get(), isEmpty);
    final snapshot = await snapshots.load();
    expect(snapshot.pendingManualStartAttemptId, 'attempt');
    expect(snapshot.pendingManualStartRequestedAtMs, 100);
  });

  test(
    'matching confirmation creates exactly one cycling trip and segment',
    () async {
      await startConfirmed();

      await processor.processAll();
      await processor.processAll();

      final trips = await database.select(database.trips).get();
      final segments = await database.select(database.segments).get();
      expect(trips, hasLength(1));
      expect(trips.single.tripId, 'trip-1');
      expect(trips.single.totalDistanceM, isNull);
      expect(trips.single.distanceStatus.name, 'unknown');
      expect(segments, hasLength(1));
      expect(segments.single.segmentId, 'segment-1');
      expect(segments.single.type.name, 'cycling');
      expect(segments.single.distanceM, isNull);
      expect(segments.single.distanceStatus.name, 'unknown');
      expect(segments.single.classificationSource, 'user');
      expect(segments.single.confidence, 1.0);
      final snapshot = await snapshots.load();
      expect(snapshot.pendingManualStartAttemptId, isNull);
      expect(snapshot.activeTripId, 'trip-1');
      expect(snapshot.activeSegmentId, 'segment-1');
    },
  );

  test('start failures, duplicates, unmatched, and stale confirmations create no trip', () async {
    await append('user_start', 100, {
      'attemptId': 'first',
    }, source: EventSource.user);
    await append('recorder_start_failed', 101, {
      'attemptId': 'first',
      'reason': 'denied',
    });
    await append('recorder_start_confirmed', 102, {
      'attemptId': 'first',
      'rideId': 'ride',
    });
    await append('recorder_start_confirmed', 103, {
      'attemptId': 'other',
      'rideId': 'ride',
    });
    await append('user_start', 200, {
      'attemptId': 'second',
    }, source: EventSource.user);
    await append('recorder_start_confirmed', 199, {
      'attemptId': 'second',
      'rideId': 'ride',
    });

    await processor.processAll();

    expect(await database.select(database.trips).get(), isEmpty);
    expect((await snapshots.load()).pendingManualStartAttemptId, 'second');
  });

  test(
    'processes insertion IDs rather than timestamps and is idempotent',
    () async {
      final first = await events.append(
        const NewEvent(
          tsUtc: 300,
          source: EventSource.system,
          type: 'unknown-first',
          payloadJson: '{}',
        ),
      );
      final second = await events.append(
        const NewEvent(
          tsUtc: 100,
          source: EventSource.system,
          type: 'unknown-second',
          payloadJson: '{}',
        ),
      );

      expect(await processor.processNext(), isTrue);
      expect((await snapshots.load()).cursor, first);
      expect(await processor.processNext(), isTrue);
      expect((await snapshots.load()).cursor, second);
      expect(await processor.processNext(), isFalse);
      await processor.processAll();
      expect(await database.select(database.trips).get(), isEmpty);
      expect(await database.select(database.segments).get(), isEmpty);
    },
  );

  test(
    'a projection failure rolls back derived writes and processing state',
    () async {
      final failing = EventProjectionProcessor(
        database,
        _Ids(throwOnSegment: true),
      );
      await startConfirmed();

      expect(failing.processAll, throwsStateError);

      final stored = await events.readUnprocessed();
      expect(stored.map((event) => event.type), ['recorder_start_confirmed']);
      expect(await database.select(database.trips).get(), isEmpty);
      expect(await database.select(database.segments).get(), isEmpty);
      expect(await database.select(database.gpsPoints).get(), isEmpty);
      final snapshot = await snapshots.load();
      expect(snapshot.cursor, 1);
      expect(snapshot.pendingManualStartAttemptId, 'attempt');
    },
  );

  test(
    'reopens after a cursor without duplicating trips, segments, or GPS rows',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'biketrack-projection-',
      );
      final file = File('${directory.path}/projection.sqlite');
      var restartDatabase = AppDatabase(NativeDatabase(file));
      try {
        var restartEvents = EventRepository(restartDatabase);
        var restartProcessor = EventProjectionProcessor(
          restartDatabase,
          _Ids(),
        );
        await restartEvents.append(
          const NewEvent(
            tsUtc: 100,
            source: EventSource.user,
            type: 'user_start',
            payloadJson: '{"attemptId":"attempt"}',
          ),
        );
        await restartEvents.append(
          const NewEvent(
            tsUtc: 101,
            source: EventSource.system,
            type: 'recorder_start_confirmed',
            payloadJson: '{"attemptId":"attempt","rideId":"native-ride"}',
          ),
        );
        await restartProcessor.processAll();
        await restartDatabase.close();

        restartDatabase = AppDatabase(NativeDatabase(file));
        restartEvents = EventRepository(restartDatabase);
        restartProcessor = EventProjectionProcessor(restartDatabase, _Ids());
        await restartEvents.append(
          const NewEvent(
            tsUtc: 110,
            source: EventSource.gps,
            type: 'location',
            payloadJson: '{"latitudeDeg":30.0,"longitudeDeg":31.0,"fixTsMs":105,"hAccuracyM":4.0,"recvMs":110,"rideId":"native-ride"}',
          ),
        );
        await restartProcessor.processAll();
        await restartProcessor.processAll();

        expect(
          await restartDatabase.select(restartDatabase.trips).get(),
          hasLength(1),
        );
        expect(
          await restartDatabase.select(restartDatabase.segments).get(),
          hasLength(1),
        );
        final points = await restartDatabase
            .select(restartDatabase.gpsPoints)
            .get();
        expect(points, hasLength(1));
        expect(points.single.accepted, isTrue);
        expect(points.single.rejectReason, 'anchorReset');
      } finally {
        await restartDatabase.close();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'projects accepted and rejected locations with raw nullable measurements',
    () async {
      await startConfirmed();
      await append('location', 999999, {
        'latitudeDeg': 30.0,
        'longitudeDeg': 31.0,
        'fixTsMs': 105,
        'hAccuracyM': 4.0,
        'recvMs': 110,
        'rideId': 'native-ride',
      }, source: EventSource.gps);
      await append('location', 120, {
        'latitudeDeg': 30.1,
        'longitudeDeg': 31.1,
        'fixTsMs': 115,
        'hAccuracyM': 30.0,
        'recvMs': 120,
        'rideId': 'native-ride',
      }, source: EventSource.gps);

      await processor.processAll();

      final points = await (database.select(
        database.gpsPoints,
      )..orderBy([(point) => OrderingTerm.asc(point.id)])).get();
      expect(points, hasLength(2));
      expect(points.first.accepted, isTrue);
      expect(points.first.tsUtc, 105);
      expect(points.first.lat, 30.0);
      expect(points.first.lon, 31.0);
      expect(points.first.hAccuracyM, 4.0);
      expect(points.first.altitudeM, isNull);
      expect(points.first.vAccuracyM, isNull);
      expect(points.first.speedMps, isNull);
      expect(points.first.speedAccuracyMps, isNull);
      expect(points.first.courseDeg, isNull);
      expect(points.last.accepted, isFalse);
      expect(points.last.rejectReason, 'lowAccuracy');
    },
  );

  test(
    'location without an active segment remains processed raw evidence only',
    () async {
      await append('location', 110, {
        'latitudeDeg': 30.0,
        'longitudeDeg': 31.0,
        'fixTsMs': 105,
        'hAccuracyM': 4.0,
        'recvMs': 110,
      }, source: EventSource.gps);

      await processor.processAll();

      expect(await database.select(database.gpsPoints).get(), isEmpty);
      expect(await events.readUnprocessed(), isEmpty);
    },
  );

  test(
    'user_stop closes only a projected trip without platform commands',
    () async {
      await startConfirmed();
      await append('user_stop', 200, {}, source: EventSource.user);

      await processor.processAll();

      final trip = (await database.select(database.trips).get()).single;
      final segment = (await database.select(database.segments).get()).single;
      expect(trip.status.name, 'completed');
      expect(trip.endTimeUtc, 200);
      expect(segment.endUtc, 200);
      final snapshot = await snapshots.load();
      expect(snapshot.activeTripId, isNull);
      expect(snapshot.activeSegmentId, isNull);
    },
  );
}
