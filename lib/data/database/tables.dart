import 'package:drift/drift.dart';

import '../../domain/shared/event_source.dart';
import '../../domain/trip/distance_status.dart';
import '../../domain/trip/segment_type.dart';
import '../../domain/trip/trip_status.dart';

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tsUtc => integer()();
  TextColumn get source => textEnum<EventSource>()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get tripId => text().nullable()();
  BoolColumn get processed => boolean().withDefault(const Constant(false))();
}

class Trips extends Table {
  TextColumn get tripId => text()();
  TextColumn get status => textEnum<TripStatus>()();
  IntColumn get startTimeUtc => integer()();
  IntColumn get endTimeUtc => integer().nullable()();
  IntColumn get lastMovementUtc => integer().nullable()();
  TextColumn get bikeId => text().nullable()();
  BoolColumn get nfcConfirmed => boolean()();
  RealColumn get totalDistanceM => real().nullable()();
  TextColumn get distanceStatus => textEnum<DistanceStatus>()();
  IntColumn get movingDurationS => integer()();
  IntColumn get pausedDurationS => integer()();
  IntColumn get suspendedDurationS => integer()();
  TextColumn get reviewReason => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {tripId};
}

class Segments extends Table {
  TextColumn get segmentId => text()();
  TextColumn get tripId => text().references(Trips, #tripId)();
  TextColumn get type => textEnum<SegmentType>()();
  IntColumn get startUtc => integer()();
  IntColumn get endUtc => integer()();
  RealColumn get distanceM => real().nullable()();
  TextColumn get distanceStatus => textEnum<DistanceStatus>()();
  IntColumn get movingS => integer()();
  RealColumn get confidence => real()();
  TextColumn get classificationSource => text()();
  BoolColumn get userCorrected => boolean()();
  BoolColumn get needsReview => boolean()();
  TextColumn get healthWorkoutUuid => text().nullable()();
  IntColumn get healthSyncedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {segmentId};
}

class GpsPoints extends Table {
  IntColumn get id => integer()();
  TextColumn get segmentId => text().references(Segments, #segmentId)();
  IntColumn get tsUtc => integer()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  RealColumn get altitudeM => real().nullable()();
  RealColumn get hAccuracyM => real()();
  RealColumn get vAccuracyM => real().nullable()();
  RealColumn get speedMps => real().nullable()();
  RealColumn get speedAccuracyMps => real().nullable()();
  RealColumn get courseDeg => real().nullable()();
  BoolColumn get accepted => boolean()();
  TextColumn get rejectReason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class DiagnosticEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get tsUtc => integer()();
  TextColumn get category => text()();
  TextColumn get severity => text()();
  TextColumn get operation => text()();
  IntColumn get rawEventId => integer().nullable()();
  TextColumn get details =>
      text().customConstraint('NOT NULL CHECK (json_valid(details))')();
}

class ProjectionStates extends Table {
  IntColumn get id => integer()();
  TextColumn get snapshotJson => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class ActivitySamples extends Table {
  IntColumn get tsUtc => integer()();
  BoolColumn get stationary => boolean()();
  BoolColumn get walking => boolean()();
  BoolColumn get running => boolean()();
  BoolColumn get cycling => boolean()();
  BoolColumn get automotive => boolean()();
  BoolColumn get unknown => boolean()();
  IntColumn get confidence => integer()();

  @override
  Set<Column> get primaryKey => {tsUtc};
}

class Bikes extends Table {
  TextColumn get bikeId => text()();
  TextColumn get name => text()();
  TextColumn get nfcPayload => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {bikeId};
}

class Config extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
