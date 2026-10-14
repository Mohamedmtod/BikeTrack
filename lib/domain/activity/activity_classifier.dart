import 'dart:math' as math;

import '../shared/confidence.dart';
import 'activity_classifier_config.dart';
import 'activity_type.dart';
import 'activity_window.dart';
import 'classification_result.dart';
import 'membership.dart';

/// Classifies physical activity from pre-aggregated sensor windows (§7.6, D-022).
class ActivityClassifier {
  const ActivityClassifier._();

  static ClassificationResult classify(
    ActivityWindow w, {
    ActivityClassifierConfig cfg = const ActivityClassifierConfig(),
  }) {
    final double conf;
    switch (w.cmConfidence) {
      case Confidence.low:
        conf = cfg.confLow;
      case Confidence.medium:
        conf = cfg.confMedium;
      case Confidence.high:
        conf = cfg.confHigh;
      case null:
        conf = 0.0;
    }

    final resolvedCm = _resolveCmType(w.cmTypes);
    final cmCycling = (resolvedCm == ActivityType.cycling) ? 1.0 : 0.0;
    final cmWalking = (resolvedCm == ActivityType.walking) ? 1.0 : 0.0;
    final cmAutomotive = (resolvedCm == ActivityType.automotive) ? 1.0 : 0.0;
    final cmStationary = (resolvedCm == ActivityType.stationary) ? 1.0 : 0.0;

    final double sSpeedWalk;
    final double sSpeedCyc;
    final double sSpeedAuto;
    final double stationarySpeedTerm;

    final speed = _normalizeSpeed(w.speedMps);
    if (speed == null) {
      sSpeedWalk = 0.0;
      sSpeedCyc = 0.0;
      sSpeedAuto = 0.0;
      stationarySpeedTerm = 0.0;
    } else {
      sSpeedWalk = trapezoid(
        speed,
        cfg.walkSpeedA,
        cfg.walkSpeedB,
        cfg.walkSpeedC,
        cfg.walkSpeedD,
      );
      sSpeedCyc = trapezoid(
        speed,
        cfg.cycleSpeedA,
        cfg.cycleSpeedB,
        cfg.cycleSpeedC,
        cfg.cycleSpeedD,
      );
      sSpeedAuto = trapezoid(
        speed,
        cfg.autoSpeedA,
        cfg.autoSpeedB,
        cfg.autoSpeedC,
        cfg.autoSpeedD,
      );
      stationarySpeedTerm = (speed < cfg.stationarySpeedMax) ? 1.0 : 0.0;
    }

    final double walkingCadenceTerm;
    final double cyclingCadenceTerm;

    final cadence = _normalizeCadence(w.cadenceSps);
    if (cadence == null) {
      walkingCadenceTerm = 0.0;
      cyclingCadenceTerm = 0.0;
    } else {
      final sCad = math.min(1.0, cadence / cfg.cadenceFull);
      walkingCadenceTerm = cfg.w3 * sCad;
      cyclingCadenceTerm = cfg.w3 * (1.0 - sCad);
    }

    final stop = _normalizeStopPattern(w.stopPatternScore);
    final stopTerm = (stop != null) ? cfg.w5 * stop : 0.0;

    final scoreCycling =
        cfg.w1 * cmCycling * conf + cfg.w2 * sSpeedCyc + cyclingCadenceTerm;

    final scoreWalking =
        cfg.w1 * cmWalking * conf + cfg.w2 * sSpeedWalk + walkingCadenceTerm;

    final scoreAutomotive =
        cfg.w1 * cmAutomotive * conf + cfg.w2 * sSpeedAuto + stopTerm;

    final scoreStationary =
        cfg.w1 * cmStationary * conf + cfg.w2 * stationarySpeedTerm;

    final scores = <ActivityType, double>{
      ActivityType.cycling: scoreCycling,
      ActivityType.walking: scoreWalking,
      ActivityType.automotive: scoreAutomotive,
      ActivityType.stationary: scoreStationary,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final bestScore = sorted[0].value;
    final secondBestScore = sorted[1].value;
    final margin = bestScore - secondBestScore;

    final ActivityType type;
    if (bestScore < cfg.minBestScore || margin < cfg.minMargin) {
      type = ActivityType.unknown;
    } else {
      type = sorted[0].key;
    }

    return ClassificationResult(
      type: type,
      scores: scores,
      bestScore: bestScore,
      margin: margin,
    );
  }

  static double? _normalizeSpeed(double? speed) {
    if (speed == null || !speed.isFinite || speed < 0.0) return null;
    return speed;
  }

  static double? _normalizeCadence(double? cadence) {
    if (cadence == null || !cadence.isFinite || cadence < 0.0) return null;
    return cadence;
  }

  static double? _normalizeStopPattern(double? stop) {
    if (stop == null || !stop.isFinite || stop < 0.0 || stop > 1.0) return null;
    return stop;
  }

  static ActivityType? _resolveCmType(Set<ActivityType> cmTypes) {
    if (cmTypes.length == 1) {
      final single = cmTypes.first;
      switch (single) {
        case ActivityType.cycling:
        case ActivityType.walking:
        case ActivityType.automotive:
        case ActivityType.stationary:
          return single;
        default:
          return null;
      }
    } else if (cmTypes.length == 2 &&
        cmTypes.contains(ActivityType.automotive) &&
        cmTypes.contains(ActivityType.stationary)) {
      return ActivityType.automotive;
    }
    return null;
  }
}
