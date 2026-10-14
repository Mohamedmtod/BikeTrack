import 'activity_type.dart';

/// Output model produced by ActivityClassifier (§7.6, D-022).
class ClassificationResult {
  final ActivityType type;
  final Map<ActivityType, double> scores;
  final double bestScore;
  final double margin;

  const ClassificationResult({
    required this.type,
    required this.scores,
    required this.bestScore,
    required this.margin,
  });
}
