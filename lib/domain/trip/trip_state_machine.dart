import '../config/trip_config.dart';
import 'transitions/active_transitions.dart';
import 'transitions/idle_transitions.dart';
import 'transitions/paused_transitions.dart';
import 'transitions/pending_transitions.dart';
import 'trip_command.dart';
import 'trip_event.dart';
import 'trip_state.dart';
import 'trip_status.dart';
import 'trip_step_result.dart';

/// Pure trip state machine: step(state, event, config) -> result (§6.2, D-026).
///
/// Idle is [TripState.isIdle]. No side effects; all rules live in transitions/.
class TripStateMachine {
  const TripStateMachine._();

  static TripStepResult step(
    TripState state,
    TripEvent event,
    TripConfig config,
  ) {
    // Ignore out-of-order events.
    if (state.lastEventMs != null && event.nowMs < state.lastEventMs!) {
      return TripStepResult(state, const <TripCommand>[]);
    }

    // Advance timestamp; store activity classification if present.
    TripState s = state.copyWith(lastEventMs: event.nowMs);
    if (event is ActivityChanged) {
      s = s.copyWith(
        lastActivityType: event.activity.type,
        lastActivitySinceMs: event.activity.sinceMs,
      );
    }

    // Dispatch by status.
    if (s.isIdle || s.status == TripStatus.completed) {
      return idleOrCompletedStep(s, event, config);
    }
    if (s.status == TripStatus.pending) {
      return pendingStep(s, event, config);
    }
    if (s.status == TripStatus.active) {
      return activeStep(s, event, config);
    }
    if (s.status == TripStatus.paused) {
      return pausedStep(s, event, config);
    }
    return TripStepResult(s, const <TripCommand>[]);
  }
}
