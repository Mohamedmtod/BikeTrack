import 'package:biketrack/data/database/app_database.dart';
import 'package:biketrack/domain/trip/distance_status.dart';
import 'package:biketrack/domain/trip/segment_type.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:drift/drift.dart';

Future<void> seedTrip(
  AppDatabase db,
  String id, {
  TripStatus status = TripStatus.completed,
  int start = 1000,
  int? end = 3000,
}) async {
  await db
      .into(db.trips)
      .insert(
        TripsCompanion.insert(
          tripId: id,
          status: status,
          startTimeUtc: start,
          endTimeUtc: Value(end),
          nfcConfirmed: false,
          distanceStatus: DistanceStatus.unknown,
          movingDurationS: 0,
          pausedDurationS: 0,
          suspendedDurationS: 0,
          createdAt: start,
          updatedAt: end ?? start,
        ),
      );
}

Future<void> seedSegment(
  AppDatabase db,
  String id,
  String tripId, {
  SegmentType type = SegmentType.cycling,
  int start = 1000,
  int end = 2000,
}) async {
  await db
      .into(db.segments)
      .insert(
        SegmentsCompanion.insert(
          segmentId: id,
          tripId: tripId,
          type: type,
          startUtc: start,
          endUtc: end,
          distanceStatus: DistanceStatus.unknown,
          movingS: 0,
          confidence: 1,
          classificationSource: 'user',
          userCorrected: false,
          needsReview: false,
        ),
      );
}

Future<void> seedPoint(
  AppDatabase db,
  int id,
  String segmentId, {
  int? ts,
  double lat = 0,
  double lon = 0,
  bool accepted = true,
  String? reason,
}) async {
  await db
      .into(db.gpsPoints)
      .insert(
        GpsPointsCompanion.insert(
          id: Value(id),
          segmentId: segmentId,
          tsUtc: ts ?? id * 1000,
          lat: lat,
          lon: lon,
          hAccuracyM: 1,
          accepted: accepted,
          rejectReason: Value(reason),
        ),
      );
}
