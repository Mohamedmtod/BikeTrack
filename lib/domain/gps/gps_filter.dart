/// Pure-Dart GPS filter implementing the two-reference design (C3 / §7.2).
///
/// No Flutter imports, no DateTime.now(), no side effects. All timestamps
/// are injected as [int] milliseconds-since-epoch.
library;

import '../geo/geo_point.dart';
import '../geo/haversine.dart';
import 'filter_result.dart';
import 'filter_state.dart';
import 'gps_filter_config.dart';
import 'gps_sample.dart';
import 'reject_reason.dart';

extension _FilterStateCopyWith on FilterState {
  FilterState _copyWith({
    int? lastRawTsMs,
    GpsSample? lastTrusted,
    GpsSample? anchor,
    bool clearAnchor = false,
    double? prevSpeedMps,
    bool anchorClearedConservatively = false,
  }) => copyWith(
    lastRawTsMs: lastRawTsMs,
    lastTrusted: lastTrusted,
    anchor: anchor,
    clearAnchor: clearAnchor,
    prevSpeedMps: prevSpeedMps,
    anchorClearedConservatively: anchorClearedConservatively,
  );
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
    // Checks 1-4: basic validity.  lastRawTsMs is updated for any point
    // that clears these four gates (D-020).
    // ------------------------------------------------------------------

    // 1. Invalid input — sensor error: negative, NaN, or non-finite accuracy;
    //    or non-finite coordinates.
    if (!p.hAccuracyM.isFinite ||
        p.hAccuracyM < 0 ||
        !p.position.latDeg.isFinite ||
        !p.position.lonDeg.isFinite) {
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

    // 4. Out-of-order delivery (uses lastRawTsMs per D-020).
    if (s.lastRawTsMs != null && p.tsMs <= s.lastRawTsMs!) {
      return FilterResult(
        newState: s,
        accepted: false,
        reason: RejectReason.outOfOrder,
      );
    }

    // ---- Point has cleared checks 1-4; it will update lastRawTsMs. ----

    // Compute instantaneous speed from lastTrusted to p (D-020).
    // Used for spike detection and prevSpeedMps on trusted paths.
    double instantSpeedMps = 0.0;
    if (s.lastTrusted != null) {
      final dInst = haversineMeters(s.lastTrusted!.position, p.position);
      final dtR = (p.tsMs - s.lastTrusted!.tsMs) / 1000.0;
      if (dtR > 0) {
        instantSpeedMps = dInst / dtR;
      }
    }

    // Gap detection: if the time since the previous raw point exceeds
    // gapMs, clear the anchor so we don't compute distance across the gap.
    // Uses lastRawTsMs for ordering/gap (D-020).
    GpsSample? newAnchor = s.anchor;
    bool isGapReset = false;
    if (s.lastRawTsMs != null && (p.tsMs - s.lastRawTsMs!) > cfg.gapMs) {
      newAnchor = null;
      isGapReset = true;
    }

    // Anchor not established → this point becomes the anchor at distance 0.
    // prevSpeedMps (D-020):
    //   • 0 when there is no lastTrusted (first ever trusted point), or after
    //     a gap reset.
    //   • instantaneous from lastTrusted otherwise — avoids cascading spike
    //     loop on the first normal step after a conservative rejection.
    //
    // When the anchor was cleared by a conservative rejection
    // (anchorClearedConservatively = true), run impossibleSpeed and spike
    // checks vs. lastTrusted before accepting as anchorReset.  This catches
    // a second consecutive outlier that would otherwise bypass checks 6-7.
    if (newAnchor == null) {
      // Guard against consecutive outliers bypassing checks 6-7.
      if (s.anchorClearedConservatively &&
          s.lastTrusted != null &&
          !isGapReset) {
        // 6-anc. Impossibly fast from lastTrusted (no anchor to compare against).
        if (instantSpeedMps > cfg.maxSpeedMps) {
          final newState = FilterState(
            lastRawTsMs: p.tsMs,
            lastTrusted: s.lastTrusted,
            anchor: null,
            prevSpeedMps: s.prevSpeedMps,
            anchorClearedConservatively: true,
          );
          return FilterResult(
            newState: newState,
            accepted: false,
            reason: RejectReason.impossibleSpeed,
          );
        }

        // 7-anc. Spike from lastTrusted (no anchor).
        final dtR = (p.tsMs - s.lastTrusted!.tsMs) / 1000.0;
        if (dtR > 0) {
          final accel = (instantSpeedMps - s.prevSpeedMps).abs() / dtR;
          if (accel > cfg.maxAccelMps2) {
            final newState = FilterState(
              lastRawTsMs: p.tsMs,
              lastTrusted: s.lastTrusted,
              anchor: null,
              prevSpeedMps: s.prevSpeedMps,
              anchorClearedConservatively: true,
            );
            return FilterResult(
              newState: newState,
              accepted: false,
              reason: RejectReason.spike,
            );
          }
        }
      }

      final newState = FilterState(
        lastRawTsMs: p.tsMs,
        lastTrusted: p,
        anchor: p,
        prevSpeedMps: (s.lastTrusted == null || isGapReset)
            ? 0.0
            : instantSpeedMps,
        anchorClearedConservatively: false,
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
    //    D-020: update lastRawTsMs, clear anchor; do NOT update lastTrusted or
    //    prevSpeedMps.
    if (vFromAnchor > cfg.maxSpeedMps) {
      final newState = FilterState(
        lastRawTsMs: p.tsMs,
        lastTrusted: s.lastTrusted, // unchanged (D-020)
        anchor: null, // conservative: clear anchor
        prevSpeedMps: s.prevSpeedMps, // unchanged (D-020)
        anchorClearedConservatively: true,
      );
      return FilterResult(
        newState: newState,
        accepted: false,
        reason: RejectReason.impossibleSpeed,
      );
    }

    // 7. Spike: instantaneous acceleration from lastTrusted exceeds maxAccelMps2.
    //    D-020: update lastRawTsMs, clear anchor; do NOT update lastTrusted or
    //    prevSpeedMps.
    if (s.lastTrusted != null) {
      final dtR = (p.tsMs - s.lastTrusted!.tsMs) / 1000.0;
      if (dtR > 0) {
        final accel = (instantSpeedMps - s.prevSpeedMps).abs() / dtR;
        if (accel > cfg.maxAccelMps2) {
          final newState = FilterState(
            lastRawTsMs: p.tsMs,
            lastTrusted: s.lastTrusted, // unchanged (D-020)
            anchor: null, // conservative: clear anchor
            prevSpeedMps: s.prevSpeedMps, // unchanged (D-020)
            anchorClearedConservatively: true,
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
    //    D-020: clear anchor, lastTrusted = p, prevSpeed = instantaneous
    //    (not forced 0 — instantSpeedMps may be 0 if no lastTrusted).
    if (isStationary) {
      final newState = FilterState(
        lastRawTsMs: p.tsMs,
        lastTrusted: p,
        anchor: null, // conservative: clear anchor
        prevSpeedMps: instantSpeedMps,
        anchorClearedConservatively: false, // deliberate — not conservative
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
        lastRawTsMs: p.tsMs,
        lastTrusted: p,
        anchor: anchor, // unchanged
        prevSpeedMps:
            instantSpeedMps, // D-020: always instantaneous from lastTrusted
        anchorClearedConservatively: false,
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
      lastRawTsMs: p.tsMs,
      lastTrusted: p,
      anchor: p, // advance anchor
      prevSpeedMps:
          instantSpeedMps, // D-020: always instantaneous from lastTrusted
      anchorClearedConservatively: false,
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

  /// Resets the anchor in [s] without touching [lastRawTsMs], [lastTrusted],
  /// or [prevSpeedMps].
  ///
  /// Callers MUST invoke this on pause, segment-change, or relaunch (D-010).
  /// The next [step] call will set a fresh anchor at distance 0.
  static FilterState resetAnchor(FilterState s) => s.withAnchorCleared();
}
