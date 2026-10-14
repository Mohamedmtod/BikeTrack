import 'activity_type.dart';

/// Configuration for [ActivityStateMachine] hysteresis and gap timeouts (§6.1, D-024).
class ActivityStateConfig {
  final int cyclingMs;
  final int walkingMs;
  final int automotiveMs;
  final int stationaryMs;
  final int unknownMs;
  final int runningMs;
  final int maxEvidenceGapMs;

  const ActivityStateConfig({
    this.cyclingMs = 30000,
    this.walkingMs = 20000,
    this.automotiveMs = 60000,
    this.stationaryMs = 45000,
    this.unknownMs = 30000,
    this.runningMs = 30000,
    this.maxEvidenceGapMs = 120000,
  }) : assert(cyclingMs > 0),
       assert(walkingMs > 0),
       assert(automotiveMs > 0),
       assert(stationaryMs > 0),
       assert(unknownMs > 0),
       assert(runningMs > 0),
       assert(maxEvidenceGapMs > 0);

  Map<ActivityType, int> get hysteresis => {
    ActivityType.cycling: cyclingMs,
    ActivityType.walking: walkingMs,
    ActivityType.automotive: automotiveMs,
    ActivityType.stationary: stationaryMs,
    ActivityType.unknown: unknownMs,
    ActivityType.running: runningMs,
  };

  int operator [](ActivityType type) {
    switch (type) {
      case ActivityType.cycling:
        return cyclingMs;
      case ActivityType.walking:
        return walkingMs;
      case ActivityType.automotive:
        return automotiveMs;
      case ActivityType.stationary:
        return stationaryMs;
      case ActivityType.unknown:
        return unknownMs;
      case ActivityType.running:
        return runningMs;
    }
  }
}
