import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:biketrack/app/projection_drain_coordinator.dart';
import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/data/projection/event_projection_processor.dart';
import 'package:biketrack/data/projection/projection_id_generator.dart';
import 'package:biketrack/data/projection/projection_state_repository.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _Ids implements ProjectionIdGenerator {
  bool failSegment = false;
  int tripCount = 0;
  int segmentCount = 0;

  @override
  String nextTripId() => 'trip-${++tripCount}';

  @override
  String nextSegmentId() {
    if (failSegment) throw StateError('segment unavailable');
    return 'segment-${++segmentCount}';
  }
}

class _GatedProcessor implements ProjectionProcessor {
  _GatedProcessor(this.delegate, this.gate);

  final ProjectionProcessor delegate;
  final Future<void> gate;
  int active = 0;
  int peak = 0;
  int calls = 0;

  @override
  Future<bool> processNext() async {
    active++;
    if (active > peak) peak = active;
    calls++;
    try {
      if (calls == 1) await gate;
      return await delegate.processNext();
    } finally {
      active--;
    }
  }
}

void main() {
  late AppDatabase database;
  late EventRepository events;
  late RecorderRuntime runtime;
  late _Ids ids;
  late ProjectionDrainCoordinator coordinator;
  late RawEventWriter writer;

  void setupCoordinator({ProjectionProcessor? processor}) {
    coordinator = ProjectionDrainCoordinator(
      processor ?? EventProjectionProcessor(database, ids),
      events,
      runtime,
    );
    writer = RawEventWriter(events, onPersisted: coordinator.scheduleAutomatic);
  }

  Future<int> append(
    String type,
    int timestamp,
    Map<String, Object?> payload,
  ) => writer.append(
    NewEvent(
      tsUtc: timestamp,
      source: EventSource.system,
      type: type,
      payloadJson: jsonEncode(payload),
    ),
  );

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    events = EventRepository(database);
    runtime = RecorderRuntime();
    ids = _Ids();
    setupCoordinator();
  });
  tearDown(() async {
    await writer.drained;
    await coordinator.drained;
    await database.close();
    runtime.dispose();
  });

  test(
    'successful append returns while projection is still in flight',
    () async {
      final gate = Completer<void>();
      final gated = _GatedProcessor(
        EventProjectionProcessor(database, ids),
        gate.future,
      );
      setupCoordinator(processor: gated);

      final id = await append('unrelated', 100, {});
      expect(id, 1);
      await Future<void>.delayed(Duration.zero);
      expect(gated.active, 1);
      expect((await events.readRecent(1)).single.processed, isFalse);
      gate.complete();
      await coordinator.drained;
      expect((await events.readRecent(1)).single.processed, isTrue);
      expect(runtime.projectionState, ProjectionDrainState.idle);
    },
  );

  test('startup drain processes old events in insertion order, not timestamp order', () async {
    final first = await events.append(
      const NewEvent(
        tsUtc: 500,
        source: EventSource.user,
        type: 'user_start',
        payloadJson: '{"attemptId":"one"}',
      ),
    );
    final second = await events.append(
      const NewEvent(
        tsUtc: 100,
        source: EventSource.system,
        type: 'recorder_start_failed',
        payloadJson: '{"attemptId":"one"}',
      ),
    );
    final third = await events.append(
      const NewEvent(
        tsUtc: 200,
        source: EventSource.system,
        type: 'later',
        payloadJson: '{}',
      ),
    );

    coordinator.scheduleAutomatic();
    await coordinator.drained;
    expect([first, second, third], orderedEquals([1, 2, 3]));
    expect(
      (await events.readRecent(3)).map((e) => e.processed),
      everyElement(isTrue),
    );
    final snapshot = await ProjectionStateRepository(database).load();
    expect(snapshot.cursor, third);
    expect(snapshot.pendingManualStartAttemptId, isNull);
    expect(runtime.projectionState, ProjectionDrainState.idle);
  });

  test('reentrant schedules and concurrent arrivals share one real processor drain', () async {
    final gate = Completer<void>();
    final gated = _GatedProcessor(
      EventProjectionProcessor(database, ids),
      gate.future,
    );
    setupCoordinator(processor: gated);
    await append('one', 300, {});
    await Future<void>.delayed(Duration.zero);
    coordinator.scheduleAutomatic();
    coordinator.scheduleAutomatic();
    await Future.wait([append('two', 100, {}), append('three', 200, {})]);
    expect(gated.peak, 1);
    gate.complete();
    await coordinator.drained;
    expect(gated.peak, 1);
    expect((await events.readUnprocessed()), isEmpty);
    expect((await ProjectionStateRepository(database).load()).cursor, 3);
    expect(await database.select(database.trips).get(), isEmpty);
  });

  test(
    'a schedule during the idle transition is included in the same drain',
    () async {
      var schedules = 0;
      runtime.addListener(() {
        if (runtime.projectionState == ProjectionDrainState.idle &&
            schedules++ == 0) {
          coordinator.scheduleAutomatic();
        }
      });
      await append('one', 100, {});
      await coordinator.drained;
      expect(schedules, 2);
      expect((await events.readRecent(1)).single.processed, isTrue);
      expect(runtime.projectionState, ProjectionDrainState.idle);
    },
  );

  test('failed projection rolls back and blocks later events and automatic schedules', () async {
    ids.failSegment = true;
    await append('user_start', 100, {'attemptId': 'one'});
    await coordinator.drained;
    final blockingId = await append('recorder_start_confirmed', 101, {
      'attemptId': 'one',
      'rideId': 'native',
    });
    await coordinator.drained;
    expect(runtime.projectionState, ProjectionDrainState.blocked);
    expect(runtime.blockingProjectionEvent?.id, blockingId);
    expect(runtime.blockingProjectionEvent?.type, 'recorder_start_confirmed');
    expect(runtime.blockingProjectionEvent?.tsUtc, 101);
    expect(runtime.blockingProjectionEvent?.payloadJson, contains('native'));
    expect(runtime.latestProjectionError, contains('segment unavailable'));
    expect(runtime.latestPersistenceError, isNull);
    expect(await database.select(database.trips).get(), isEmpty);
    expect(await database.select(database.segments).get(), isEmpty);
    expect((await ProjectionStateRepository(database).load()).cursor, 1);

    final laterId = await append('later', 5, {});
    coordinator.scheduleAutomatic();
    await coordinator.drained;
    expect((await events.readUnprocessed()).map((e) => e.id), [
      blockingId,
      laterId,
    ]);
    expect(runtime.projectionState, ProjectionDrainState.blocked);

    ids.failSegment = false;
    await coordinator.retry();
    expect(runtime.projectionState, ProjectionDrainState.idle);
    expect(runtime.blockingProjectionEvent, isNull);
    expect(runtime.latestProjectionError, isNull);
    expect(await events.readUnprocessed(), isEmpty);
    expect((await ProjectionStateRepository(database).load()).cursor, laterId);
    expect(await database.select(database.trips).get(), hasLength(1));
    expect(await database.select(database.segments).get(), hasLength(1));
    await coordinator.retry();
    expect(await database.select(database.trips).get(), hasLength(1));
  });

  test(
    'new coordinator after reopening drains previously blocked raw events',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'biketrack-drain-',
      );
      final file = File('${directory.path}/events.sqlite');
      var reopened = AppDatabase(NativeDatabase(file));
      var reopenedRuntime = RecorderRuntime();
      try {
        var repository = EventRepository(reopened);
        await repository.append(
          const NewEvent(
            tsUtc: 100,
            source: EventSource.user,
            type: 'user_start',
            payloadJson: '{"attemptId":"one"}',
          ),
        );
        await repository.append(
          const NewEvent(
            tsUtc: 101,
            source: EventSource.system,
            type: 'recorder_start_confirmed',
            payloadJson: '{"attemptId":"one","rideId":"native"}',
          ),
        );
        final badIds = _Ids()..failSegment = true;
        var fresh = ProjectionDrainCoordinator(
          EventProjectionProcessor(reopened, badIds),
          repository,
          reopenedRuntime,
        );
        fresh.scheduleAutomatic();
        await fresh.drained;
        expect(reopenedRuntime.projectionState, ProjectionDrainState.blocked);
        expect((await repository.readUnprocessed()).map((e) => e.id), [2]);
        await reopened.close();
        reopenedRuntime.dispose();

        reopened = AppDatabase(NativeDatabase(file));
        reopenedRuntime = RecorderRuntime();
        repository = EventRepository(reopened);
        fresh = ProjectionDrainCoordinator(
          EventProjectionProcessor(reopened, _Ids()),
          repository,
          reopenedRuntime,
        );
        fresh.scheduleAutomatic();
        await fresh.drained;
        expect(reopenedRuntime.projectionState, ProjectionDrainState.idle);
        expect(await repository.readUnprocessed(), isEmpty);
        expect(await reopened.select(reopened.trips).get(), hasLength(1));
        expect(await reopened.select(reopened.segments).get(), hasLength(1));
        fresh.scheduleAutomatic();
        await fresh.drained;
        expect(await reopened.select(reopened.trips).get(), hasLength(1));
      } finally {
        await reopened.close();
        reopenedRuntime.dispose();
        await directory.delete(recursive: true);
      }
    },
  );
}
