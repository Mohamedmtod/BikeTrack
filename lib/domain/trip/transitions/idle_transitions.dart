import '../../config/trip_config.dart';
import '../gps_mode.dart';
import '../segment_type.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';

/// Transitions for idle (status == null) and completed status (§6.2, D-026).
///
/// UserStart opens a fresh cycling trip.
/// NfcScan enters pending.
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
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
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
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.lowPower)],
    );
  }
  return TripStepResult(s, const <TripCommand>[]);
}
