import 'dart:async';
import 'dart:convert';

import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_event_ingestion.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recorder_test_fakes.dart';

void main() {
  late AppDatabase database;
  late FakeEventRepository repository;
  late RecorderBridge bridge;
  late RecorderRuntime runtime;
  late RecorderEventIngestion ingestion;
  var clock = 100;

  setUp(() {
    clock = 100;
    database = AppDatabase(NativeDatabase.memory());
    repository = FakeEventRepository(database);
    bridge = RecorderBridge(nativeApi: FakeNativeRecorderApi());
    runtime = RecorderRuntime();
    ingestion = RecorderEventIngestion(
      bridge,
      RawEventWriter(repository),
      runtime,
      () => clock++,
    );
  });
  tearDown(() async {
    await ingestion.dispose();
    await bridge.dispose();
    await database.close();
    runtime.dispose();
  });

  Future<List<StoredEvent>> events() async {
    await Future<void>.delayed(Duration.zero);
    await ingestion.drained;
    return (await repository.readRecent(100)).reversed.toList();
  }

  Future<int> repositoryAppend(NewEvent event) =>
      FakeEventRepository(database).append(event);

  test(
    'persists each GPS fix without changing its UTC time or received time',
    () async {
      for (var i = 0; i < 2; i++) {
        bridge.onRawFix(
          pigeon.NativeGpsFix(
            latitudeDeg: 30.0444,
            longitudeDeg: 31.2357,
            fixTsMs: 1720000000123,
            hAccuracyM: 4.5,
            recvMs: 1720000000456,
            rideId: null,
          ),
        );
      }
      final stored = await events();
      expect(stored, hasLength(2));
      for (final event in stored) {
        expect(event.source, EventSource.gps);
        expect(event.type, 'location');
        expect(event.tsUtc, 1720000000123);
        expect(event.tripId, isNull);
        expect(jsonDecode(event.payloadJson), {
          'latitudeDeg': 30.0444,
          'longitudeDeg': 31.2357,
          'fixTsMs': 1720000000123,
          'hAccuracyM': 4.5,
          'recvMs': 1720000000456,
          'rideId': null,
        });
      }
      expect(runtime.persistedCallbackCount, 2);
    },
  );

  test(
    'maps lifecycle, authorization and error callbacks with arrival clock',
    () async {
      bridge.onLocationUpdate(
        pigeon.RecorderLocationUpdate(started: true, rideId: 'ride-1'),
      );
      bridge.onAuthorizationChanged(
        pigeon.RecorderAuthorizationChange(authorization: 'always'),
      );
      bridge.onLocationError(
        pigeon.RecorderLocationError(
          code: 'network',
          message: 'Network unavailable',
          rideId: 'ride-1',
        ),
      );
      bridge.onLocationUpdate(
        pigeon.RecorderLocationUpdate(started: false, rideId: null),
      );
      final stored = await events();
      expect(stored.map((e) => e.tsUtc), [100, 101, 102, 103]);
      expect(stored.map((e) => e.source), everyElement(EventSource.system));
      expect(stored.map((e) => e.type), [
        'location_updates_started',
        'location_authorization_changed',
        'location_error',
        'location_updates_stopped',
      ]);
      expect(stored.map((e) => jsonDecode(e.payloadJson)), [
        {'started': true, 'rideId': 'ride-1'},
        {'authorization': 'always'},
        {
          'code': 'network',
          'message': 'Network unavailable',
          'rideId': 'ride-1',
        },
        {'started': false, 'rideId': null},
      ]);
      expect(runtime.activity, RecorderActivity.idle);
      expect(runtime.latestNativeError, contains('Network unavailable'));
      expect(runtime.persistedCallbackCount, 4);
    },
  );

  test(
    'serial queue keeps arrival order even with a delayed first write',
    () async {
      final gate = Completer<void>();
      final attempted = <String>[];
      var first = true;
      repository.onAppend = (event) async {
        attempted.add(event.type);
        if (first) {
          first = false;
          await gate.future;
        }
        return repositoryAppend(event);
      };
      bridge.onAuthorizationChanged(
        pigeon.RecorderAuthorizationChange(authorization: 'first'),
      );
      bridge.onLocationUpdate(
        pigeon.RecorderLocationUpdate(started: true, rideId: null),
      );
      bridge.onLocationError(
        pigeon.RecorderLocationError(code: 'third', message: 'third'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(attempted, ['location_authorization_changed']);
      gate.complete();
      expect((await events()).map((e) => e.type), [
        'location_authorization_changed',
        'location_updates_started',
        'location_error',
      ]);
      expect(attempted, [
        'location_authorization_changed',
        'location_updates_started',
        'location_error',
      ]);
    },
  );

  test(
    'failed callback write is visible and later callbacks continue',
    () async {
      var attempts = 0;
      repository.onAppend = (event) async {
        attempts++;
        if (attempts == 1) throw StateError('disk full');
        return repositoryAppend(event);
      };
      bridge.onRawFix(
        pigeon.NativeGpsFix(
          latitudeDeg: 1,
          longitudeDeg: 2,
          fixTsMs: 77,
          hAccuracyM: 3,
          recvMs: 90,
        ),
      );
      bridge.onAuthorizationChanged(
        pigeon.RecorderAuthorizationChange(authorization: 'denied'),
      );
      final stored = await events();
      expect(attempts, 2);
      expect(stored.map((e) => e.type), ['location_authorization_changed']);
      expect(runtime.latestPersistenceError, contains('disk full'));
      expect(runtime.persistedCallbackCount, 1);
    },
  );
}
