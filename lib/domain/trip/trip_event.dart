import '../activity/activity_state.dart';

/// Sealed event hierarchy for TripStateMachine (§6.2, D-026).
///
/// Dart sealed classes require all subclasses in the same library;
/// all events are defined in this file (justified exception to one-type-per-file).
sealed class TripEvent {
  final int nowMs;
  const TripEvent(this.nowMs);
}

/// User explicitly pressed start.
final class UserStart extends TripEvent {
  const UserStart(super.nowMs);
}

/// NFC tag was scanned.
final class NfcScan extends TripEvent {
  const NfcScan(super.nowMs);
}

/// User explicitly pressed stop.
final class UserStop extends TripEvent {
  const UserStop(super.nowMs);
}

/// Activity state machine emitted a new classification.
final class ActivityChanged extends TripEvent {
  final ActivityState activity;
  const ActivityChanged(super.nowMs, this.activity);
}

/// GPS recording gap detected after the last trusted GPS timestamp.
final class GpsGapDetected extends TripEvent {
  final int detectedAtMs;
  final int lastTrustedGpsMs;

  const GpsGapDetected(this.detectedAtMs, this.lastTrustedGpsMs)
    : super(detectedAtMs);
}

/// Activity and GPS history became available after a recording interruption.
final class RecoveryDetected extends TripEvent {
  final int detectedAtMs;
  final int lastTrustedGpsMs;
  final int? lastKnownMovementMs;

  const RecoveryDetected(
    this.detectedAtMs,
    this.lastTrustedGpsMs, [
    this.lastKnownMovementMs,
  ]) : super(detectedAtMs);
}

/// Periodic clock tick for timeout checks.
final class Tick extends TripEvent {
  const Tick(super.nowMs);
}
