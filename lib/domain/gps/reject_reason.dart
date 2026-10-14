/// Reason a GPS sample was rejected or handled specially by GpsFilter (§7.2).
enum RejectReason {
  /// h_accuracy < 0 — sensor error (check 1).
  invalid,

  /// h_accuracy > maxHAccuracyM — poor fix (check 2).
  lowAccuracy,

  /// nowMs − sample.tsMs > staleMs — point arrived too late (check 3).
  stale,

  /// sample.tsMs ≤ lastReceived.tsMs — out-of-order delivery (check 4).
  outOfOrder,

  /// Gap > gapMs: anchor was reset; this point becomes the new anchor at distance 0.
  anchorReset,

  /// v (anchor→point) > maxSpeedMps — physically impossible speed (check 6).
  impossibleSpeed,

  /// Instantaneous acceleration exceeds maxAccelMps2 — spike / NLOS jump (check 7).
  spike,

  /// Activity is stationary — point stored but distance = 0, anchor unchanged (check 8).
  stationaryGate,

  /// d < max(minStepM, 0.5*(anchorAcc + pointAcc)) — within uncertainty bubble (check 9).
  jitter,
}
