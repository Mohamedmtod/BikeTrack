import 'dart:convert';

import '../../domain/activity/activity_type.dart';
import '../../domain/geo/geo_point.dart';
import '../../domain/gps/filter_state.dart';
import '../../domain/gps/gps_sample.dart';
import '../../domain/trip/segment_type.dart';
import '../../domain/trip/trip_close_reason.dart';
import '../../domain/trip/trip_state.dart';
import '../../domain/trip/trip_status.dart';

class ProjectionSnapshot {
  const ProjectionSnapshot({
    required this.cursor,
    required this.filterState,
    required this.tripState,
    this.activeTripId,
    this.activeSegmentId,
    this.pendingManualStartAttemptId,
    this.pendingManualStartRequestedAtMs,
  });

  const ProjectionSnapshot.initial()
    : cursor = 0,
      filterState = const FilterState(),
      tripState = const TripState.idle(),
      activeTripId = null,
      activeSegmentId = null,
      pendingManualStartAttemptId = null,
      pendingManualStartRequestedAtMs = null;

  final int cursor;
  final FilterState filterState;
  final TripState tripState;
  final String? activeTripId;
  final String? activeSegmentId;
  final String? pendingManualStartAttemptId;
  final int? pendingManualStartRequestedAtMs;

  ProjectionSnapshot copyWith({
    int? cursor,
    FilterState? filterState,
    TripState? tripState,
    Object? activeTripId = _keep,
    Object? activeSegmentId = _keep,
    Object? pendingManualStartAttemptId = _keep,
    Object? pendingManualStartRequestedAtMs = _keep,
  }) => ProjectionSnapshot(
    cursor: cursor ?? this.cursor,
    filterState: filterState ?? this.filterState,
    tripState: tripState ?? this.tripState,
    activeTripId: activeTripId == _keep
        ? this.activeTripId
        : activeTripId as String?,
    activeSegmentId: activeSegmentId == _keep
        ? this.activeSegmentId
        : activeSegmentId as String?,
    pendingManualStartAttemptId: pendingManualStartAttemptId == _keep
        ? this.pendingManualStartAttemptId
        : pendingManualStartAttemptId as String?,
    pendingManualStartRequestedAtMs: pendingManualStartRequestedAtMs == _keep
        ? this.pendingManualStartRequestedAtMs
        : pendingManualStartRequestedAtMs as int?,
  );
}

const Object _keep = Object();

abstract final class ProjectionSnapshotCodec {
  static const int version = 1;

  static String encode(ProjectionSnapshot snapshot) =>
      jsonEncode(_toJson(snapshot));

  static ProjectionSnapshot decode(String encoded) {
    final decoded = jsonDecode(encoded);
    return _fromJson(_map(decoded, 'snapshot'));
  }

  static Map<String, Object?> _toJson(ProjectionSnapshot snapshot) => {
    'version': version,
    'cursor': snapshot.cursor,
    'filterState': _filterStateToJson(snapshot.filterState),
    'tripState': _tripStateToJson(snapshot.tripState),
    'activeTripId': snapshot.activeTripId,
    'activeSegmentId': snapshot.activeSegmentId,
    'pendingManualStartAttemptId': snapshot.pendingManualStartAttemptId,
    'pendingManualStartRequestedAtMs': snapshot.pendingManualStartRequestedAtMs,
  };

  static ProjectionSnapshot _fromJson(Map<String, Object?> json) {
    final snapshotVersion = _int(json['version'], 'version');
    if (snapshotVersion != version) {
      throw UnsupportedError(
        'Unsupported projection snapshot version: $snapshotVersion',
      );
    }
    return ProjectionSnapshot(
      cursor: _int(json['cursor'], 'cursor'),
      filterState: _filterStateFromJson(
        _map(json['filterState'], 'filterState'),
      ),
      tripState: _tripStateFromJson(_map(json['tripState'], 'tripState')),
      activeTripId: _nullableString(json['activeTripId'], 'activeTripId'),
      activeSegmentId: _nullableString(
        json['activeSegmentId'],
        'activeSegmentId',
      ),
      pendingManualStartAttemptId: _nullableString(
        json['pendingManualStartAttemptId'],
        'pendingManualStartAttemptId',
      ),
      pendingManualStartRequestedAtMs: _nullableInt(
        json['pendingManualStartRequestedAtMs'],
        'pendingManualStartRequestedAtMs',
      ),
    );
  }

  static Map<String, Object?> _filterStateToJson(FilterState state) => {
    'lastRawTsMs': state.lastRawTsMs,
    'lastTrusted': _sampleToJson(state.lastTrusted),
    'anchor': _sampleToJson(state.anchor),
    'prevSpeedMps': state.prevSpeedMps,
    'anchorClearedConservatively': state.anchorClearedConservatively,
  };

  static FilterState _filterStateFromJson(Map<String, Object?> json) =>
      FilterState(
        lastRawTsMs: _nullableInt(
          json['lastRawTsMs'],
          'filterState.lastRawTsMs',
        ),
        lastTrusted: _sampleFromJson(
          json['lastTrusted'],
          'filterState.lastTrusted',
        ),
        anchor: _sampleFromJson(json['anchor'], 'filterState.anchor'),
        prevSpeedMps: _double(json['prevSpeedMps'], 'filterState.prevSpeedMps'),
        anchorClearedConservatively: _bool(
          json['anchorClearedConservatively'],
          'filterState.anchorClearedConservatively',
        ),
      );

  static Map<String, Object?>? _sampleToJson(GpsSample? sample) {
    if (sample == null) return null;
    return {
      'tsMs': sample.tsMs,
      'latDeg': sample.position.latDeg,
      'lonDeg': sample.position.lonDeg,
      'hAccuracyM': sample.hAccuracyM,
    };
  }

  static GpsSample? _sampleFromJson(Object? value, String field) {
    if (value == null) return null;
    final json = _map(value, field);
    return GpsSample(
      tsMs: _int(json['tsMs'], '$field.tsMs'),
      position: GeoPoint(
        _double(json['latDeg'], '$field.latDeg'),
        _double(json['lonDeg'], '$field.lonDeg'),
      ),
      hAccuracyM: _double(json['hAccuracyM'], '$field.hAccuracyM'),
    );
  }

  static Map<String, Object?> _tripStateToJson(TripState state) => {
    'status': state.status?.name,
    'tripStartMs': state.tripStartMs,
    'pendingSinceMs': state.pendingSinceMs,
    'pausedSinceMs': state.pausedSinceMs,
    'suspectedSinceMs': state.suspectedSinceMs,
    'segmentType': state.segmentType?.name,
    'segmentStartMs': state.segmentStartMs,
    'lastActivityType': state.lastActivityType?.name,
    'lastActivitySinceMs': state.lastActivitySinceMs,
    'lastKnownMovementMs': state.lastKnownMovementMs,
    'closeReason': state.closeReason?.name,
    'lastEventMs': state.lastEventMs,
  };

  static TripState _tripStateFromJson(Map<String, Object?> json) => TripState(
    status: _enumByName(
      TripStatus.values,
      _nullableString(json['status'], 'tripState.status'),
      'tripState.status',
    ),
    tripStartMs: _nullableInt(json['tripStartMs'], 'tripState.tripStartMs'),
    pendingSinceMs: _nullableInt(
      json['pendingSinceMs'],
      'tripState.pendingSinceMs',
    ),
    pausedSinceMs: _nullableInt(
      json['pausedSinceMs'],
      'tripState.pausedSinceMs',
    ),
    suspectedSinceMs: _nullableInt(
      json['suspectedSinceMs'],
      'tripState.suspectedSinceMs',
    ),
    segmentType: _enumByName(
      SegmentType.values,
      _nullableString(json['segmentType'], 'tripState.segmentType'),
      'tripState.segmentType',
    ),
    segmentStartMs: _nullableInt(
      json['segmentStartMs'],
      'tripState.segmentStartMs',
    ),
    lastActivityType: _enumByName(
      ActivityType.values,
      _nullableString(json['lastActivityType'], 'tripState.lastActivityType'),
      'tripState.lastActivityType',
    ),
    lastActivitySinceMs: _nullableInt(
      json['lastActivitySinceMs'],
      'tripState.lastActivitySinceMs',
    ),
    lastKnownMovementMs: _nullableInt(
      json['lastKnownMovementMs'],
      'tripState.lastKnownMovementMs',
    ),
    closeReason: _enumByName(
      TripCloseReason.values,
      _nullableString(json['closeReason'], 'tripState.closeReason'),
      'tripState.closeReason',
    ),
    lastEventMs: _nullableInt(json['lastEventMs'], 'tripState.lastEventMs'),
  );

  static Map<String, Object?> _map(Object? value, String field) {
    if (value is! Map) throw FormatException('$field must be an object');
    return value.map<String, Object?>((key, value) {
      if (key is! String) throw FormatException('$field has a non-string key');
      return MapEntry(key, value);
    });
  }

  static int _int(Object? value, String field) {
    if (value is! int) throw FormatException('$field must be an integer');
    return value;
  }

  static int? _nullableInt(Object? value, String field) =>
      value == null ? null : _int(value, field);

  static double _double(Object? value, String field) {
    if (value is! num) throw FormatException('$field must be a number');
    return value.toDouble();
  }

  static bool _bool(Object? value, String field) {
    if (value is! bool) throw FormatException('$field must be a boolean');
    return value;
  }

  static String? _nullableString(Object? value, String field) {
    if (value == null) return null;
    if (value is! String) throw FormatException('$field must be a string');
    return value;
  }

  static T? _enumByName<T extends Enum>(
    Iterable<T> values,
    String? name,
    String field,
  ) {
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw FormatException('$field has unsupported enum value: $name');
  }
}
