import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'event_record.dart';

class EventRepository {
  const EventRepository(this._database);

  final AppDatabase _database;

  Future<int> append(NewEvent event) async {
    if (event.type.isEmpty) {
      throw ArgumentError.value(event.type, 'type', 'Event type must not be empty');
    }
    try {
      jsonDecode(event.payloadJson);
    } on FormatException catch (error) {
      throw FormatException('Invalid event payload JSON: ${error.message}');
    }

    return _database.into(_database.events).insert(
      EventsCompanion.insert(
        tsUtc: event.tsUtc,
        source: event.source,
        type: event.type,
        payload: event.payloadJson,
        tripId: Value(event.tripId),
      ),
    );
  }

  Future<List<StoredEvent>> readUnprocessed() async {
    final rows = await (_database.select(_database.events)
          ..where((event) => event.processed.equals(false))
          ..orderBy([(event) => OrderingTerm.asc(event.id)]))
        .get();
    return [
      for (final row in rows)
        StoredEvent(
          id: row.id,
          tsUtc: row.tsUtc,
          source: row.source,
          type: row.type,
          payloadJson: row.payload,
          tripId: row.tripId,
          processed: row.processed,
        ),
    ];
  }

  Future<void> markProcessed(Iterable<int> ids) async {
    final selected = ids.toSet();
    if (selected.isEmpty) return;
    await (_database.update(_database.events)
          ..where(
            (event) =>
                event.id.isIn(selected) & event.processed.equals(false),
          ))
        .write(const EventsCompanion(processed: Value(true)));
  }
}
