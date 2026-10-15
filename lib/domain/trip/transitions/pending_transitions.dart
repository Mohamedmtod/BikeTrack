import 'dart:math' show max;

import '../../config/trip_config.dart';
import '../../activity/activity_type.dart';
import '../gps_mode.dart';
import '../segment_type.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';

/// Transitions for pending status (§6.2, D-026).
///
/// UserStart -> active immediately.
/// UserStop -> idle (cancel).
/// NfcScan -> no-op (already pending).
/// Cycling activity detected -> active at max(sinceMs, pendingSinceMs).
/// Pending timeout (nowMs - pendingSinceMs >= pendingMs) -> idle (cancel).
TripStepResult pendingStep(TripState s, TripEvent event, TripConfig config) {
  if (event is UserStart) {
    return TripStepResult(
      TripState(
        status: TripStatus.active,
        tripStartMs: event.nowMs,
        segmentType: SegmentType.cycling,
        segmentStartMs: event.nowMs,
        lastKnownMovementMs: event.nowMs,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.high), OpenSegment(SegmentType.cycling, event.nowMs)],
    );
  }
  if (event is UserStop) {
    return TripStepResult(
      TripState(
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [const StopGps(), const CancelTrip()],
    );
  }
  if (event is NfcScan) {
    return TripStepResult(s, const <TripCommand>[]);
  }

  // Activity stored by machine before dispatch; check for cycling.
  if (s.lastActivityType == ActivityType.cycling) {
    final start = max(s.lastActivitySinceMs!, s.pendingSinceMs!);
    return TripStepResult(
      TripState(
        status: TripStatus.active,
        tripStartMs: start,
        segmentType: SegmentType.cycling,
        segmentStartMs: start,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastKnownMovementMs: event.nowMs,
        lastEventMs: s.lastEventMs,
      ),
      [StartGps(GpsMode.high), OpenSegment(SegmentType.cycling, start)],
    );
  }

  // Pending timeout.
  if (event.nowMs - s.pendingSinceMs! >= config.pendingMs) {
    return TripStepResult(
      TripState(
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [const StopGps(), const CancelTrip()],
    );
  }

  return TripStepResult(s, const <TripCommand>[]);
}
