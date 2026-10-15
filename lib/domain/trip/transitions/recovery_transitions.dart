import 'dart:math' as math;

import '../segment_type.dart';
import '../trip_command.dart';
import '../trip_event.dart';
import '../trip_state.dart';
import '../trip_status.dart';
import '../trip_step_result.dart';
import '../trip_close_reason.dart';

TripStepResult? gapOrRecoveryStep(TripState state, TripEvent event) {
  if (event is GpsGapDetected) {
    return _gapStep(state, event);
  }
  if (event is RecoveryDetected) {
    return _recoveryStep(state, event);
  }
  return null;
}

TripStepResult _gapStep(TripState state, GpsGapDetected event) {
  if (!_hasOpenSegment(state) || state.segmentType == SegmentType.gap) {
    return TripStepResult(state, const <TripCommand>[]);
  }

  final boundary = _clamp(
    event.lastTrustedGpsMs,
    state.segmentStartMs!,
    event.detectedAtMs,
  );
  return TripStepResult(
    state.copyWith(
      segmentType: SegmentType.gap,
      segmentStartMs: boundary,
    ),
    [
      CloseSegment(boundary),
      OpenSegment(SegmentType.gap, boundary),
      const ResetGpsAnchor(),
    ],
  );
}

TripStepResult _recoveryStep(TripState state, RecoveryDetected event) {
  if (state.isIdle ||
      state.status == TripStatus.completed ||
      state.status == TripStatus.needsReview) {
    return TripStepResult(state, const <TripCommand>[]);
  }

  final commands = <TripCommand>[];
  int? gapStartMs;
  if (_hasOpenSegment(state)) {
    if (state.segmentType == SegmentType.gap) {
      gapStartMs = state.segmentStartMs!;
    } else {
      final trustedBoundary = _clamp(
        event.lastTrustedGpsMs,
        state.segmentStartMs!,
        event.detectedAtMs,
      );
      commands.add(CloseSegment(trustedBoundary));
      commands.add(OpenSegment(SegmentType.gap, trustedBoundary));
      gapStartMs = trustedBoundary;
    }
  }

  final lowerBound = gapStartMs ?? state.tripStartMs ?? event.detectedAtMs;
  final endMs = _clamp(
    event.lastKnownMovementMs ?? event.detectedAtMs,
    lowerBound,
    event.detectedAtMs,
  );
  if (gapStartMs != null) {
    commands.add(CloseSegment(endMs));
  }
  commands.add(const StopGps());
  commands.add(EndTrip(endMs));

  return TripStepResult(
    state.copyWith(
      status: TripStatus.needsReview,
      pendingSinceMs: null,
      pausedSinceMs: null,
      suspectedSinceMs: null,
      segmentType: null,
      segmentStartMs: null,
      lastKnownMovementMs: endMs,
      closeReason: TripCloseReason.recoveredAfterGap,
    ),
    commands,
  );
}

bool _hasOpenSegment(TripState state) =>
    state.segmentType != null && state.segmentStartMs != null;

int _clamp(int value, int lowerBound, int upperBound) =>
    math.max(lowerBound, math.min(value, upperBound));
