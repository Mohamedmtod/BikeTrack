import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'diagnostic_entry.dart';

class DiagnosticRepository {
  const DiagnosticRepository(
    this._database, {
    this.config = const DiagnosticsConfig(),
  });

  final AppDatabase _database;
  final DiagnosticsConfig config;

  Future<int> append(NewDiagnosticEntry entry, {required int nowUtcMs}) async {
    for (final value in [entry.category, entry.severity, entry.operation]) {
      if (value.isEmpty) {
        throw ArgumentError('Diagnostic fields must not be empty');
      }
    }
    try {
      jsonDecode(entry.detailsJson);
    } on FormatException catch (error) {
      throw FormatException(
        'Invalid diagnostic details JSON: ${error.message}',
      );
    }

    return _database.transaction(() async {
      final id = await _database
          .into(_database.diagnosticEntries)
          .insert(
            DiagnosticEntriesCompanion.insert(
              tsUtc: entry.tsUtc,
              category: entry.category,
              severity: entry.severity,
              operation: entry.operation,
              rawEventId: Value(entry.rawEventId),
              details: entry.detailsJson,
            ),
          );
      await _prune(nowUtcMs);
      return id;
    });
  }

  Future<void> prune({required int nowUtcMs}) =>
      _database.transaction(() => _prune(nowUtcMs));

  Future<void> _prune(int nowUtcMs) async {
    await _database.customStatement(
      'DELETE FROM diagnostic_entries WHERE ts_utc < ?',
      [nowUtcMs - config.retention.inMilliseconds],
    );
    await _database.customStatement(
      '''
      DELETE FROM diagnostic_entries WHERE id IN (
        SELECT id FROM diagnostic_entries ORDER BY id ASC
        LIMIT (SELECT MAX((SELECT COUNT(*) FROM diagnostic_entries) - ?, 0))
      )
    ''',
      [config.maxEntries],
    );
  }

  Future<List<StoredDiagnosticEntry>> readAll() async {
    final rows = await (_database.select(
      _database.diagnosticEntries,
    )..orderBy([(entry) => OrderingTerm.asc(entry.id)])).get();
    return [
      for (final row in rows)
        StoredDiagnosticEntry(
          id: row.id,
          tsUtc: row.tsUtc,
          category: row.category,
          severity: row.severity,
          operation: row.operation,
          rawEventId: row.rawEventId,
          detailsJson: row.details,
        ),
    ];
  }
}
