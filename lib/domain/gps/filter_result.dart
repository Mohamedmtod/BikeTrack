import 'filter_state.dart';
import 'reject_reason.dart';

/// The value returned by [GpsFilter.step].
class FilterResult {
  /// The updated state to pass to the next [GpsFilter.step] call.
  final FilterState newState;

  /// Whether the point is accepted (contributes to the ride or resets anchor).
  ///
  /// true  → point passes all checks (may add distance, reset anchor, or be stationary).
  /// false → point rejected; [reason] explains why; [distanceAddedM] is always 0.
  final bool accepted;

  /// Why the point was not accepted outright, or how it was treated specially.
  /// Null only when [accepted] is true and the point genuinely added distance
  /// (normal forward movement).
  final RejectReason? reason;

  /// Distance in metres added to the running total by this point.
  /// 0 for rejected points, stationary gate, jitter, and anchor-reset.
  /// Positive only for a genuine forward-movement acceptance (check 10).
  final double distanceAddedM;

  const FilterResult({
    required this.newState,
    required this.accepted,
    this.reason,
    this.distanceAddedM = 0.0,
  });
}
