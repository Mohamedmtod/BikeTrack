import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/shared/event_source.dart';
import '../../domain/trip/distance_status.dart';
import '../../domain/trip/segment_type.dart';
import '../../domain/trip/trip_status.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Events, Trips, Segments, GpsPoints, ActivitySamples, Bikes, Config],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'biketrack'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await customStatement('CREATE INDEX events_ts_utc ON events (ts_utc)');
      await customStatement(
        'CREATE INDEX events_processed ON events (processed)',
      );
      await customStatement(
        'CREATE INDEX gps_points_segment_id_ts_utc '
        'ON gps_points (segment_id, ts_utc)',
      );
      await customStatement(
        'CREATE INDEX segments_trip_id ON segments (trip_id)',
      );
      await customStatement('CREATE INDEX trips_status ON trips (status)');

      // Guard the raw event log even when code bypasses the repository.
      await customStatement('''
        CREATE TRIGGER events_no_delete BEFORE DELETE ON events
        BEGIN
          SELECT RAISE(ABORT, 'events cannot be deleted');
        END
      ''');
      await customStatement('''
        CREATE TRIGGER events_process_only BEFORE UPDATE ON events
        WHEN NOT (
          OLD.processed = 0 AND NEW.processed = 1
          AND NEW.id IS OLD.id
          AND NEW.ts_utc IS OLD.ts_utc
          AND NEW.source IS OLD.source
          AND NEW.type IS OLD.type
          AND NEW.payload IS OLD.payload
          AND NEW.trip_id IS OLD.trip_id
        )
        BEGIN
          SELECT RAISE(ABORT, 'only processing an event is allowed');
        END
      ''');
    },
  );
}
