import 'activity_state.dart';

/// Result produced by an [ActivityStateMachine.step] transition (§6.1).
class ActivityStateResult {
  final ActivityState state;
  final bool changed;

  const ActivityStateResult({required this.state, required this.changed});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityStateResult &&
          runtimeType == other.runtimeType &&
          state == other.state &&
          changed == other.changed;

  @override
  int get hashCode => Object.hash(state, changed);

  @override
  String toString() => 'ActivityStateResult(state: $state, changed: $changed)';
}
