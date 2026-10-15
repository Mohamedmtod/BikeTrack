import '../activity/activity_type.dart';
import 'segment_type.dart';
import 'trip_close_reason.dart';
import 'trip_status.dart';

// Sentinel used by copyWith to mean "keep the current field value".
// Callers pass null to explicitly clear a nullable field.
const Object _keep = Object();

/// Immutable trip state consumed and produced by TripStateMachine (§6.2, D-026).
///
/// Idle (no open trip) is represented as [status] == null; use [isIdle].
class TripState {
  final TripStatus? status;
  final int? tripStartMs;
  final int? pendingSinceMs;
  final int? pausedSinceMs;
  final int? suspectedSinceMs;
  final SegmentType? segmentType;
  final int? segmentStartMs;
  final ActivityType? lastActivityType;
  final int? lastActivitySinceMs;
  final int? lastKnownMovementMs;
  final TripCloseReason? closeReason;
  final int? lastEventMs;

  const TripState({
    this.status,
    this.tripStartMs,
    this.pendingSinceMs,
    this.pausedSinceMs,
    this.suspectedSinceMs,
    this.segmentType,
    this.segmentStartMs,
    this.lastActivityType,
    this.lastActivitySinceMs,
    this.lastKnownMovementMs,
    this.closeReason,
    this.lastEventMs,
  });

  /// Creates an idle state (no open trip; all fields null).
  const TripState.idle()
    : status = null,
      tripStartMs = null,
      pendingSinceMs = null,
      pausedSinceMs = null,
      suspectedSinceMs = null,
      segmentType = null,
      segmentStartMs = null,
      lastActivityType = null,
      lastActivitySinceMs = null,
      lastKnownMovementMs = null,
      closeReason = null,
      lastEventMs = null;

  /// True when there is no open trip (status == null).
  bool get isIdle => status == null;

  /// Returns a copy with specified fields replaced.
  ///
  /// Omit a parameter to keep its current value.
  /// Pass [null] explicitly to clear a nullable field.
  TripState copyWith({
    Object? status = _keep,
    Object? tripStartMs = _keep,
    Object? pendingSinceMs = _keep,
    Object? pausedSinceMs = _keep,
    Object? suspectedSinceMs = _keep,
    Object? segmentType = _keep,
    Object? segmentStartMs = _keep,
    Object? lastActivityType = _keep,
    Object? lastActivitySinceMs = _keep,
    Object? lastKnownMovementMs = _keep,
    Object? closeReason = _keep,
    Object? lastEventMs = _keep,
  }) {
    return TripState(
      status: status == _keep ? this.status : status as TripStatus?,
      tripStartMs: tripStartMs == _keep
          ? this.tripStartMs
          : tripStartMs as int?,
      pendingSinceMs: pendingSinceMs == _keep
          ? this.pendingSinceMs
          : pendingSinceMs as int?,
      pausedSinceMs: pausedSinceMs == _keep
          ? this.pausedSinceMs
          : pausedSinceMs as int?,
      suspectedSinceMs: suspectedSinceMs == _keep
          ? this.suspectedSinceMs
          : suspectedSinceMs as int?,
      segmentType: segmentType == _keep
          ? this.segmentType
          : segmentType as SegmentType?,
      segmentStartMs: segmentStartMs == _keep
          ? this.segmentStartMs
          : segmentStartMs as int?,
      lastActivityType: lastActivityType == _keep
          ? this.lastActivityType
          : lastActivityType as ActivityType?,
      lastActivitySinceMs: lastActivitySinceMs == _keep
          ? this.lastActivitySinceMs
          : lastActivitySinceMs as int?,
      lastKnownMovementMs: lastKnownMovementMs == _keep
          ? this.lastKnownMovementMs
          : lastKnownMovementMs as int?,
      closeReason: closeReason == _keep
          ? this.closeReason
          : closeReason as TripCloseReason?,
      lastEventMs: lastEventMs == _keep
          ? this.lastEventMs
          : lastEventMs as int?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          tripStartMs == other.tripStartMs &&
          pendingSinceMs == other.pendingSinceMs &&
          pausedSinceMs == other.pausedSinceMs &&
          suspectedSinceMs == other.suspectedSinceMs &&
          segmentType == other.segmentType &&
          segmentStartMs == other.segmentStartMs &&
          lastActivityType == other.lastActivityType &&
          lastActivitySinceMs == other.lastActivitySinceMs &&
          lastKnownMovementMs == other.lastKnownMovementMs &&
          closeReason == other.closeReason &&
          lastEventMs == other.lastEventMs;

  @override
  int get hashCode => Object.hash(
    status,
    tripStartMs,
    pendingSinceMs,
    pausedSinceMs,
    suspectedSinceMs,
    segmentType,
    segmentStartMs,
    lastActivityType,
    lastActivitySinceMs,
    lastKnownMovementMs,
    closeReason,
    lastEventMs,
  );

  @override
  String toString() =>
      'TripState('
      'status: $status, '
      'tripStartMs: $tripStartMs, '
      'pendingSinceMs: $pendingSinceMs, '
      'pausedSinceMs: $pausedSinceMs, '
      'suspectedSinceMs: $suspectedSinceMs, '
      'segmentType: $segmentType, '
      'segmentStartMs: $segmentStartMs, '
      'lastActivityType: $lastActivityType, '
      'lastActivitySinceMs: $lastActivitySinceMs, '
      'lastKnownMovementMs: $lastKnownMovementMs, '
      'closeReason: $closeReason, '
      'lastEventMs: $lastEventMs)';
}
