import 'activity_type.dart';

/// Immutable activity state tracking the current type and debounce candidate (§6.1, D-024).
class ActivityState {
  final ActivityType type;
  final int sinceMs;
  final ActivityType? candidate;
  final int? candidateSinceMs;
  final int? lastUpdateMs;

  const ActivityState({
    required this.type,
    required this.sinceMs,
    this.candidate,
    this.candidateSinceMs,
    this.lastUpdateMs,
  });

  factory ActivityState.initial(int nowMs) => ActivityState(
    type: ActivityType.unknown,
    sinceMs: nowMs,
    candidate: null,
    candidateSinceMs: null,
    lastUpdateMs: null,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityState &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          sinceMs == other.sinceMs &&
          candidate == other.candidate &&
          candidateSinceMs == other.candidateSinceMs &&
          lastUpdateMs == other.lastUpdateMs;

  @override
  int get hashCode =>
      Object.hash(type, sinceMs, candidate, candidateSinceMs, lastUpdateMs);

  @override
  String toString() =>
      'ActivityState(type: $type, sinceMs: $sinceMs, candidate: $candidate, candidateSinceMs: $candidateSinceMs, lastUpdateMs: $lastUpdateMs)';
}
