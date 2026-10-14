import 'trip_command.dart';
import 'trip_state.dart';

/// Result of a single TripStateMachine step (§6.2, D-026).
class TripStepResult {
  final TripState state;
  final List<TripCommand> commands;

  const TripStepResult(this.state, this.commands);
}
