/// Pure-Dart GPS filter implementing the two-reference design (C3 / §7.2).
///
/// No Flutter imports, no DateTime.now(), no side effects. All timestamps
/// are injected as [int] milliseconds-since-epoch.
library;

import 'enums.dart';
import 'geo.dart';
import 'gps_filter_config.dart';

// Re-export config so callers can import a single file.
export 'gps_filter_config.dart';

// ---------------------------------------------------------------------------
// Data types
// ---------------------------------------------------------------------------

/// An incoming GPS measurement.
///
/// [tsMs] — device timestamp in milliseconds since epoch (NOT wall time).
/// [position] — WGS-84 coordinates.
/// [hAccuracyM] — horizontal accuracy radius in metres (σ or 68th percentile).
class GpsSample {
  final int tsMs;
  final GeoPoint position;
  final double hAccuracyM;

  const GpsSample({
    required this.tsMs,
    required this.position,
    required this.hAccuracyM,
  });
}

/// Mutable state carried between [GpsFilter.step] calls.
///
/// Both references are kept separate (C3 / D-010):
/// - [lastReceived] — every point that passes checks 1-4 updates this.
/// - [anchor] — the reference point for distance computation; reset on gaps/stops.
/// - [prevSpeedMps] — speed from anchor→lastReceived, used for spike detection.
class FilterState {
  /// Last sample that passed the basic validity checks (1-4).
  /// Null until the very first valid sample.
  final GpsSample? lastReceived;

  /// Reference point from which distance is accumulated.
  /// Null = anchor not established; next valid point becomes anchor at distance 0.
  final GpsSample? anchor;

  /// Speed (m/s) computed at the previous accepted step, for acceleration check.
  final double prevSpeedMps;

  const FilterState({this.lastReceived, this.anchor, this.prevSpeedMps = 0.0});

  /// Returns a copy with [anchor] cleared; caller uses this on
  /// pause / segment-change / relaunch (D-010).
  FilterState withAnchorCleared() => FilterState(
    lastReceived: lastReceived,
    anchor: null,
    prevSpeedMps: prevSpeedMps,
  );

  FilterState _copyWith({
    GpsSample? lastReceived,
    GpsSample? anchor,
    bool clearAnchor = false,
    double? prevSpeedMps,
  }) {
    return FilterState(
      lastReceived: lastReceived ?? this.lastReceived,
      anchor: clearAnchor ? null : (anchor ?? this.anchor),
      prevSpeedMps: prevSpeedMps ?? this.prevSpeedMps,
    );
  }
}

/// The value returned by [GpsFilter.step].
class FilterResult {
  /// The updated state to pass to the next [GpsFilter.step] call.
  final FilterState newState;

  /// Whether the point is accepted (contributes to the ride or resets anchor).
  ///
  /// true  → point passes all checks (may add distance, reset anchor, or be stationary).
  /// false → point rejected; [reason] explains why; [distanceAddedM] is always 0.
  final bool accepted;

  /// Why the point was not accepted outright, or how it was treated specially.
  /// Null only when [accepted] is true and the point genuinely added distance
  /// (normal forward movement).
  final RejectReason? reason;

  /// Distance in metres added to the running total by this point.
  /// 0 for rejected points, stationary gate, jitter, and anchor-reset.
  /// Positive only for a genuine forward-movement acceptance (check 10).
  final double distanceAddedM;

  const FilterResult({
    required this.newState,
    required this.accepted,
    this.reason,
    this.distanceAddedM = 0.0,
  });
}

// ---------------------------------------------------------------------------
// GpsFilter — pure functions
// ---------------------------------------------------------------------------

/// Stateless GPS filter; all state lives in [FilterState].
///
/// Usage:
/// ```dart
/// var state = const FilterState();
/// final cfg = const GpsFilterConfig();
///
/// for (final raw in incoming) {
///   final result = GpsFilter.step(state, raw, nowMs: clock(), isStationary: activity.isStationary, cfg: cfg);
///   state = result.newState;
///   if (result.accepted) total += result.distanceAddedM;
/// }
/// ```
abstract final class GpsFilter {
  GpsFilter._();

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Processes one GPS sample and returns ([FilterResult]).
  ///
  /// [s] — current state.
  /// [p] — incoming sample.
  /// [nowMs] — current wall-clock ms (injected; must not call DateTime.now()).
  /// [isStationary] — true when the activity classifier says the device is not moving.
  /// [cfg] — filter thresholds.
  static FilterResult step(
    FilterState s,
    GpsSample p, {
    required int nowMs,
    required bool isStationary,
    required GpsFilterConfig cfg,
  }) {
    // ------------------------------------------------------------------
    // Checks 1-4: basic validity.  lastReceived is updated for any point
    // that clears these four gates.
    // ------------------------------------------------------------------

    // 1. Negative accuracy — sensor error.
    if (p.hAccuracyM < 0) {
      return FilterResult(
        newState: s,
        accepted: false,
        reason: RejectReason.invalid,
      );
    }

    // 2. Poor fix.
    if (p.hAccuracyM > cfg.maxHAccuracyM) {
      return FilterResult(
        newState: s,
        accepted: false,
        reason: RejectReason.lowAccuracy,
      );
    }

    // 3. Stale point (arrived too late).
    if (nowMs - p.tsMs > cfg.staleMs) {
      return FilterResult(
        newState: s,
        accepted: false,
        reason: RejectReason.stale,
      );
    }

    // 4. Out-of-order delivery.
    if (s.lastReceived != null && p.tsMs <= s.lastReceived!.tsMs) {
      return FilterResult(
        newState: s,
        accepted: false,
        reason: RejectReason.outOfOrder,
      );
    }

    // ---- Point has cleared checks 1-4; it will update lastReceived. ----

    // Gap detection: if the time since the previous valid point exceeds
    // gapMs, clear the anchor so we don't compute distance across the gap.
    GpsSample? newAnchor = s.anchor;
    if (s.lastReceived != null && (p.tsMs - s.lastReceived!.tsMs) > cfg.gapMs) {
      newAnchor = null; // force anchor reset on next step
    }

    // Anchor not established → this point becomes the anchor at distance 0.
    if (newAnchor == null) {
      final newState = FilterState(
        lastReceived: p,
        anchor: p,
        prevSpeedMps: 0.0,
      );
      return FilterResult(
        newState: newState,
        accepted: true,
        reason: RejectReason.anchorReset,
        distanceAddedM: 0.0,
      );
    }

    // ------------------------------------------------------------------
    // Checks 5-10: motion quality against anchor.
    // ------------------------------------------------------------------
    final anchor = newAnchor; // non-null from here
    final d = haversineMeters(anchor.position, p.position);
    final dtA = (p.tsMs - anchor.tsMs) / 1000.0; // seconds from anchor

    // Guard: dtA must be positive (anchor != null and ordering already ensured).
    // In the degenerate case where tsMs == anchor.tsMs, treat as jitter.
    final vFromAnchor = dtA > 0 ? d / dtA : double.infinity;

    // 6. Impossibly fast from anchor.
    if (vFromAnchor > cfg.maxSpeedMps) {
      // Do not move anchor; update lastReceived and prevSpeed.
      final newState = s._copyWith(
        lastReceived: p,
        anchor: anchor,
        prevSpeedMps: vFromAnchor,
      );
      return FilterResult(
        newState: newState,
        accepted: false,
        reason: RejectReason.impossibleSpeed,
      );
    }

    // 7. Spike: instantaneous acceleration from lastReceived exceeds maxAccelMps2.
    if (s.lastReceived != null) {
      final dInst = haversineMeters(s.lastReceived!.position, p.position);
      final dtR = (p.tsMs - s.lastReceived!.tsMs) / 1000.0;
      if (dtR > 0) {
        final vInst = dInst / dtR;
        final accel = (vInst - s.prevSpeedMps).abs() / dtR;
        if (accel > cfg.maxAccelMps2) {
          final newState = s._copyWith(
            lastReceived: p,
            anchor: anchor,
            prevSpeedMps: vInst,
          );
          return FilterResult(
            newState: newState,
            accepted: false,
            reason: RejectReason.spike,
          );
        }
      }
    }

    // 8. Stationary gate — activity says the device is not moving.
    //    Accept the point (store it) but add 0 distance; do NOT move the anchor.
    if (isStationary) {
      final newState = FilterState(
        lastReceived: p,
        anchor: anchor, // unchanged
        prevSpeedMps: 0.0, // reset — standing still
      );
      return FilterResult(
        newState: newState,
        accepted: true,
        reason: RejectReason.stationaryGate,
        distanceAddedM: 0.0,
      );
    }

    // 9. Jitter — movement within the combined uncertainty circle.
    final jitterThreshold =
        (cfg.minStepM > 0.5 * (anchor.hAccuracyM + p.hAccuracyM))
        ? cfg.minStepM
        : 0.5 * (anchor.hAccuracyM + p.hAccuracyM);
    if (d < jitterThreshold) {
      final newState = s._copyWith(
        lastReceived: p,
        anchor: anchor, // unchanged
        prevSpeedMps: vFromAnchor,
      );
      return FilterResult(
        newState: newState,
        accepted: true,
        reason: RejectReason.jitter,
        distanceAddedM: 0.0,
      );
    }

    // 10. Accepted — genuine forward movement.
    final newState = FilterState(
      lastReceived: p,
      anchor: p, // advance anchor
      prevSpeedMps: vFromAnchor,
    );
    return FilterResult(
      newState: newState,
      accepted: true,
      reason: null,
      distanceAddedM: d,
    );
  }

  // -------------------------------------------------------------------------
  // Helper
  // -------------------------------------------------------------------------

  /// Resets the anchor in [s] without touching [lastReceived] or [prevSpeedMps].
  ///
  /// Callers MUST invoke this on pause, segment-change, or relaunch (D-010).
  /// The next [step] call will set a fresh anchor at distance 0.
  static FilterState resetAnchor(FilterState s) => s.withAnchorCleared();
}
