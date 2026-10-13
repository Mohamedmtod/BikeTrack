/// Core domain enums based on engineering plan §5.1 and decisions (D-011).
library;

/// Physical activity classification (§5.1).
enum ActivityType { stationary, walking, running, cycling, automotive, unknown }

/// Confidence level for classifications and detections (§5.1).
enum Confidence { low, medium, high }

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

  /// Trip automatically closed after prolonged inactivity/suspension.
  autoClosed,
}

/// Activity type within a trip segment, or gap in recording (§5.1).
enum SegmentType { cycling, walking, automotive, unknown, gap }

/// Sensor and location recording fidelity state (§5.1).
enum RecordingState { off, lowPower, highAccuracy }

/// Originating source of an event (§5.1).
enum EventSource { motion, pedometer, gps, nfc, user, system, health }

/// Source used to determine an activity classification (§5.1).
enum ClassificationSource { coreMotion, fused, nfc, user }

/// Distance reliability indicator (D-011, §5.2).
enum DistanceStatus { measured, partial, unknown }
