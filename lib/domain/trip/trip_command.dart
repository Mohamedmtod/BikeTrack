import 'gps_mode.dart';
import 'segment_type.dart';

/// Sealed command hierarchy produced by TripStateMachine (§6.2, D-026).
///
/// Dart sealed classes require all subclasses in the same library;
/// all commands are defined in this file (justified exception to one-type-per-file).
sealed class TripCommand {
  const TripCommand();
}

/// Start GPS at the given power/accuracy mode.
final class StartGps extends TripCommand {
  final GpsMode mode;
  const StartGps(this.mode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is StartGps && mode == other.mode;

  @override
  int get hashCode => Object.hash(runtimeType, mode);
}

/// Stop GPS.
final class StopGps extends TripCommand {
  const StopGps();

  @override
  bool operator ==(Object other) => other is StopGps;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Open a new trip segment.
final class OpenSegment extends TripCommand {
  final SegmentType type;
  final int startMs;
  final bool needsReview;

  const OpenSegment(this.type, this.startMs, {this.needsReview = false});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpenSegment &&
          type == other.type &&
          startMs == other.startMs &&
          needsReview == other.needsReview;

  @override
  int get hashCode => Object.hash(runtimeType, type, startMs, needsReview);
}

/// Close the current trip segment.
final class CloseSegment extends TripCommand {
  final int endMs;
  const CloseSegment(this.endMs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CloseSegment && endMs == other.endMs;

  @override
  int get hashCode => Object.hash(runtimeType, endMs);
}

/// Persist and finalise the trip.
final class EndTrip extends TripCommand {
  final int endMs;
  const EndTrip(this.endMs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EndTrip && endMs == other.endMs;

  @override
  int get hashCode => Object.hash(runtimeType, endMs);
}

/// Discard the pending trip (no data saved).
final class CancelTrip extends TripCommand {
  const CancelTrip();

  @override
  bool operator ==(Object other) => other is CancelTrip;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// Ask the user what to do with the already-open trip.
final class AskOpenTripDecision extends TripCommand {
  const AskOpenTripDecision();

  @override
  bool operator ==(Object other) => other is AskOpenTripDecision;

  @override
  int get hashCode => runtimeType.hashCode;
}
