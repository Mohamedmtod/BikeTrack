import 'dart:convert';

import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/app/recorder_session.dart';
import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder_test_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeEventRepository repository;
  late FakeNativeRecorderApi native;
  late RecorderBridge bridge;
  late RecorderRuntime runtime;
  late RecorderSession session;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = FakeEventRepository(database);
    native = FakeNativeRecorderApi();
    bridge = RecorderBridge(nativeApi: native);
    runtime = RecorderRuntime();
    session = RecorderSession(
      bridge,
      RawEventWriter(repository),
      runtime,
      () => 98765,
    );
  });
  tearDown(() async {
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

  test('native stop failure surfaces alongside a failed stop write', () async {
    repository.onAppend = (_) async => throw StateError('disk full');
    native.stopError = StateError('native stop failed');
    await expectLater(session.stopManual(), throwsStateError);
    expect(native.calls, ['stop']);
    expect(runtime.latestPersistenceError, contains('disk full'));
    expect(runtime.latestNativeError, contains('native stop failed'));
    expect(runtime.activity, RecorderActivity.stopping);
  });
}
