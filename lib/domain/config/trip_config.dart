/// Configuration thresholds for trip lifecycle and detection (§6.4, D-025).
class TripConfig {
  final int pendingMs;
  final int pauseMs;
  final int forgotMs;
  final int autoCloseMs;
  final int modeChangeMs;
  final int gapMs;
  final double pauseRegionRadiusM;
  final double cadenceWalkingMinSps;

  const TripConfig({
    this.pendingMs = 300000,
    this.pauseMs = 180000,
    this.forgotMs = 900000,
    this.autoCloseMs = 2700000,
    this.modeChangeMs = 60000,
    this.gapMs = 30000,
    this.pauseRegionRadiusM = 100.0,
    this.cadenceWalkingMinSps = 1.2,
  }) : assert(pendingMs > 0),
       assert(pauseMs > 0),
       assert(forgotMs > 0),
       assert(autoCloseMs > 0),
       assert(modeChangeMs > 0),
       assert(gapMs > 0),
       assert(pauseRegionRadiusM > 0),
       assert(cadenceWalkingMinSps > 0);
}
