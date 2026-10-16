import 'dart:convert';
import 'dart:io';

import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/diagnostics/diagnostic_bundle_exporter.dart';
import 'package:biketrack/data/diagnostics/diagnostic_entry.dart';
import 'package:biketrack/data/diagnostics/diagnostic_repository.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/data/projection/projection_state_repository.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late AppDatabase database;
  late EventRepository events;
  late DiagnosticRepository diagnostics;
  late RecorderRuntime runtime;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('biketrack-export-');
    database = AppDatabase(NativeDatabase.memory());
    events = EventRepository(database);
    diagnostics = DiagnosticRepository(database);
    runtime = RecorderRuntime();
  });
  tearDown(() async {
    runtime.dispose();
    await database.close();
    await directory.delete(recursive: true);
  });

  DiagnosticBundleExporter exporter({
    DiagnosticsConfig config = const DiagnosticsConfig(),
    Future<String> Function()? path,
  }) => DiagnosticBundleExporter(
    events: events,
    diagnostics: diagnostics,
    projections: ProjectionStateRepository(database),
    runtime: runtime,
    documentsPath: path ?? () async => directory.path,
    config: config,
    platformMetadata: const {'operating_system': 'test'},
    now: () => DateTime.utc(2026, 10, 16),
  );

  test('preserves raw JSON strings, orders insertion IDs, includes available state', () async {
    const payload = '{  "latitudeDeg" : 30.0, "n":1.00 }';
    await events.append(
      const NewEvent(
        tsUtc: 500,
        source: EventSource.gps,
        type: 'location',
        payloadJson: payload,
      ),
    );
    await events.append(
      const NewEvent(
        tsUtc: 100,
        source: EventSource.system,
        type: 'later',
        payloadJson: '{}',
      ),
    );
    await diagnostics.append(
      const NewDiagnosticEntry(
        tsUtc: 900,
        category: 'native_recorder',
        severity: 'error',
        operation: 'start',
        detailsJson: '{"error":"bad"}',
      ),
      nowUtcMs: 900,
    );
    await diagnostics.append(
      const NewDiagnosticEntry(
        tsUtc: 800,
        category: 'raw_event_write',
        severity: 'error',
        operation: 'user_stop',
        rawEventId: 2,
        detailsJson: '{}',
      ),
      nowUtcMs: 900,
    );
    await database.customInsert('''
      INSERT INTO projection_states (id, snapshot_json)
      VALUES (1, '{"cursor":1}')
    ''');
    runtime.projectionFailed(
      const StoredEvent(
        id: 2,
        tsUtc: 100,
        source: EventSource.system,
        type: 'later',
        payloadJson: '{}',
        tripId: null,
        processed: false,
      ),
      StateError('blocked'),
    );

    final result = await exporter().export();
    final contents = await File(result.path).readAsString();
    final bundle = jsonDecode(contents) as Map<String, dynamic>;
    expect(result.byteSize, utf8.encode(contents).length);
    expect(bundle['manifest'], {
      'format_version': 1,
      'generated_at_utc': '2026-10-16T00:00:00.000Z',
      'platform': {'operating_system': 'test'},
    });
    final raw = bundle['raw_events'] as List<dynamic>;
    expect(raw.map((row) => row['id']), [1, 2]);
    expect(raw.map((row) => row['ts_utc']), [500, 100]);
    expect(raw.first['payloadJson'], payload);
    expect(raw.first['payloadJson'], isA<String>());
    expect((bundle['diagnostic_entries'] as List).map((row) => row['id']), [
      1,
      2,
    ]);
    expect(bundle['projection_snapshot'], {'cursor': 1});
    expect(bundle['projection_runtime'], {
      'state': 'blocked',
      'blocking_event_id': 2,
      'error': 'Bad state: blocked',
    });
  });

  test(
    'oversize bundle writes no file and never requests destination',
    () async {
      await events.append(
        const NewEvent(
          tsUtc: 1,
          source: EventSource.gps,
          type: 'location',
          payloadJson: '{"coordinates":"30.012345,31.012345"}',
        ),
      );
      var pathCalls = 0;
      await expectLater(
        exporter(
          config: const DiagnosticsConfig(maxBundleBytes: 20),
          path: () async {
            pathCalls++;
            return directory.path;
          },
        ).export(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('no file was written'),
          ),
        ),
      );
      expect(pathCalls, 0);
      expect(await directory.list().toList(), isEmpty);
    },
  );
}
