import '../../activity/activity_type.dart';
import '../../config/trip_config.dart';
import '../gps_mode.dart';
import '../segment_type.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';

/// Transitions for idle (status == null) and completed status (§6.2, D-026, D-027).
///
/// UserStart opens a fresh cycling trip; clears stale activity (D-027).
/// NfcScan enters pending; clears stale activity (D-027).
/// All other events are no-ops.
TripStepResult idleOrCompletedStep(
  TripState s,
  TripEvent event,
  TripConfig config,
) {
  if (event is UserStart) {
    return TripStepResult(
      TripState(
        status: TripStatus.active,
        tripStartMs: event.nowMs,
        segmentType: SegmentType.cycling,
        segmentStartMs: event.nowMs,
        lastKnownMovementMs: event.nowMs,
        // lastActivityType/lastActivitySinceMs cleared — D-027(1)
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.high), OpenSegment(SegmentType.cycling, event.nowMs)],
    );
  }
  if (event is NfcScan) {
    return TripStepResult(
      TripState(
        status: TripStatus.pending,
        pendingSinceMs: event.nowMs,
        // lastActivityType/lastActivitySinceMs cleared — D-027(1)
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.lowPower)],
    );
  }
  if (s.isIdle &&
      event is ActivityChanged &&
      event.activity.type == ActivityType.cycling) {
    final startMs = event.activity.sinceMs > event.nowMs
        ? event.nowMs
        : event.activity.sinceMs;
    return TripStepResult(
      TripState(
        status: TripStatus.active,
        tripStartMs: startMs,
        segmentType: SegmentType.cycling,
        segmentStartMs: startMs,
        lastActivityType: ActivityType.cycling,
        lastActivitySinceMs: event.activity.sinceMs,
        lastKnownMovementMs: event.nowMs,
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.high), OpenSegment(SegmentType.cycling, startMs)],
    );
  }
  return TripStepResult(s, const <TripCommand>[]);
}
