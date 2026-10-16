import 'package:biketrack/app/projection_drain_coordinator.dart';
import 'package:biketrack/app/raw_event_writer.dart';
import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/app/recorder_session.dart';
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/data/projection/event_projection_processor.dart';
import 'package:biketrack/data/projection/projection_id_generator.dart';
import 'package:biketrack/debug/recorder_debug_screen.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

void main() {
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
}
