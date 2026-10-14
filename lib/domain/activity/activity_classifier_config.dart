/// Configuration thresholds and weights for ActivityClassifier (§7.6, D-022).
class ActivityClassifierConfig {
  final double w1;
  final double w2;
  final double w3;
  final double w5;

  final double confLow;
  final double confMedium;
  final double confHigh;

  final double cadenceFull;
  final double stationarySpeedMax;

  final double minBestScore;
  final double minMargin;

  final double walkSpeedA;
  final double walkSpeedB;
  final double walkSpeedC;
  final double walkSpeedD;

  final double cycleSpeedA;
  final double cycleSpeedB;
  final double cycleSpeedC;
  final double cycleSpeedD;

  final double autoSpeedA;
  final double autoSpeedB;
  final double autoSpeedC;
  final double autoSpeedD;

  const ActivityClassifierConfig({
    this.w1 = 0.55,
    this.w2 = 0.30,
    this.w3 = 0.15,
    this.w5 = 0.10,
    this.confLow = 0.3,
    this.confMedium = 0.6,
    this.confHigh = 1.0,
    this.cadenceFull = 1.8,
    this.stationarySpeedMax = 0.5,
    this.minBestScore = 0.45,
    this.minMargin = 0.15,
    this.walkSpeedA = 0.3,
    this.walkSpeedB = 1.0,
    this.walkSpeedC = 2.0,
    this.walkSpeedD = 3.0,
    this.cycleSpeedA = 2.0,
    this.cycleSpeedB = 3.0,
    this.cycleSpeedC = 9.0,
    this.cycleSpeedD = 12.0,
    this.autoSpeedA = 6.0,
    this.autoSpeedB = 8.0,
    this.autoSpeedC = double.infinity,
    this.autoSpeedD = double.infinity,
  }) : assert(w1 >= 0),
       assert(w2 >= 0),
       assert(w3 >= 0),
       assert(w5 >= 0),
       assert(confLow >= 0),
       assert(confMedium >= 0),
       assert(confHigh >= 0),
       assert(confLow <= 1),
       assert(confMedium <= 1),
       assert(confHigh <= 1),
       assert(w1 + w2 + w3 <= 1),
       assert(w1 + w2 + w5 <= 1),
       assert(minBestScore >= 0 && minBestScore <= 1),
       assert(minMargin >= 0 && minMargin <= 1),
       assert(cadenceFull > 0),
       assert(
         walkSpeedA <= walkSpeedB &&
             walkSpeedB <= walkSpeedC &&
             walkSpeedC <= walkSpeedD,
       ),
       assert(
         cycleSpeedA <= cycleSpeedB &&
             cycleSpeedB <= cycleSpeedC &&
             cycleSpeedC <= cycleSpeedD,
       ),
       assert(
         autoSpeedA <= autoSpeedB &&
             autoSpeedB <= autoSpeedC &&
             autoSpeedC <= autoSpeedD,
       );
}
