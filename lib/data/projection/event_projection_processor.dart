import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/config/domain_config.dart';
import '../../domain/geo/geo_point.dart';
import '../../domain/gps/gps_filter.dart';
import '../../domain/gps/gps_sample.dart';
import '../../domain/trip/distance_status.dart';
import '../../domain/trip/trip_command.dart';
import '../../domain/trip/trip_event.dart';
import '../../domain/trip/trip_state_machine.dart';
import '../../domain/trip/trip_status.dart';
import '../database/app_database.dart';
import '../events/event_record.dart';
import 'projection_id_generator.dart';
import 'projection_snapshot.dart';

class EventProjectionProcessor {
  EventProjectionProcessor(
    this._database,
    this._idGenerator, {
    DomainConfig? config,
  }) : _config = config ?? DomainConfig();

  final AppDatabase _database;
  final ProjectionIdGenerator _idGenerator;
  final DomainConfig _config;

  Future<bool> processNext() async => _database.transaction(() async {
    final snapshot = await _loadSnapshot();
    final row =
        await (_database.select(_database.events)
              ..where(
                (event) =>
                    event.processed.equals(false) &
                    event.id.isBiggerThanValue(snapshot.cursor),
              )
              ..orderBy([(event) => OrderingTerm.asc(event.id)])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return false;

    final event = StoredEvent(
      id: row.id,
      tsUtc: row.tsUtc,
      source: row.source,
      type: row.type,
      payloadJson: row.payload,
      tripId: row.tripId,
      processed: row.processed,
    );
    final next = await _project(snapshot, event);
    await (_database.update(_database.events)
          ..where((item) => item.id.equals(event.id)))
        .write(const EventsCompanion(processed: Value(true)));
    await _saveSnapshot(next.copyWith(cursor: event.id));
    return true;
  });

  Future<void> processAll() async {
    while (await processNext()) {}
  }

  Future<ProjectionSnapshot> _loadSnapshot() async {
    final row = await (_database.select(
      _database.projectionStates,
    )..where((state) => state.id.equals(1))).getSingleOrNull();
    if (row == null) return const ProjectionSnapshot.initial();
    return ProjectionSnapshotCodec.decode(row.snapshotJson);
  }

  Future<void> _saveSnapshot(ProjectionSnapshot snapshot) => _database
      .into(_database.projectionStates)
      .insertOnConflictUpdate(
        ProjectionStatesCompanion.insert(
          id: const Value(1),
          snapshotJson: ProjectionSnapshotCodec.encode(snapshot),
        ),
      );

  Future<ProjectionSnapshot> _project(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) async {
    switch (event.type) {
      case 'user_start':
        return _onUserStart(snapshot, event);
      case 'recorder_start_confirmed':
        return _onStartConfirmed(snapshot, event);
      case 'recorder_start_failed':
        return _onStartFailed(snapshot, event);
      case 'user_stop':
        return _onUserStop(snapshot, event);
      case 'location':
        return _onLocation(snapshot, event);
      default:
        return snapshot;
    }
  }

  ProjectionSnapshot _onUserStart(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) {
    final payload = _payload(event);
    return snapshot.copyWith(
      pendingManualStartAttemptId: _requiredString(payload, 'attemptId'),
      pendingManualStartRequestedAtMs: event.tsUtc,
    );
  }

  Future<ProjectionSnapshot> _onStartConfirmed(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) async {
    final payload = _payload(event);
    final attemptId = _requiredString(payload, 'attemptId');
    if (snapshot.pendingManualStartAttemptId != attemptId ||
        snapshot.pendingManualStartRequestedAtMs == null ||
        event.tsUtc < snapshot.pendingManualStartRequestedAtMs! ||
        !snapshot.tripState.isIdle) {
      return snapshot;
    }
    final step = TripStateMachine.step(
      snapshot.tripState,
      UserStart(event.tsUtc),
      _config.trip,
    );
    final next = snapshot.copyWith(
      tripState: step.state,
      pendingManualStartAttemptId: null,
      pendingManualStartRequestedAtMs: null,
    );
    return _applyCommands(next, step.commands, event.tsUtc);
  }

  ProjectionSnapshot _onStartFailed(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) {
    final payload = _payload(event);
    final attemptId = _requiredString(payload, 'attemptId');
    if (snapshot.pendingManualStartAttemptId != attemptId) return snapshot;
    return snapshot.copyWith(
      pendingManualStartAttemptId: null,
      pendingManualStartRequestedAtMs: null,
    );
  }

  Future<ProjectionSnapshot> _onUserStop(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) async {
    if (snapshot.tripState.isIdle || snapshot.activeTripId == null) {
      return snapshot;
    }
    final step = TripStateMachine.step(
      snapshot.tripState,
      UserStop(event.tsUtc),
      _config.trip,
    );
    return _applyCommands(
      snapshot.copyWith(tripState: step.state),
      step.commands,
      event.tsUtc,
    );
  }

  Future<ProjectionSnapshot> _onLocation(
    ProjectionSnapshot snapshot,
    StoredEvent event,
  ) async {
    if (snapshot.activeSegmentId == null) return snapshot;
    final payload = _payload(event);
    final sample = GpsSample(
      tsMs: _int(payload, 'fixTsMs'),
      position: GeoPoint(
        _double(payload, 'latitudeDeg'),
        _double(payload, 'longitudeDeg'),
      ),
      hAccuracyM: _double(payload, 'hAccuracyM'),
    );
    final result = GpsFilter.step(
      snapshot.filterState,
      sample,
      nowMs: _int(payload, 'recvMs'),
      isStationary: false,
      cfg: _config.gps,
    );
    await _database
        .into(_database.gpsPoints)
        .insert(
          GpsPointsCompanion.insert(
            id: Value(event.id),
            segmentId: snapshot.activeSegmentId!,
            tsUtc: sample.tsMs,
            lat: sample.position.latDeg,
            lon: sample.position.lonDeg,
            hAccuracyM: sample.hAccuracyM,
            accepted: result.accepted,
            rejectReason: Value(result.reason?.name),
          ),
        );
    return snapshot.copyWith(filterState: result.newState);
  }

  Future<ProjectionSnapshot> _applyCommands(
    ProjectionSnapshot snapshot,
    Iterable<TripCommand> commands,
    int updatedAt,
  ) async {
    var next = snapshot;
    for (final command in commands) {
      if (command is ResetGpsAnchor) {
        next = next.copyWith(filterState: next.filterState.withAnchorCleared());
      } else if (command is OpenSegment) {
        next = await _openSegment(next, command, updatedAt);
      } else if (command is CloseSegment) {
        next = await _closeSegment(next, command);
      } else if (command is EndTrip) {
        next = await _endTrip(next, command, updatedAt);
      } else if (command is CancelTrip) {
        next = next.copyWith(
          activeTripId: null,
          activeSegmentId: null,
          filterState: next.filterState.withAnchorCleared(),
        );
      }
    }
    return next;
  }

  Future<ProjectionSnapshot> _openSegment(
    ProjectionSnapshot snapshot,
    OpenSegment command,
    int updatedAt,
  ) async {
    var next = snapshot;
    var tripId = next.activeTripId;
    if (tripId == null) {
      tripId = _idGenerator.nextTripId();
      await _database
          .into(_database.trips)
          .insert(
            TripsCompanion.insert(
              tripId: tripId,
              status: next.tripState.status ?? TripStatus.active,
              startTimeUtc: next.tripState.tripStartMs ?? command.startMs,
              nfcConfirmed: false,
              distanceStatus: DistanceStatus.unknown,
              movingDurationS: 0,
              pausedDurationS: 0,
              suspendedDurationS: 0,
              createdAt: updatedAt,
              updatedAt: updatedAt,
            ),
          );
      next = next.copyWith(activeTripId: tripId);
    }
    final segmentId = _idGenerator.nextSegmentId();
    await _database
        .into(_database.segments)
        .insert(
          SegmentsCompanion.insert(
            segmentId: segmentId,
            tripId: tripId,
            type: command.type,
            startUtc: command.startMs,
            endUtc: command.startMs,
            distanceStatus: DistanceStatus.unknown,
            movingS: 0,
            confidence: 1.0,
            classificationSource: 'user',
            userCorrected: false,
            needsReview: command.needsReview,
          ),
        );
    return next.copyWith(
      activeSegmentId: segmentId,
      filterState: next.filterState.withAnchorCleared(),
    );
  }

  Future<ProjectionSnapshot> _closeSegment(
    ProjectionSnapshot snapshot,
    CloseSegment command,
  ) async {
    final segmentId = snapshot.activeSegmentId;
    if (segmentId == null) return snapshot;
    await (_database.update(_database.segments)
          ..where((segment) => segment.segmentId.equals(segmentId)))
        .write(SegmentsCompanion(endUtc: Value(command.endMs)));
    return snapshot.copyWith(
      activeSegmentId: null,
      filterState: snapshot.filterState.withAnchorCleared(),
    );
  }

  Future<ProjectionSnapshot> _endTrip(
    ProjectionSnapshot snapshot,
    EndTrip command,
    int updatedAt,
  ) async {
    final tripId = snapshot.activeTripId;
    if (tripId != null) {
      await (_database.update(
        _database.trips,
      )..where((trip) => trip.tripId.equals(tripId))).write(
        TripsCompanion(
          status: Value(snapshot.tripState.status ?? TripStatus.completed),
          endTimeUtc: Value(command.endMs),
          lastMovementUtc: Value(snapshot.tripState.lastKnownMovementMs),
          updatedAt: Value(updatedAt),
        ),
      );
    }
    return snapshot.copyWith(
      activeTripId: null,
      activeSegmentId: null,
      filterState: snapshot.filterState.withAnchorCleared(),
    );
  }

  Map<String, Object?> _payload(StoredEvent event) {
    final decoded = jsonDecode(event.payloadJson);
    if (decoded is! Map) {
      throw FormatException('${event.type} payload must be an object');
    }
    return decoded.map<String, Object?>((key, value) {
      if (key is! String) {
        throw FormatException('${event.type} payload key must be a string');
      }
      return MapEntry(key, value);
    });
  }

  String _requiredString(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  int _int(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! int) throw FormatException('$key must be an integer');
    return value;
  }

  double _double(Map<String, Object?> payload, String key) {
    final value = payload[key];
    if (value is! num) throw FormatException('$key must be a number');
    return value.toDouble();
  }
}
