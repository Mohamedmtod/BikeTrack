import 'dart:io';

import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';
import 'package:biketrack/domain/shared/event_source.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late EventRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = EventRepository(database);
  });
  tearDown(() => database.close());

  test('append preserves all fields including null trip ID and raw JSON text', () async {
    const payload = '{ "raw": [1, 2], "extra": {"nested": true} }';
    final id = await repository.append(const NewEvent(
      tsUtc: 1730000000123,
      source: EventSource.motion,
      type: 'activity_changed',
      payloadJson: payload,
    ));
    final stored = (await repository.readUnprocessed()).single;
    expect(stored.id, id);
    expect(stored.tsUtc, 1730000000123);
    expect(stored.source, EventSource.motion);
    expect(stored.type, 'activity_changed');
    expect(stored.payloadJson, payload);
    expect(stored.tripId, isNull);
    expect(stored.processed, isFalse);

    final row = await database.customSelect('SELECT * FROM events').getSingle();
    expect(row.read<String>('source'), 'motion');
    expect(row.read<int>('ts_utc'), 1730000000123);
    expect(row.read<String>('payload'), payload);
    expect(row.data['trip_id'], isNull);
  });

  test('rejects malformed JSON without appending an event', () async {
    await expectLater(
      repository.append(const NewEvent(
        tsUtc: 1,
        source: EventSource.gps,
        type: 'location',
        payloadJson: '{"broken":}',
      )),
      throwsA(isA<FormatException>().having(
        (error) => error.message, 'message', contains('Invalid event payload JSON'),
      )),
    );
    expect(await repository.readUnprocessed(), isEmpty);
  });

  test('preserves valid JSON scalar and trip association', () async {
    await repository.append(const NewEvent(
      tsUtc: 42,
      source: EventSource.user,
      type: 'user_start',
      payloadJson: 'null',
      tripId: 'trip-1',
    ));
    final stored = (await repository.readUnprocessed()).single;
    expect(stored.payloadJson, 'null');
    expect(stored.tripId, 'trip-1');
  });

  test('returns unprocessed events in insertion order, not timestamp order', () async {
    final ids = <int>[];
    for (final timestamp in [300, 100, 200]) {
      ids.add(await repository.append(NewEvent(
        tsUtc: timestamp,
        source: EventSource.system,
        type: 'tick',
        payloadJson: '{"ts":$timestamp}',
      )));
    }
    expect((await repository.readUnprocessed()).map((e) => e.id), ids);
    expect((await repository.readUnprocessed()).map((e) => e.tsUtc), [300, 100, 200]);
  });

  test('marking selected events changes only their processed flag', () async {
    final first = await repository.append(const NewEvent(
      tsUtc: 1,
      source: EventSource.gps,
      type: 'location',
      payloadJson: '{"fix":1}',
    ));
    final second = await repository.append(const NewEvent(
      tsUtc: 2,
      source: EventSource.nfc,
      type: 'nfc_scan',
      payloadJson: '{"tag":"abc"}',
      tripId: 'ride-2',
    ));
    final third = await repository.append(const NewEvent(
      tsUtc: 3,
      source: EventSource.health,
      type: 'health',
      payloadJson: '{"count":0}',
    ));
    final before = await database.customSelect('SELECT * FROM events ORDER BY id').get();
    await repository.markProcessed([second, third, second, -1]);
    await repository.markProcessed([second]);
    await repository.markProcessed([]);
    expect((await repository.readUnprocessed()).map((e) => e.id), [first]);
    final after = await database.customSelect('SELECT * FROM events ORDER BY id').get();
    for (var i = 0; i < before.length; i++) {
      final old = Map<String, Object?>.of(before[i].data)..remove('processed');
      final current = Map<String, Object?>.of(after[i].data)..remove('processed');
      expect(current, old);
    }
    expect(after.map((row) => row.read<int>('processed')), [0, 1, 1]);
  });

  test('database rejects raw event updates, re-processing, and deletion', () async {
    final id = await repository.append(const NewEvent(
      tsUtc: 8,
      source: EventSource.system,
      type: 'launch',
      payloadJson: '{"original":true}',
    ));
    await expectLater(
      database.customUpdate('UPDATE events SET payload = ? WHERE id = ?',
          variables: [Variable.withString('{}'), Variable.withInt(id)]),
      throwsA(isA<Exception>()),
    );
    await repository.markProcessed([id]);
    await expectLater(
      database.customUpdate('UPDATE events SET processed = 0 WHERE id = ?',
          variables: [Variable.withInt(id)]),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.customUpdate('UPDATE events SET ts_utc = 9 WHERE id = ?',
          variables: [Variable.withInt(id)]),
      throwsA(isA<Exception>()),
    );
    await expectLater(
      database.customStatement('DELETE FROM events WHERE id = ?', [id]),
      throwsA(isA<Exception>()),
    );
    final row = await database.customSelect('SELECT * FROM events').getSingle();
    expect(row.read<String>('payload'), '{"original":true}');
    expect(row.read<int>('ts_utc'), 8);
    expect(row.read<int>('processed'), 1);
  });

  test('events and processed state persist across database reopen', () async {
    final directory = await Directory.systemTemp.createTemp('biketrack-events-');
    final file = File('${directory.path}/events.sqlite');
    try {
      final original = AppDatabase(NativeDatabase(file));
      final writer = EventRepository(original);
      final processedId = await writer.append(const NewEvent(
        tsUtc: 10,
        source: EventSource.user,
        type: 'start',
        payloadJson: '{"one":1}',
      ));
      final pendingId = await writer.append(const NewEvent(
        tsUtc: 5,
        source: EventSource.gps,
        type: 'fix',
        payloadJson: '{ "raw": true }',
        tripId: 'ride-1',
      ));
      await writer.markProcessed([processedId]);
      await original.close();

      final reopened = AppDatabase(NativeDatabase(file));
      try {
        final pending = (await EventRepository(reopened).readUnprocessed()).single;
        expect(pending.id, pendingId);
        expect(pending.tsUtc, 5);
        expect(pending.source, EventSource.gps);
        expect(pending.type, 'fix');
        expect(pending.payloadJson, '{ "raw": true }');
        expect(pending.tripId, 'ride-1');
        final done = await reopened.customSelect(
          'SELECT processed FROM events WHERE id = ?',
          variables: [Variable.withInt(processedId)],
        ).getSingle();
        expect(done.read<int>('processed'), 1);
      } finally {
        await reopened.close();
      }
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
