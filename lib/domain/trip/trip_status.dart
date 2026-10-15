/// Lifecycle status of a recorded trip (§5.1).
enum TripStatus {
  /// NFC scanned, waiting for motion confirmation.
  pending,

  /// Trip is active and recording.
  active,

  /// Short pause, trip remains open.
  paused,

  /// Long pause or different activity suspected; awaiting resolution.
  suspectedForgotten,

  /// Trip finished but flagged for review.
  needsReview,

  /// Trip confirmed and persisted.
  completed,

  /// NFC scanned without subsequent motion.
  cancelled,
}
