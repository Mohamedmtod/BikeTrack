import 'dart:async';

import 'package:biketrack/app/diagnostics_coordinator.dart';
import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/diagnostics/diagnostic_entry.dart';
import 'package:biketrack/data/diagnostics/diagnostic_repository.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FailingDiagnostics extends DiagnosticRepository {
  _FailingDiagnostics(super.database);
  int calls = 0;
  final gate = Completer<void>();

  @override
  Future<int> append(NewDiagnosticEntry entry, {required int nowUtcMs}) async {
    calls++;
    await gate.future;
    throw StateError('diagnostic disk full');
  }
}

void main() {
  late AppDatabase database;
  setUp(() => database = AppDatabase(NativeDatabase.memory()));
  tearDown(() => database.close());

  test('one narrow integration records only reported failures', () async {
    final repository = DiagnosticRepository(database);
    final coordinator = DiagnosticsCoordinator(repository, clockMs: () => 1000);
    coordinator.rawWriteFailed(
      const NewEvent(
        tsUtc: 10,
        source: EventSource.user,
        type: 'user_stop',
        payloadJson: '{}',
      ),
      StateError('write'),
    );
    coordinator.nativeFailed('start rejected', 'denied');
    coordinator.projectionFailed(
      const StoredEvent(
        id: 19,
        tsUtc: 10,
        source: EventSource.user,
        type: 'user_start',
        payloadJson: '{}',
        tripId: null,
        processed: false,
      ),
      StateError('projection'),
    );
    await coordinator.drained;
    final entries = await repository.readAll();
    expect(entries.map((e) => e.category), [
      'raw_event_write',
      'native_recorder',
      'projection_drain',
    ]);
    expect(entries.map((e) => e.operation), [
      'user_stop',
      'start rejected',
      'process_next',
    ]);
    expect(entries.every((e) => e.severity == 'error'), isTrue);
    expect(entries.map((e) => e.rawEventId), [null, null, 19]);
    expect(entries.every((e) => e.tsUtc == 1000), isTrue);
  });

  test(
    'diagnostic storage failure is unawaited, swallowed and never recurses',
    () async {
      final repository = _FailingDiagnostics(database);
      final coordinator = DiagnosticsCoordinator(
        repository,
        clockMs: () => 1000,
      );
      coordinator.nativeFailed('stop', StateError('original native error'));
      await Future<void>.delayed(Duration.zero);
      expect(repository.calls, 1);
      repository.gate.complete();
      await coordinator.drained;
      expect(repository.calls, 1);
      expect(await database.select(database.diagnosticEntries).get(), isEmpty);
    },
  );
}
