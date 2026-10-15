import '../../config/trip_config.dart';
import '../../activity/activity_type.dart';
import '../gps_mode.dart';
import '../trip_close_reason.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';

/// Transitions for paused status (§6.2, D-026).
///
/// UserStop -> completed, ending at pausedSinceMs (segment was not closed on pause).
/// UserStart / NfcScan -> AskOpenTripDecision.
/// Cycling activity -> resume active (segment continues; pausedSinceMs cleared).
/// Other activity / Tick -> no-op (phase 2 deferred, D-026).
TripStepResult pausedStep(TripState s, TripEvent event, TripConfig config) {
  if (event is UserStop) {
    final endMs = s.pausedSinceMs! < (s.segmentStartMs ?? s.tripStartMs!)
        ? (s.segmentStartMs ?? s.tripStartMs!)
        : s.pausedSinceMs!;
    return TripStepResult(
      TripState(
        status: TripStatus.completed,
        tripStartMs: s.tripStartMs,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastKnownMovementMs: endMs,
        closeReason: TripCloseReason.userStopped,
        lastEventMs: s.lastEventMs,
      ),
      [CloseSegment(endMs), const StopGps(), EndTrip(endMs)],
    );
  }
  if (event is UserStart || event is NfcScan) {
    return TripStepResult(s, [const AskOpenTripDecision()]);
  }
  if (s.lastActivityType == ActivityType.cycling) {
    return TripStepResult(
      TripState(
        status: TripStatus.active,
        tripStartMs: s.tripStartMs,
        segmentType: s.segmentType,
        segmentStartMs: s.segmentStartMs,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastKnownMovementMs: s.lastKnownMovementMs,
        lastEventMs: s.lastEventMs,
        // pausedSinceMs intentionally cleared (null)
      ),
      [const StartGps(GpsMode.high)],
    );
  }
  if (event.nowMs - s.pausedSinceMs! >= config.forgotMs) {
    return TripStepResult(
      s.copyWith(
        status: TripStatus.suspectedForgotten,
        suspectedSinceMs: event.nowMs,
      ),
      const <TripCommand>[],
    );
  }
  return TripStepResult(s, const <TripCommand>[]);
}
