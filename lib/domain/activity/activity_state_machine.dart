import 'activity_state.dart';
import 'activity_state_config.dart';
import 'activity_state_result.dart';
import 'activity_type.dart';

/// Pure-Dart activity state machine implementing hysteresis debouncing (§6.1, D-024).
class ActivityStateMachine {
  const ActivityStateMachine._();

  /// Transitions [s] given a newly [classified] activity at [nowMs].
  static ActivityStateResult step(
    ActivityState s,
    ActivityType classified,
    int nowMs, {
    ActivityStateConfig cfg = const ActivityStateConfig(),
  }) {
    // 1. Out-of-order or duplicate timestamp: ignore and leave state unchanged.
    if (s.lastUpdateMs != null && nowMs <= s.lastUpdateMs!) {
      return ActivityStateResult(state: s, changed: false);
    }

    // 2. Evidence gap detection.
    final gap =
        s.lastUpdateMs != null &&
        (nowMs - s.lastUpdateMs! > cfg.maxEvidenceGapMs);

    // 3. Classified input matches current state type: clear candidate.
    if (classified == s.type) {
      final nextState = ActivityState(
        type: s.type,
        sinceMs: s.sinceMs,
        candidate: null,
        candidateSinceMs: null,
        lastUpdateMs: nowMs,
      );
      return ActivityStateResult(state: nextState, changed: false);
    }

    // 4. Classified input differs from current state type.
    if (!gap && classified == s.candidate) {
      final candidateSinceMs = s.candidateSinceMs!;
      final hysteresisMs = cfg.hysteresis[classified]!;
      if (nowMs - candidateSinceMs >= hysteresisMs) {
        final nextState = ActivityState(
          type: classified,
          sinceMs: candidateSinceMs,
          candidate: null,
          candidateSinceMs: null,
          lastUpdateMs: nowMs,
        );
        return ActivityStateResult(state: nextState, changed: true);
      } else {
        final nextState = ActivityState(
          type: s.type,
          sinceMs: s.sinceMs,
          candidate: s.candidate,
          candidateSinceMs: s.candidateSinceMs,
          lastUpdateMs: nowMs,
        );
        return ActivityStateResult(state: nextState, changed: false);
      }
    } else {
      final nextState = ActivityState(
        type: s.type,
        sinceMs: s.sinceMs,
        candidate: classified,
        candidateSinceMs: nowMs,
        lastUpdateMs: nowMs,
      );
      return ActivityStateResult(state: nextState, changed: false);
    }
  }
}
