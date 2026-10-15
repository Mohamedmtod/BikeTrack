import '../domain/geo/geo_point.dart';
import '../domain/gps/gps_sample.dart';
import 'generated/recorder.g.dart' as pigeon;

class RecorderStart {
  const RecorderStart({required this.started, this.rideId, this.reason});

  final bool started;
  final String? rideId;
  final String? reason;

  factory RecorderStart.fromPigeon(pigeon.RecorderStartResult result) {
    return RecorderStart(
      started: result.started,
      rideId: result.rideId,
      reason: result.reason,
    );
  }
}

class RecorderState {
  const RecorderState({
    required this.recording,
    this.rideId,
    required this.authorization,
  });

  final bool recording;
  final String? rideId;
  final String authorization;

  factory RecorderState.fromPigeon(pigeon.RecorderStatus status) {
    return RecorderState(
      recording: status.recording,
      rideId: status.rideId,
      authorization: status.authorization,
    );
  }
}

class RecorderFix {
  const RecorderFix({required this.sample, required this.recvMs, this.rideId});

  final GpsSample sample;
  final int recvMs;
  final String? rideId;

  factory RecorderFix.fromPigeon(pigeon.NativeGpsFix fix) {
    return RecorderFix(
      sample: GpsSample(
        tsMs: fix.fixTsMs,
        position: GeoPoint(fix.latitudeDeg, fix.longitudeDeg),
        hAccuracyM: fix.hAccuracyM,
      ),
      recvMs: fix.recvMs,
      rideId: fix.rideId,
    );
  }
}

class RecorderLocationUpdate {
  const RecorderLocationUpdate({required this.started, this.rideId});

  final bool started;
  final String? rideId;

  factory RecorderLocationUpdate.fromPigeon(
    pigeon.RecorderLocationUpdate update,
  ) {
    return RecorderLocationUpdate(
      started: update.started,
      rideId: update.rideId,
    );
  }
}

class RecorderAuthorizationChange {
  const RecorderAuthorizationChange(this.authorization);

  final String authorization;

  factory RecorderAuthorizationChange.fromPigeon(
    pigeon.RecorderAuthorizationChange change,
  ) {
    return RecorderAuthorizationChange(change.authorization);
  }
}

class RecorderLocationError {
  const RecorderLocationError({
    required this.code,
    required this.message,
    this.rideId,
  });

  final String code;
  final String message;
  final String? rideId;

  factory RecorderLocationError.fromPigeon(pigeon.RecorderLocationError error) {
    return RecorderLocationError(
      code: error.code,
      message: error.message,
      rideId: error.rideId,
    );
  }
}
