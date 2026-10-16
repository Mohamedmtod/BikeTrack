import 'dart:convert';

import 'package:biketrack/data/projection/projection_snapshot.dart';
import 'package:biketrack/domain/activity/activity_type.dart';
import 'package:biketrack/domain/geo/geo_point.dart';
import 'package:biketrack/domain/gps/filter_state.dart';
import 'package:biketrack/domain/gps/gps_sample.dart';
import 'package:biketrack/domain/trip/segment_type.dart';
import 'package:biketrack/domain/trip/trip_close_reason.dart';
import 'package:biketrack/domain/trip/trip_state.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips every projection snapshot field through explicit JSON', () {
    const snapshot = ProjectionSnapshot(
      cursor: 42,
      filterState: FilterState(
        lastRawTsMs: 11,
        lastTrusted: GpsSample(
          tsMs: 12,
          position: GeoPoint(30.1, 31.2),
          hAccuracyM: 3.4,
        ),
        anchor: GpsSample(
          tsMs: 13,
          position: GeoPoint(30.3, 31.4),
          hAccuracyM: 5.6,
        ),
        prevSpeedMps: 7.8,
        anchorClearedConservatively: true,
      ),
      tripState: TripState(
        status: TripStatus.needsReview,
        tripStartMs: 21,
        pendingSinceMs: 22,
        pausedSinceMs: 23,
        suspectedSinceMs: 24,
        segmentType: SegmentType.gap,
        segmentStartMs: 25,
        lastActivityType: ActivityType.automotive,
        lastActivitySinceMs: 26,
        lastKnownMovementMs: 27,
        closeReason: TripCloseReason.recoveredAfterGap,
        lastEventMs: 28,
      ),
      activeTripId: 'trip-1',
      activeSegmentId: 'segment-1',
      pendingManualStartAttemptId: 'attempt-1',
      pendingManualStartRequestedAtMs: 29,
    );

    final encoded = ProjectionSnapshotCodec.encode(snapshot);
    final decoded = ProjectionSnapshotCodec.decode(encoded);
    final json = jsonDecode(encoded) as Map<String, dynamic>;

    expect(json['version'], ProjectionSnapshotCodec.version);
    expect(json['tripState']['status'], 'needsReview');
    expect(decoded.cursor, snapshot.cursor);
    expect(decoded.filterState.lastRawTsMs, 11);
    expect(decoded.filterState.lastTrusted!.tsMs, 12);
    expect(
      decoded.filterState.lastTrusted!.position,
      const GeoPoint(30.1, 31.2),
    );
    expect(decoded.filterState.anchor!.tsMs, 13);
    expect(decoded.filterState.anchor!.position, const GeoPoint(30.3, 31.4));
    expect(decoded.filterState.prevSpeedMps, 7.8);
    expect(decoded.filterState.anchorClearedConservatively, isTrue);
    expect(decoded.tripState, snapshot.tripState);
    expect(decoded.activeTripId, 'trip-1');
    expect(decoded.activeSegmentId, 'segment-1');
    expect(decoded.pendingManualStartAttemptId, 'attempt-1');
    expect(decoded.pendingManualStartRequestedAtMs, 29);
  });

  test('rejects unsupported snapshot versions', () {
    expect(
      () => ProjectionSnapshotCodec.decode('{"version":99}'),
      throwsUnsupportedError,
    );
  });
}
