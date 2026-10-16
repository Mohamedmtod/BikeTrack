import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/diagnostics/diagnostic_entry.dart';
import 'package:biketrack/data/diagnostics/diagnostic_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  NewDiagnosticEntry entry(int timestamp, {String json = '{"ok":true}'}) =>
      NewDiagnosticEntry(
        tsUtc: timestamp,
        category: 'native_recorder',
        severity: 'error',
        operation: 'start',
        detailsJson: json,
      );

  test('rejects malformed JSON, including direct SQL writes', () async {
    final repository = DiagnosticRepository(database);
    await expectLater(
      repository.append(entry(10, json: '{invalid'), nowUtcMs: 10),
      throwsFormatException,
    );
    await expectLater(
      database.customInsert('''
        INSERT INTO diagnostic_entries
          (ts_utc, category, severity, operation, details)
        VALUES (10, 'native', 'error', 'start', '{invalid')
      '''),
      throwsA(isA<Exception>()),
    );
    expect(await repository.readAll(), isEmpty);
  });

  test(
    'prunes by age first, then oldest insertion ID regardless of timestamps',
    () async {
      final repository = DiagnosticRepository(
        database,
        config: const DiagnosticsConfig(
          retention: Duration(milliseconds: 100),
          maxEntries: 2,
        ),
      );
      await database.customInsert('''
      INSERT INTO events (ts_utc, source, type, payload, processed)
      VALUES (1, 'system', 'evidence', '{}', 0)
    ''');
      await database.customInsert('''
      INSERT INTO trips (
        trip_id, status, start_time_utc, nfc_confirmed, distance_status,
        moving_duration_s, paused_duration_s, suspended_duration_s,
        created_at, updated_at
      ) VALUES ('trip', 'active', 1, 0, 'unknown', 0, 0, 0, 1, 1)
    ''');
      final agedId = await repository.append(entry(1), nowUtcMs: 1);
      final oldestId = await repository.append(entry(170), nowUtcMs: 170);
      final newerId = await repository.append(entry(110), nowUtcMs: 170);
      final latestId = await repository.append(entry(150), nowUtcMs: 170);
      expect([agedId, oldestId, newerId, latestId], [1, 2, 3, 4]);
      expect((await repository.readAll()).map((row) => row.id), [3, 4]);
      await repository.prune(nowUtcMs: 230);
      expect((await repository.readAll()).map((row) => row.id), [4]);
      expect(await database.select(database.events).get(), hasLength(1));
      expect(await database.select(database.trips).get(), hasLength(1));
    },
  );
}
