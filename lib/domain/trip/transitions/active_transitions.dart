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

/// Maps a moving [ActivityType] to its [SegmentType]; returns null for others.
SegmentType? _toSegmentType(ActivityType type) => switch (type) {
  ActivityType.cycling => SegmentType.cycling,
  ActivityType.walking => SegmentType.walking,
  ActivityType.automotive => SegmentType.automotive,
  _ => null,
};

/// Transitions for active status (§6.2, D-026, D-027).
///
/// UserStop -> completed.
/// UserStart / NfcScan -> AskOpenTripDecision (trip already open).
/// Stationary >= pauseMs (elapsed from clamped pauseStart) -> paused.
/// Moving activity != current segment >= modeChangeMs (elapsed from clamped switchAt) -> segment switch.
TripStepResult activeStep(TripState s, TripEvent event, TripConfig config) {
  if (event is UserStop) {
    return TripStepResult(
      TripState(
        status: TripStatus.completed,
        tripStartMs: s.tripStartMs,
        lastActivityType: s.lastActivityType,
        lastActivitySinceMs: s.lastActivitySinceMs,
        lastEventMs: s.lastEventMs,
      ),
      [CloseSegment(event.nowMs), const StopGps(), EndTrip(event.nowMs)],
    );
  }
  if (event is UserStart || event is NfcScan) {
    return TripStepResult(s, [const AskOpenTripDecision()]);
  }

  final lat = s.lastActivityType;
  final lasSince = s.lastActivitySinceMs;

  // Stationary -> paused after pauseMs (D-027: clamp to segmentStartMs ?? tripStartMs).
  if (lat == ActivityType.stationary && lasSince != null) {
    final pauseStart = max(lasSince, s.segmentStartMs ?? s.tripStartMs!);
    if (event.nowMs - pauseStart >= config.pauseMs) {
      return TripStepResult(
        TripState(
          status: TripStatus.paused,
          tripStartMs: s.tripStartMs,
          segmentType: s.segmentType,
          segmentStartMs: s.segmentStartMs,
          pausedSinceMs: pauseStart,
          lastActivityType: s.lastActivityType,
          lastActivitySinceMs: lasSince,
          lastEventMs: s.lastEventMs,
        ),
        [const StartGps(GpsMode.lowPower)],
      );
    }
    return TripStepResult(s, const <TripCommand>[]);
  }

  // Moving activity -> mode change after modeChangeMs (D-027: clamp switchAt).
  if (lat != null && lasSince != null) {
    final seg = _toSegmentType(lat);
    if (seg != null && seg != s.segmentType) {
      final switchAt = max(lasSince, s.segmentStartMs ?? s.tripStartMs!);
      if (event.nowMs - switchAt >= config.modeChangeMs) {
        return TripStepResult(
          TripState(
            status: TripStatus.active,
            tripStartMs: s.tripStartMs,
            segmentType: seg,
            segmentStartMs: switchAt,
            lastActivityType: s.lastActivityType,
            lastActivitySinceMs: lasSince,
            lastEventMs: s.lastEventMs,
          ),
          [
            CloseSegment(switchAt),
            OpenSegment(
              seg,
              switchAt,
              needsReview: seg == SegmentType.automotive,
            ),
          ],
        );
      }
    }
  }

  return TripStepResult(s, const <TripCommand>[]);
}
