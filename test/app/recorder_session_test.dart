import 'dart:async';
import 'dart:convert';

import 'package:biketrack/app/diagnostics_coordinator.dart';
import 'package:biketrack/data/diagnostics/diagnostic_repository.dart';
import 'package:biketrack/app/projection_drain_coordinator.dart';
import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/app/recorder_session.dart';
import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/projection/event_projection_processor.dart';
import 'package:biketrack/data/projection/projection_id_generator.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder_test_fakes.dart';

class _FailingIds implements ProjectionIdGenerator {
  @override
  String nextTripId() => 'trip-1';

  @override
  String nextSegmentId() => throw StateError('projection failed');
}

void main() {
  late AppDatabase database;
  late FakeEventRepository repository;
  late PendingNativeRecorderApi native;
  late RecorderBridge bridge;
  late RecorderRuntime runtime;
  late RecorderSession session;
  late DiagnosticsCoordinator diagnostics;
  late DiagnosticRepository diagnosticRepository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = FakeEventRepository(database);
    native = PendingNativeRecorderApi();
    bridge = RecorderBridge(nativeApi: native);
    diagnosticRepository = DiagnosticRepository(database);
    diagnostics = DiagnosticsCoordinator(
      diagnosticRepository,
      clockMs: () => 98765,
    );
    runtime = RecorderRuntime(diagnostics: diagnostics);
    session = RecorderSession(
      bridge,
      RawEventWriter(repository, diagnostics: diagnostics),
      runtime,
      () => 98765,
    );
  });
  tearDown(() async {
    await diagnostics.drained;
    await bridge.dispose();
    await database.close();
    runtime.dispose();
  });

  test(
    'manual start writes raw intent before asking bridge to start',
    () async {
      repository.onAppend = (event) async {
        if (event.type == 'user_start') expect(native.calls, isEmpty);
        return FakeEventRepository(database).append(event);
      };
      final result = await session.startManual('explicit-id');
      expect(result.started, isTrue);
      expect(native.calls, ['start:user:explicit-id']);
      final stored = (await repository.readRecent(10)).reversed.toList();
      expect(stored.map((event) => event.type), [
        'user_start',
        'recorder_start_confirmed',
      ]);
      expect(stored.first.tsUtc, 98765);
      expect(stored.first.source, EventSource.user);
      expect(jsonDecode(stored.first.payloadJson), {
        'attemptId': 'explicit-id',
      });
      expect(stored.last.source, EventSource.system);
      expect(jsonDecode(stored.last.payloadJson), {
        'attemptId': 'explicit-id',
        'rideId': 'ride-1',
      });
      expect(runtime.activity, RecorderActivity.recording);
    },
  );

  test('failed user_start append prevents native start', () async {
    repository.onAppend = (_) async => throw StateError('start write failed');
    await expectLater(session.startManual('id'), throwsStateError);
    expect(native.calls, isEmpty);
    expect(
      runtime.latestPersistenceError,
      contains('user_start: Bad state: start write failed'),
    );
    expect(runtime.activity, RecorderActivity.idle);
  });

  test('user_stop is written before native stop', () async {
    repository.onAppend = (event) async {
      expect(native.calls, isEmpty);
      return FakeEventRepository(database).append(event);
    };
    await session.stopManual();
    expect(native.calls, ['stop']);
    final stored = (await repository.readRecent(10)).single;
    expect(stored.type, 'user_stop');
    expect(stored.source, EventSource.user);
    expect(stored.tsUtc, 98765);
    expect(jsonDecode(stored.payloadJson), isEmpty);
    expect(runtime.activity, RecorderActivity.idle);
  });

  test(
    'failed user_stop write still calls native stop and exposes failure',
    () async {
      repository.onAppend = (_) async => throw StateError('stop write failed');
      await expectLater(session.stopManual(), throwsStateError);
      expect(native.calls, ['stop']);
      expect(
        runtime.latestPersistenceError,
        contains('user_stop: Bad state: stop write failed'),
      );
      expect(runtime.activity, RecorderActivity.idle);
    },
  );

  test('native start exception and rejected start are visible', () async {
    native.startError = StateError('native start failed');
    await expectLater(session.startManual('id-1'), throwsStateError);
    expect(runtime.latestNativeError, contains('native start failed'));
    expect(runtime.activity, RecorderActivity.idle);
    native.startError = null;
    native.startResult = pigeon.RecorderStartResult(
      started: false,
      reason: 'not authorized',
    );
    final rejected = await session.startManual('id-2');
    expect(rejected.started, isFalse);
    expect(runtime.latestNativeError, contains('not authorized'));
    expect(runtime.activity, RecorderActivity.idle);
    expect((await repository.readRecent(10)).length, 3);
  });

  test(
    'start-result persistence failures remain visible in runtime state',
    () async {
      repository.onAppend = (event) async {
        if (event.type == 'recorder_start_confirmed') {
          throw StateError('confirmation write failed');
        }
        return FakeEventRepository(database).append(event);
      };

      await expectLater(session.startManual('confirmed'), throwsStateError);
      expect(
        runtime.latestPersistenceError,
        contains(
          'recorder_start_confirmed: Bad state: confirmation write failed',
        ),
      );
      expect(runtime.activity, RecorderActivity.recording);

      native.startResult = pigeon.RecorderStartResult(
        started: false,
        reason: 'denied',
      );
      repository.onAppend = (event) async {
        if (event.type == 'recorder_start_failed') {
          throw StateError('failure write failed');
        }
        return FakeEventRepository(database).append(event);
      };
      await expectLater(session.startManual('failed'), throwsStateError);
      expect(
        runtime.latestPersistenceError,
        contains('recorder_start_failed: Bad state: failure write failed'),
      );
      expect(runtime.activity, RecorderActivity.idle);
    },
  );

  test(
    'projection failure does not stop native start, stop, or raw writes',
    () async {
      final projections = ProjectionDrainCoordinator(
        EventProjectionProcessor(database, _FailingIds()),
        repository,
        runtime,
      );
      final connectedSession = RecorderSession(
        bridge,
        RawEventWriter(repository, onPersisted: projections.scheduleAutomatic),
        runtime,
        () => 98765,
      );

      final started = await connectedSession.startManual('attempt');
      expect(started.started, isTrue);
      await projections.drained;
      expect(runtime.projectionState, ProjectionDrainState.blocked);
      expect(runtime.blockingProjectionEvent?.type, 'recorder_start_confirmed');
      expect(runtime.latestProjectionError, contains('projection failed'));
      expect(runtime.latestPersistenceError, isNull);
      await connectedSession.stopManual();
      expect(native.calls, ['start:user:attempt', 'stop']);
      expect((await repository.readRecent(3)).map((e) => e.type), [
        'user_stop',
        'recorder_start_confirmed',
        'user_start',
      ]);
      expect((await repository.readUnprocessed()).map((e) => e.type), [
        'recorder_start_confirmed',
        'user_stop',
      ]);
    },
  );

  test('native stop failure surfaces alongside a failed stop write', () async {
    repository.onAppend = (_) async => throw StateError('disk full');
    native.stopError = StateError('native stop failed');
    await expectLater(session.stopManual(), throwsStateError);
    expect(native.calls, ['stop']);
    expect(runtime.latestPersistenceError, contains('disk full'));
    expect(runtime.latestNativeError, contains('native stop failed'));
    expect(runtime.activity, RecorderActivity.stopping);
  });

  test(
    'each native failure and raw write failure records exactly one diagnostic',
    () async {
      repository.onAppend = (event) async {
        if (event.type == 'user_stop') throw StateError('stop write failed');
        return FakeEventRepository(database).append(event);
      };
      native.startError = StateError('start exception');
      await expectLater(session.startManual('a'), throwsStateError);
      native.startError = null;
      native.startResult = pigeon.RecorderStartResult(
        started: false,
        reason: 'denied',
      );
      expect((await session.startManual('b')).started, isFalse);
      native.stopError = StateError('stop exception');
      await expectLater(session.stopManual(), throwsStateError);
      await diagnostics.drained;
      final entries = await diagnosticRepository.readAll();
      expect(entries.map((entry) => '${entry.category}:${entry.operation}'), [
        'native_recorder:start',
        'native_recorder:start rejected',
        'raw_event_write:user_stop',
        'native_recorder:stop',
      ]);
    },
  );

  test(
    'drained waits for native start and confirmed event persistence',
    () async {
      final nativeStart = Completer<pigeon.RecorderStartResult>();
      final writingConfirmation = Completer<void>();
      final persistConfirmation = Completer<void>();
      native.startCompletion = nativeStart;
      repository.onAppend = (event) async {
        if (event.type == 'recorder_start_confirmed') {
          writingConfirmation.complete();
          await persistConfirmation.future;
        }
        return FakeEventRepository(database).append(event);
      };

      final started = session.startManual('pending');
      await native.startCalled.future;
      var disposed = false;
      final disposalBarrier = session.drained.then((_) => disposed = true);
      expect(disposed, isFalse);

      nativeStart.complete(
        pigeon.RecorderStartResult(started: true, rideId: 'ride-1'),
      );
      await writingConfirmation.future;
      expect(disposed, isFalse);
      persistConfirmation.complete();
      expect((await started).started, isTrue);
      await disposalBarrier;
      expect(disposed, isTrue);
      expect((await repository.readRecent(10)).map((event) => event.type), [
        'recorder_start_confirmed',
        'user_start',
      ]);
    },
  );

  test('drained waits for rejected start failure event persistence', () async {
    final nativeStart = Completer<pigeon.RecorderStartResult>();
    final writingFailure = Completer<void>();
    final persistFailure = Completer<void>();
    native.startCompletion = nativeStart;
    repository.onAppend = (event) async {
      if (event.type == 'recorder_start_failed') {
        writingFailure.complete();
        await persistFailure.future;
      }
      return FakeEventRepository(database).append(event);
    };

    final started = session.startManual('rejected');
    await native.startCalled.future;
    var disposed = false;
    final disposalBarrier = session.drained.then((_) => disposed = true);
    nativeStart.complete(
      pigeon.RecorderStartResult(started: false, reason: 'denied'),
    );
    await writingFailure.future;
    expect(disposed, isFalse);
    persistFailure.complete();
    expect((await started).started, isFalse);
    await disposalBarrier;
    expect(disposed, isTrue);
    expect((await repository.readRecent(10)).map((event) => event.type), [
      'recorder_start_failed',
      'user_start',
    ]);
  });

  test('drained includes pending native stop', () async {
    final nativeStop = Completer<void>();
    native.stopCompletion = nativeStop;
    final stopped = session.stopManual();
    await native.stopCalled.future;
    var disposed = false;
    final disposalBarrier = session.drained.then((_) => disposed = true);
    expect(disposed, isFalse);
    expect((await repository.readRecent(10)).single.type, 'user_stop');
    nativeStop.complete();
    await stopped;
    await disposalBarrier;
    expect(disposed, isTrue);
  });

  test(
    'a throwing operation keeps its caller error but not the barrier',
    () async {
      final nativeStart = Completer<pigeon.RecorderStartResult>();
      native.startCompletion = nativeStart;
      final started = session.startManual('throws');
      final caller = expectLater(started, throwsStateError);
      await native.startCalled.future;
      final disposalBarrier = session.drained;
      nativeStart.completeError(StateError('native start failed'));
      await caller;
      await disposalBarrier;
      await session.stopManual();
      await session.drained;
      expect(native.calls, ['start:user:throws', 'stop']);
      expect(runtime.latestNativeError, contains('native start failed'));
    },
  );
}
