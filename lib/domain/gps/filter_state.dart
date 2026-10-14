import 'gps_sample.dart';

/// Mutable state carried between [GpsFilter.step] calls.
///
/// Three references are kept separate (C3 / D-010 / D-020):
/// - [lastRawTsMs] — timestamp of every point passing checks 1–4; used for
///   out-of-order and gap detection.
/// - [lastTrusted] — last point NOT rejected at checks 6–7; used for
///   instantaneous speed and spike detection.
/// - [anchor] — the reference point for distance computation; reset on gaps/stops.
/// - [prevSpeedMps] — instantaneous speed lastTrusted→current (D-020).
/// - [anchorClearedConservatively] — true when anchor was cleared by a
///   conservative rejection (impossibleSpeed / spike); false otherwise.
///   When true, the next anchorReset candidate is also checked for speed /
///   spike vs [lastTrusted] to prevent cascades from consecutive outliers.
class FilterState {
  /// Timestamp of the last sample that passed checks 1–4 (ordering + gap).
  /// Null until the very first valid sample.
  final int? lastRawTsMs;

  /// Last sample that passed checks 1–4 AND was not rejected at checks 6–7.
  /// Used for instantaneous speed and spike detection (D-020).
  /// Null until the very first trusted point.
  final GpsSample? lastTrusted;

  /// Reference point from which distance is accumulated.
  /// Null = anchor not established; next valid point becomes anchor at distance 0.
  final GpsSample? anchor;

  /// Instantaneous speed (m/s) from lastTrusted→current at the previous step.
  /// 0 when there is no lastTrusted or after a gap reset (D-020).
  final double prevSpeedMps;

  /// Set when impossibleSpeed/spike clears the anchor. Persists through checks 1-4 rejections.
  /// Cleared by: successful guarded anchorReset, resetAnchor(), stationary path, gap reset. See D-021.
  final bool anchorClearedConservatively;

  const FilterState({
    this.lastRawTsMs,
    this.lastTrusted,
    this.anchor,
    this.prevSpeedMps = 0.0,
    this.anchorClearedConservatively = false,
  });

  /// Returns a copy with [anchor] cleared; caller uses this on
  /// pause / segment-change / relaunch (D-010).
  FilterState withAnchorCleared() => FilterState(
    lastRawTsMs: lastRawTsMs,
    lastTrusted: lastTrusted,
    anchor: null,
    prevSpeedMps: prevSpeedMps,
    anchorClearedConservatively: false, // deliberate reset — not conservative
  );

  FilterState copyWith({
    int? lastRawTsMs,
    GpsSample? lastTrusted,
    GpsSample? anchor,
    bool clearAnchor = false,
    double? prevSpeedMps,
    bool anchorClearedConservatively = false,
  }) {
    return FilterState(
      lastRawTsMs: lastRawTsMs ?? this.lastRawTsMs,
      lastTrusted: lastTrusted ?? this.lastTrusted,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
      prevSpeedMps: prevSpeedMps ?? this.prevSpeedMps,
      anchorClearedConservatively: anchorClearedConservatively,
    );
  }
}
