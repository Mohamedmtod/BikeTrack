/// Configuration for the GPS filter (§6.4, D-014).
///
/// All thresholds live here; no magic numbers in [GpsFilter] logic.
library;

/// Immutable configuration object passed into every [GpsFilter.step] call.
///
/// Default values match §6.4 of the engineering plan.
class GpsFilterConfig {
  /// Maximum accepted horizontal accuracy in metres.
  /// Points with h_accuracy > [maxHAccuracyM] are rejected as [RejectReason.lowAccuracy].
  final double maxHAccuracyM;

  /// Maximum age of a GPS sample in milliseconds (now − sample.tsMs).
  /// Older points are rejected as [RejectReason.stale].
  final int staleMs;

  /// If the gap between two consecutive points exceeds this (ms), the anchor
  /// is reset and the next accepted point becomes the new anchor at distance 0.
  final int gapMs;

  /// Maximum plausible cycling speed in m/s (60 km/h = 16.7 m/s).
  /// Points implying a higher speed from the anchor are rejected as
  /// [RejectReason.impossibleSpeed].
  final double maxSpeedMps;

  /// Maximum plausible acceleration in m/s².
  /// Points whose instantaneous acceleration (from [lastReceived]) exceeds
  /// this are rejected as [RejectReason.spike].
  final double maxAccelMps2;

  /// Minimum step distance in metres.
  /// A point closer than max([minStepM], 0.5*(anchorAcc + pointAcc)) to the
  /// anchor is treated as [RejectReason.jitter] — distance 0, anchor unchanged.
  final double minStepM;

  const GpsFilterConfig({
    this.maxHAccuracyM = 25.0,
    this.staleMs = 10000,
    this.gapMs = 30000,
    this.maxSpeedMps = 16.7,
    this.maxAccelMps2 = 4.0,
    this.minStepM = 3.0,
  });
}
