import '../shared/confidence.dart';
import 'activity_type.dart';

/// Pre-aggregated sensor window for activity classification (§7.6, D-022).
class ActivityWindow {
  final Set<ActivityType> cmTypes;
  final Confidence? cmConfidence;
  final double? cadenceSps;
  final double? speedMps;
  final double? stopPatternScore;

  const ActivityWindow({
    this.cmTypes = const {},
    this.cmConfidence,
    this.cadenceSps,
    this.speedMps,
    this.stopPatternScore,
  });
}
