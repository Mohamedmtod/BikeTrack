import '../../config/trip_config.dart';
import '../../activity/activity_type.dart';
import '../gps_mode.dart';
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
    return TripStepResult(
      TripState(
        status: TripStatus.completed,
        tripStartMs: s.tripStartMs,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [
        CloseSegment(s.pausedSinceMs!),
        const StopGps(),
        EndTrip(s.pausedSinceMs!),
      ],
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
        lastEventMs: s.lastEventMs,
        // pausedSinceMs intentionally cleared (null)
      ),
      [const StartGps(GpsMode.high)],
    );
  }
  return TripStepResult(s, const <TripCommand>[]);
}
