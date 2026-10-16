import 'dart:async';

import 'package:biketrack/app/projection_drain_coordinator.dart';
import 'package:biketrack/app/recorder_event_ingestion.dart';
import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/app/recorder_session.dart';
import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/diagnostics/diagnostic_bundle_exporter.dart';
import 'package:biketrack/data/diagnostics/diagnostic_repository.dart';
import 'package:biketrack/data/projection/projection_state_repository.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/data/projection/event_projection_processor.dart';
import 'package:biketrack/data/projection/projection_id_generator.dart';
import 'package:biketrack/debug/recorder_debug_screen.dart';
import 'package:biketrack/data/trips/projected_trip_repository.dart';
import 'package:biketrack/ui/rides_screen.dart';
import 'package:biketrack/ui/ride_history_screen.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:biketrack/domain/trip/segment_type.dart';

import 'helpers/ride_fixture.dart';

import 'package:biketrack/domain/shared/event_source.dart';
import 'package:biketrack/main.dart' show disposeRecorderResources;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app/recorder_test_fakes.dart';

class _Ids implements ProjectionIdGenerator {
  @override
  String nextTripId() => 'trip-1';

  @override
  String nextSegmentId() => 'segment-1';
}

class _FailOnceProcessor implements ProjectionProcessor {
  _FailOnceProcessor(this.delegate);

  final ProjectionProcessor delegate;
  bool fail = true;

  @override
  Future<bool> processNext() {
    if (fail) throw StateError('projection unavailable');
    return delegate.processNext();
  }
}

class _StubExporter extends DiagnosticBundleExporter {
  _StubExporter(AppDatabase database, RecorderRuntime runtime)
    : super(
        events: EventRepository(database),
        diagnostics: DiagnosticRepository(database),
        projections: ProjectionStateRepository(database),
        runtime: runtime,
        documentsPath: () async => '/unused',
      );

  int calls = 0;
  Object? failure;

  @override
  Future<DiagnosticExportResult> export() async {
    calls++;
    if (failure case final error?) throw error;
    return const DiagnosticExportResult('/app/Documents/report.json', 123);
  }
}

void main() {
  test(
    'resource disposal waits for native start and its durable confirmation',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = FakeEventRepository(database);
      final native = PendingNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: native);
      final runtime = RecorderRuntime();
      final projections = ProjectionDrainCoordinator(
        EventProjectionProcessor(database, _Ids()),
        repository,
        runtime,
      );
      final writer = RawEventWriter(
        repository,
        onPersisted: projections.scheduleAutomatic,
      );
      final ingestion = RecorderEventIngestion(
        bridge,
        writer,
        runtime,
        () => 1000,
      );
      final session = RecorderSession(bridge, writer, runtime, () => 1000);
      final nativeStart = Completer<pigeon.RecorderStartResult>();
      final writingConfirmation = Completer<void>();
      final persistConfirmation = Completer<void>();
      final confirmationPersisted = Completer<void>();
      native.startCompletion = nativeStart;
      repository.onAppend = (event) async {
        if (event.type == 'recorder_start_confirmed') {
          writingConfirmation.complete();
          await persistConfirmation.future;
          final id = await FakeEventRepository(database).append(event);
          expect((await repository.readRecent(1)).single.type, event.type);
          confirmationPersisted.complete();
          return id;
        }
        return FakeEventRepository(database).append(event);
      };

      final started = session.startManual('dispose-pending');
      await native.startCalled.future;
      var disposed = false;
      final disposal = disposeRecorderResources(
        ingestion: ingestion,
        session: session,
        writer: writer,
        projections: projections,
        bridge: bridge,
        database: database,
        runtime: runtime,
      ).then((_) => disposed = true);
      expect(disposed, isFalse);
      nativeStart.complete(
        pigeon.RecorderStartResult(started: true, rideId: 'ride-1'),
      );
      await writingConfirmation.future;
      expect(disposed, isFalse);
      expect((await repository.readRecent(10)).single.type, 'user_start');
      persistConfirmation.complete();
      await confirmationPersisted.future;
      expect((await started).started, isTrue);
      await disposal;
      expect(disposed, isTrue);
      expect(native.calls, ['start:user:dispose-pending']);
    },
  );

  testWidgets(
    'debug console displays status, errors, recent events and manual controls',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = EventRepository(database);
      final native = FakeNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: native);
      final runtime = RecorderRuntime();
      final projections = ProjectionDrainCoordinator(
        EventProjectionProcessor(database, _Ids()),
        repository,
        runtime,
      );
      final session = RecorderSession(
        bridge,
        RawEventWriter(repository),
        runtime,
        () => 1000,
      );
      addTearDown(() async {
        await projections.drained;
        await bridge.dispose();
        await database.close();
        runtime.dispose();
      });
      await repository.append(
        const NewEvent(
          tsUtc: 42,
          source: EventSource.gps,
          type: 'location',
          tripId: 'ride-7',
          payloadJson: '{"recvMs":57}',
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: RecorderDebugScreen(
            session: session,
            runtime: runtime,
            repository: repository,
            projections: projections,
            exporter: _StubExporter(database, runtime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recorder: idle'), findsOneWidget);
      expect(find.text('Projections: idle'), findsOneWidget);
      expect(find.text('Persisted callbacks: 0'), findsOneWidget);
      expect(find.text('#1 / gps / location / 42 / pending'), findsOneWidget);
      expect(find.text('Trip: ride-7\n{"recvMs":57}'), findsOneWidget);

      runtime.persistenceFailed('user_stop', StateError('disk full'));
      runtime.nativeFailed('stop', StateError('native failure'));
      runtime.callbackPersisted();
      await tester.pump();
      expect(
        find.textContaining('Persistence error: user_stop:'),
        findsOneWidget,
      );
      expect(find.textContaining('Native error: stop:'), findsOneWidget);
      expect(find.text('Persisted callbacks: 1'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'manual-1');
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(native.calls, ['start:user:manual-1']);
      expect(find.text('Recorder: recording'), findsOneWidget);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(native.calls, ['start:user:manual-1', 'stop']);
      expect(find.text('Recorder: idle'), findsOneWidget);

      await repository.append(
        const NewEvent(
          tsUtc: 99,
          source: EventSource.system,
          type: 'fresh',
          payloadJson: '{}',
        ),
      );
      await tester.tap(find.byTooltip('Refresh events'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('#5 / system / fresh / 99 / pending'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('#5 / system / fresh / 99 / pending'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'manual export warns before action and reports path, size and errors',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = EventRepository(database);
      final native = FakeNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: native);
      final runtime = RecorderRuntime();
      final projections = ProjectionDrainCoordinator(
        EventProjectionProcessor(database, _Ids()),
        repository,
        runtime,
      );
      final session = RecorderSession(
        bridge,
        RawEventWriter(repository),
        runtime,
        () => 1000,
      );
      addTearDown(() async {
        await bridge.dispose();
        await database.close();
        runtime.dispose();
      });
      final exporter = _StubExporter(database, runtime);
      await tester.pumpWidget(
        MaterialApp(
          home: RecorderDebugScreen(
            session: session,
            runtime: runtime,
            repository: repository,
            projections: projections,
            exporter: exporter,
          ),
        ),
      );
      await tester.pumpAndSettle();
      const warning =
          'This diagnostic bundle may contain GPS coordinates, route history, timestamps, ride identifiers, and error details. Review where you save or share it.';
      expect(find.text(warning), findsOneWidget);
      expect(exporter.calls, 0);
      await tester.ensureVisible(find.text('Export diagnostics to Files'));
      await tester.tap(find.text('Export diagnostics to Files'));
      await tester.pumpAndSettle();
      expect(exporter.calls, 1);
      expect(
        find.textContaining(
          'Exported to /app/Documents/report.json (123 bytes)',
        ),
        findsOneWidget,
      );
      exporter.failure = StateError('no space');
      await tester.tap(find.text('Export diagnostics to Files'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Export error: Bad state: no space'),
        findsOneWidget,
      );
      expect(exporter.calls, 2);
      expect(native.calls, isEmpty);
    },
  );

  test(
    'generated Pigeon Documents path resolves at the Dart channel boundary',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel =
          'dev.flutter.pigeon.biketrack.RecorderHostApi.documentsDirectoryPath';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockDecodedMessageHandler(
        BasicMessageChannel<Object?>(
          channel,
          pigeon.RecorderHostApi.pigeonChannelCodec,
        ),
        (message) async {
          expect(message, isNull);
          return <Object?>['/app/Documents'];
        },
      );
      addTearDown(
        () => messenger.setMockDecodedMessageHandler(
          BasicMessageChannel<Object?>(
            channel,
            pigeon.RecorderHostApi.pigeonChannelCodec,
          ),
          null,
        ),
      );
      expect(
        await pigeon.RecorderHostApi().documentsDirectoryPath(),
        '/app/Documents',
      );
    },
  );

  testWidgets(
    'shows processed and pending events and retries only from debug',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = EventRepository(database);
      final native = FakeNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: native);
      final runtime = RecorderRuntime();
      final processor = _FailOnceProcessor(
        EventProjectionProcessor(database, _Ids()),
      );
      final projections = ProjectionDrainCoordinator(
        processor,
        repository,
        runtime,
      );
      final session = RecorderSession(
        bridge,
        RawEventWriter(repository),
        runtime,
        () => 1000,
      );
      addTearDown(() async {
        await projections.drained;
        await bridge.dispose();
        await database.close();
        runtime.dispose();
      });
      await repository.append(
        const NewEvent(
          tsUtc: 100,
          source: EventSource.system,
          type: 'processed-first',
          payloadJson: '{}',
        ),
      );
      processor.fail = false;
      projections.scheduleAutomatic();
      await projections.drained;
      processor.fail = true;
      await repository.append(
        const NewEvent(
          tsUtc: 50,
          source: EventSource.system,
          type: 'blocked-second',
          payloadJson: '{"detail":"pending"}',
        ),
      );
      projections.scheduleAutomatic();
      await projections.drained;

      await tester.pumpWidget(
        MaterialApp(
          home: RecorderDebugScreen(
            session: session,
            runtime: runtime,
            repository: repository,
            projections: projections,
            exporter: _StubExporter(database, runtime),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Projections: blocked'), findsOneWidget);
      expect(
        find.text('#1 / system / processed-first / 100 / processed'),
        findsOneWidget,
      );
      expect(
        find.text('#2 / system / blocked-second / 50 / pending'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Blocking event: #2 / blocked-second / 50'),
        findsOneWidget,
      );
      expect(find.textContaining('"detail":"pending"'), findsWidgets);
      expect(
        find.textContaining(
          'Projection error: Bad state: projection unavailable',
        ),
        findsOneWidget,
      );
      expect(find.text('Retry projections'), findsOneWidget);

      processor.fail = false;
      await tester.tap(find.text('Retry projections'));
      await tester.pumpAndSettle();
      expect(find.text('Projections: idle'), findsOneWidget);
      expect(
        find.text('#2 / system / blocked-second / 50 / processed'),
        findsOneWidget,
      );
      expect(find.text('Retry projections'), findsNothing);
      expect((await repository.readUnprocessed()), isEmpty);
      expect(native.calls, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('home shows only projected GPS, then updates after drain', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final events = EventRepository(database);
    final bridge = RecorderBridge(nativeApi: FakeNativeRecorderApi());
    final runtime = RecorderRuntime();
    final projections = ProjectionDrainCoordinator(
      EventProjectionProcessor(database, _Ids()),
      events,
      runtime,
    );
    final session = RecorderSession(
      bridge,
      RawEventWriter(events, onPersisted: projections.scheduleAutomatic),
      runtime,
      () => 1000,
    );
    addTearDown(() async {
      await projections.drained;
      await bridge.dispose();
      await database.close();
      runtime.dispose();
    });
    await tester.pumpWidget(
      MaterialApp(
        home: RidesScreen(
          session: session,
          runtime: runtime,
          trips: ProjectedTripRepository(database),
          events: events,
          projections: projections,
          exporter: _StubExporter(database, runtime),
          clock: () => DateTime.fromMillisecondsSinceEpoch(12000),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Start Ride'), findsOneWidget);
    expect(find.text('Distance unknown'), findsOneWidget);
    await tester.tap(find.text('Start Ride'));
    await projections.drained;
    await tester.pumpAndSettle();
    expect(find.text('Stop Ride'), findsOneWidget);
    expect(find.text('Distance unknown'), findsOneWidget);
    await events.append(
      const NewEvent(
        tsUtc: 1000,
        source: EventSource.gps,
        type: 'location',
        payloadJson: '{"latitudeDeg":0.0,"longitudeDeg":0.0,"fixTsMs":1000,"hAccuracyM":1.0,"recvMs":1000}',
      ),
    );
    await events.append(
      const NewEvent(
        tsUtc: 11000,
        source: EventSource.gps,
        type: 'location',
        payloadJson: '{"latitudeDeg":0.001,"longitudeDeg":0.0,"fixTsMs":11000,"hAccuracyM":1.0,"recvMs":11000}',
      ),
    );
    runtime.callbackPersisted();
    await tester.pumpAndSettle();
    expect(find.text('Distance unknown'), findsOneWidget);
    projections.scheduleAutomatic();
    await projections.drained;
    await tester.pumpAndSettle();
    expect(find.text('0.11 km (measured)'), findsOneWidget);
    expect(find.text('Reliability: measured'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('history and detail show derived distance, reliability and gap', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() => db.close());
    await seedTrip(
      db,
      'ride',
      status: TripStatus.needsReview,
      start: 1000,
      end: 5000,
    );
    await seedSegment(db, 'first', 'ride', start: 1000, end: 2000);
    await seedSegment(
      db,
      'gap',
      'ride',
      type: SegmentType.gap,
      start: 2000,
      end: 5000,
    );
    await seedPoint(db, 1, 'first', reason: 'anchorReset');
    await seedPoint(db, 2, 'first', lat: 0.001);
    await tester.pumpWidget(
      MaterialApp(home: RideHistoryScreen(trips: ProjectedTripRepository(db))),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('0.11 km (partial)'), findsOneWidget);
    expect(find.textContaining('Reliability: partial'), findsOneWidget);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
    expect(find.text('Ride detail'), findsOneWidget);
    expect(find.text('Status: needsReview'), findsOneWidget);
    expect(find.text('0.11 km (partial)'), findsOneWidget);
    expect(find.text('Reliability: partial'), findsOneWidget);
    expect(find.text('GPS gap'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
