import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/app/recorder_session.dart';
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/debug/recorder_debug_screen.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app/recorder_test_fakes.dart';

void main() {
  testWidgets(
    'debug console displays status, errors, recent events and manual controls',
    (tester) async {
      final database = AppDatabase(NativeDatabase.memory());
      final repository = EventRepository(database);
      final native = FakeNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: native);
      final runtime = RecorderRuntime();
      final session = RecorderSession(bridge, repository, runtime, () => 1000);
      addTearDown(() async {
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
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Recorder: idle'), findsOneWidget);
      expect(find.text('Persisted callbacks: 0'), findsOneWidget);
      expect(find.text('gps / location / 42'), findsOneWidget);
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
      expect(find.text('system / fresh / 99'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
