import 'dart:io';

import 'package:biketrack/data/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test(
    'initializes schema version 3 with exactly the planned tables',
    () async {
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.read<int>('user_version'), 3);

      final tables = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''').get();
      expect(tables.map((row) => row.read<String>('name')), [
        'activity_samples',
        'bikes',
        'config',
        'diagnostic_entries',
        'events',
        'gps_points',
        'projection_states',
        'segments',
        'trips',
      ]);
    },
  );

  test('creates every planned column and index', () async {
    final columns = <String, List<String>>{
      'events': [
        'id',
        'ts_utc',
        'source',
        'type',
        'payload',
        'trip_id',
        'processed',
      ],
      'trips': [
        'trip_id',
        'status',
        'start_time_utc',
        'end_time_utc',
        'last_movement_utc',
        'bike_id',
        'nfc_confirmed',
        'total_distance_m',
        'distance_status',
        'moving_duration_s',
        'paused_duration_s',
        'suspended_duration_s',
        'review_reason',
        'created_at',
        'updated_at',
      ],
      'segments': [
        'segment_id',
        'trip_id',
        'type',
        'start_utc',
        'end_utc',
        'distance_m',
        'distance_status',
        'moving_s',
        'confidence',
        'classification_source',
        'user_corrected',
        'needs_review',
        'health_workout_uuid',
        'health_synced_at',
      ],
      'gps_points': [
        'id',
        'segment_id',
        'ts_utc',
        'lat',
        'lon',
        'altitude_m',
        'h_accuracy_m',
        'v_accuracy_m',
        'speed_mps',
        'speed_accuracy_mps',
        'course_deg',
        'accepted',
        'reject_reason',
      ],
      'activity_samples': [
        'ts_utc',
        'stationary',
        'walking',
        'running',
        'cycling',
        'automotive',
        'unknown',
        'confidence',
      ],
      'bikes': ['bike_id', 'name', 'nfc_payload', 'created_at'],
      'config': ['key', 'value'],
      'projection_states': ['id', 'snapshot_json'],
      'diagnostic_entries': [
        'id',
        'ts_utc',
        'category',
        'severity',
        'operation',
        'raw_event_id',
        'details',
      ],
    };
    for (final entry in columns.entries) {
      final rows = await database
          .customSelect('PRAGMA table_info(${entry.key})')
          .get();
      expect(
        rows.map((row) => row.read<String>('name')),
        entry.value,
        reason: entry.key,
      );
    }

    final indexes = await database.customSelect('''
      SELECT name, tbl_name FROM sqlite_master
      WHERE type = 'index' AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''').get();
    expect(
      {
        for (final row in indexes)
          row.read<String>('name'): row.read<String>('tbl_name'),
      },
      {
        'diagnostic_entries_ts_utc': 'diagnostic_entries',
        'diagnostic_entries_raw_event_id': 'diagnostic_entries',
        'events_ts_utc': 'events',
        'events_processed': 'events',
        'gps_points_segment_id_ts_utc': 'gps_points',
        'segments_trip_id': 'segments',
        'trips_status': 'trips',
      },
    );
    for (final (name, expected) in [
      ('diagnostic_entries_ts_utc', ['ts_utc']),
      ('diagnostic_entries_raw_event_id', ['raw_event_id']),
      ('events_ts_utc', ['ts_utc']),
      ('events_processed', ['processed']),
      ('gps_points_segment_id_ts_utc', ['segment_id', 'ts_utc']),
      ('segments_trip_id', ['trip_id']),
      ('trips_status', ['status']),
    ]) {
      final rows = await database
          .customSelect('PRAGMA index_info($name)')
          .get();
      expect(rows.map((row) => row.read<String>('name')), expected);
    }
  });

  test(
    'nullable schema fields accept NULL and other columns are required',
    () async {
      for (final (table, nullable) in [
        ('events', ['trip_id']),
        ('diagnostic_entries', ['raw_event_id']),
        (
          'trips',
          [
            'end_time_utc',
            'last_movement_utc',
            'bike_id',
            'total_distance_m',
            'review_reason',
          ],
        ),
        ('segments', ['distance_m', 'health_workout_uuid', 'health_synced_at']),
        (
          'gps_points',
          [
            'altitude_m',
            'v_accuracy_m',
            'speed_mps',
            'speed_accuracy_mps',
            'course_deg',
            'reject_reason',
          ],
        ),
        ('projection_states', <String>[]),
        ('activity_samples', <String>[]),
        ('bikes', <String>[]),
        ('config', <String>[]),
      ]) {
        final rows = await database
            .customSelect('PRAGMA table_info($table)')
            .get();
        for (final row in rows) {
          final name = row.read<String>('name');
          // SQLite treats a TEXT primary key as NOT NULL only when explicitly declared.
          if (row.read<int>('pk') != 0) continue;
          expect(
            row.read<int>('notnull') == 0,
            nullable.contains(name),
            reason: '$table.$name',
          );
        }
      }
    },
  );

  test(
    'stored enum values use stable names rather than ordinal positions',
    () async {
      await database.customInsert('''
      INSERT INTO events (ts_utc, source, type, payload, processed)
      VALUES (100, 'system', 'test', '{}', 0)
    ''');
      final row = await database
          .customSelect('SELECT source FROM events')
          .getSingle();
      expect(row.read<String>('source'), 'system');
    },
  );

  test(
    'migrates populated version 1 data to nullable GPS measurements',
    () async {
      final directory = await Directory.systemTemp.createTemp('biketrack-v1-');
      final file = File('${directory.path}/events.sqlite');
      try {
        final v2 = AppDatabase(NativeDatabase(file));
        await v2.customSelect('SELECT * FROM events').get();
        await v2.customInsert('''
        INSERT INTO trips (
          trip_id, status, start_time_utc, nfc_confirmed, total_distance_m,
          distance_status, moving_duration_s, paused_duration_s,
          suspended_duration_s, created_at, updated_at
        ) VALUES ('trip-v1', 'active', 1, 0, NULL, 'unknown', 0, 0, 0, 1, 1)
      ''');
        await v2.customInsert('''
        INSERT INTO segments (
          segment_id, trip_id, type, start_utc, end_utc, distance_m,
          distance_status, moving_s, confidence, classification_source,
          user_corrected, needs_review
        ) VALUES ('segment-v1', 'trip-v1', 'cycling', 1, 1, NULL, 'unknown',
          0, 1.0, 'user', 0, 0)
      ''');
        await v2.customInsert('''
        INSERT INTO events (ts_utc, source, type, payload, processed)
        VALUES (10, 'user', 'legacy', '{"value":1}', 0)
      ''');
        await v2.customInsert('''
        INSERT INTO gps_points (
          id, segment_id, ts_utc, lat, lon, altitude_m, h_accuracy_m,
          v_accuracy_m, speed_mps, speed_accuracy_mps, course_deg, accepted,
          reject_reason
        ) VALUES (7, 'segment-v1', 11, 30.0, 31.0, 9.0, 4.0, 5.0, 6.0, 7.0,
          8.0, 1, NULL)
      ''');
        await v2.customStatement('DROP TABLE diagnostic_entries');
        await v2.customStatement('DROP TABLE projection_states');
        await v2.customStatement('DROP INDEX gps_points_segment_id_ts_utc');
        await v2.customStatement(
          'ALTER TABLE gps_points RENAME TO gps_points_v2',
        );
        await v2.customStatement('''
        CREATE TABLE gps_points (
          id INTEGER NOT NULL PRIMARY KEY,
          segment_id TEXT NOT NULL REFERENCES segments (segment_id),
          ts_utc INTEGER NOT NULL,
          lat REAL NOT NULL,
          lon REAL NOT NULL,
          altitude_m REAL NOT NULL,
          h_accuracy_m REAL NOT NULL,
          v_accuracy_m REAL NOT NULL,
          speed_mps REAL NOT NULL,
          speed_accuracy_mps REAL NOT NULL,
          course_deg REAL NOT NULL,
          accepted INTEGER NOT NULL CHECK (accepted IN (0, 1)),
          reject_reason TEXT NULL
        )
      ''');
        await v2.customStatement(
          'INSERT INTO gps_points SELECT * FROM gps_points_v2',
        );
        await v2.customStatement('DROP TABLE gps_points_v2');
        await v2.customStatement(
          'CREATE INDEX gps_points_segment_id_ts_utc ON gps_points (segment_id, ts_utc)',
        );
        await v2.customStatement('PRAGMA user_version = 1');
        await v2.close();

        final migrated = AppDatabase(NativeDatabase(file));
        try {
          expect(
            (await migrated.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version'),
            3,
          );
          final event = await migrated
              .customSelect('SELECT * FROM events')
              .getSingle();
          expect(event.read<String>('type'), 'legacy');
          expect(event.read<String>('payload'), '{"value":1}');
          final point = await migrated
              .customSelect('SELECT * FROM gps_points WHERE id = 7')
              .getSingle();
          expect(point.read<double>('altitude_m'), 9.0);
          expect(point.read<double>('course_deg'), 8.0);
          await migrated.customInsert('''
          INSERT INTO gps_points (
            id, segment_id, ts_utc, lat, lon, altitude_m, h_accuracy_m,
            v_accuracy_m, speed_mps, speed_accuracy_mps, course_deg, accepted,
            reject_reason
          ) VALUES (8, 'segment-v1', 12, 30.1, 31.1, NULL, 4.0, NULL, NULL,
            NULL, NULL, 0, 'lowAccuracy')
        ''');
        } finally {
          await migrated.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'v2 to v3 migration preserves events, projections, trips, segments and GPS',
    () async {
      final directory = await Directory.systemTemp.createTemp('biketrack-v2-');
      final file = File('${directory.path}/events.sqlite');
      try {
        final old = AppDatabase(NativeDatabase(file));
        await old.customSelect('SELECT * FROM events').get();
        await old.customInsert('''
        INSERT INTO trips (
          trip_id, status, start_time_utc, nfc_confirmed, distance_status,
          moving_duration_s, paused_duration_s, suspended_duration_s,
          created_at, updated_at
        ) VALUES ('trip-v2', 'active', 1, 0, 'unknown', 0, 0, 0, 1, 1)
      ''');
        await old.customInsert('''
        INSERT INTO segments (
          segment_id, trip_id, type, start_utc, end_utc, distance_status,
          moving_s, confidence, classification_source, user_corrected, needs_review
        ) VALUES ('segment-v2', 'trip-v2', 'cycling', 1, 1, 'unknown', 0, 1, 'user', 0, 0)
      ''');
        await old.customInsert('''
        INSERT INTO gps_points (id, segment_id, ts_utc, lat, lon,
          h_accuracy_m, accepted)
        VALUES (7, 'segment-v2', 2, 30, 31, 4, 1)
      ''');
        await old.customInsert('''
        INSERT INTO events (ts_utc, source, type, payload, processed)
        VALUES (2, 'system', 'v2', '{"exact": true}', 0)
      ''');
        await old.customInsert('''
        INSERT INTO projection_states (id, snapshot_json) VALUES (1, '{"cursor":7}')
      ''');
        await old.customStatement('DROP TABLE diagnostic_entries');
        await old.customStatement('PRAGMA user_version = 2');
        await old.close();

        final upgraded = AppDatabase(NativeDatabase(file));
        try {
          expect(
            (await upgraded.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version'),
            3,
          );
          for (final (table, column, value) in [
            ('trips', 'trip_id', 'trip-v2'),
            ('segments', 'segment_id', 'segment-v2'),
            ('events', 'payload', '{"exact": true}'),
            ('projection_states', 'snapshot_json', '{"cursor":7}'),
          ]) {
            final row = await upgraded
                .customSelect('SELECT $column FROM $table')
                .getSingle();
            expect(row.read<String>(column), value);
          }
          final gps = await upgraded
              .customSelect('SELECT * FROM gps_points')
              .getSingle();
          expect(gps.read<int>('id'), 7);
          expect(gps.readNullable<double>('altitude_m'), isNull);
          expect(
            await upgraded.select(upgraded.diagnosticEntries).get(),
            isEmpty,
          );
          final indexes = await upgraded
              .customSelect(
                "SELECT name FROM sqlite_master WHERE type = 'index' AND name LIKE 'diagnostic_entries_%' ORDER BY name",
              )
              .get();
          expect(indexes.map((row) => row.read<String>('name')), [
            'diagnostic_entries_raw_event_id',
            'diagnostic_entries_ts_utc',
          ]);
        } finally {
          await upgraded.close();
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );

  test('schema and indexes survive opening a file-backed database', () async {
    final directory = await Directory.systemTemp.createTemp(
      'biketrack-db-test-',
    );
    final file = File('${directory.path}/events.sqlite');
    try {
      final first = AppDatabase(NativeDatabase(file));
      await first.customSelect('SELECT * FROM events').get();
      await first.close();
      final reopened = AppDatabase(NativeDatabase(file));
      try {
        expect(
          (await reopened.customSelect('PRAGMA user_version').getSingle())
              .read<int>('user_version'),
          3,
        );
        expect(
          await reopened
              .customSelect(
                'SELECT * FROM sqlite_master '
                "WHERE name = 'events_processed'",
              )
              .get(),
          hasLength(1),
        );
      } finally {
        await reopened.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
