import 'dart:math' as math;

import '../../activity/activity_type.dart';
import '../../config/trip_config.dart';
import '../gps_mode.dart';
import '../segment_type.dart';
import '../trip_close_reason.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';

TripStepResult suspectedForgottenStep(
  TripState state,
  TripEvent event,
  TripConfig config,
) {
  if (event is UserStop) {
    return _endTrip(
      state,
      _terminalEnd(state, state.lastKnownMovementMs ?? event.nowMs, event.nowMs),
      TripStatus.completed,
      TripCloseReason.userStopped,
    );
  }
  if (event is UserStart || event is NfcScan) {
    return TripStepResult(state, [const AskOpenTripDecision()]);
  }
  if (event is ActivityChanged && event.activity.type == ActivityType.cycling) {
    return _resumeCycling(state, event);
  }
  if (event.nowMs - state.suspectedSinceMs! >= config.autoCloseMs) {
    return _endTrip(
      state,
      _terminalEnd(
        state,
        state.lastKnownMovementMs ?? state.pausedSinceMs ?? event.nowMs,
        event.nowMs,
      ),
      TripStatus.needsReview,
      TripCloseReason.autoClosed,
    );
  }
  return TripStepResult(state, const <TripCommand>[]);
}

TripStepResult _resumeCycling(TripState state, ActivityChanged event) {
  if (state.segmentType != SegmentType.gap) {
    return TripStepResult(
      state.copyWith(
        status: TripStatus.active,
        pausedSinceMs: null,
        suspectedSinceMs: null,
      ),
      [const StartGps(GpsMode.high)],
    );
  }

  final startMs = math.max(
    state.segmentStartMs!,
    math.min(event.activity.sinceMs, event.nowMs),
  );
  return TripStepResult(
    state.copyWith(
      status: TripStatus.active,
      pausedSinceMs: null,
      suspectedSinceMs: null,
      segmentType: SegmentType.cycling,
      segmentStartMs: startMs,
    ),
    [
      CloseSegment(startMs),
      OpenSegment(SegmentType.cycling, startMs),
      const StartGps(GpsMode.high),
    ],
  );
}

TripStepResult _endTrip(
  TripState state,
  int endMs,
  TripStatus status,
  TripCloseReason closeReason,
) {
  final commands = <TripCommand>[];
  if (state.segmentStartMs != null) {
    commands.add(CloseSegment(endMs));
  }
  commands.add(const StopGps());
  commands.add(EndTrip(endMs));
  return TripStepResult(
    state.copyWith(
      status: status,
      pendingSinceMs: null,
      pausedSinceMs: null,
      suspectedSinceMs: null,
      segmentType: null,
      segmentStartMs: null,
      lastKnownMovementMs: endMs,
      closeReason: closeReason,
    ),
    commands,
  );
}

int _terminalEnd(TripState state, int candidateMs, int upperBoundMs) {
  final lowerBoundMs = state.segmentStartMs ?? state.tripStartMs ?? candidateMs;
  return math.max(lowerBoundMs, math.min(candidateMs, upperBoundMs));
}
