import '../app/recorder_runtime.dart';
import '../domain/trip/distance_status.dart';
import 'ride_route.dart';

enum RideHomeState { ready, recording, stopping, attention }

abstract final class RidePresentation {
  static RideHomeState homeState({
    required RecorderActivity activity,
    required bool hasOpenRide,
    required bool stopping,
    required bool blocked,
    required bool error,
  }) {
    if (blocked || error) return RideHomeState.attention;
    if (stopping) return RideHomeState.stopping;
    if (hasOpenRide && activity == RecorderActivity.idle) {
      return RideHomeState.attention;
    }
    if (activity == RecorderActivity.recording) {
      return RideHomeState.recording;
    }
    return RideHomeState.ready;
  }

  static String homeTitle(RideHomeState state) => switch (state) {
    RideHomeState.ready => 'Ready to ride',
    RideHomeState.recording => 'Recording',
    RideHomeState.stopping => 'Stopping…',
    RideHomeState.attention => 'Ride needs attention',
  };

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String distance(RideRoute? route) {
    if (route?.distanceM == null || route!.status == DistanceStatus.unknown) {
      return 'Distance unavailable';
    }
    return '${(route.distanceM! / 1000).toStringAsFixed(2)} km';
  }

  static String reliability(RideRoute? route) => switch (route?.status) {
    DistanceStatus.measured => 'Measured distance',
    DistanceStatus.partial => 'Partial distance · some sections missing',
    _ => 'Distance not yet available',
  };

  static String state(String status) => switch (status) {
    'completed' => 'Completed',
    'needsReview' => 'Needs review',
    'paused' => 'Paused',
    'suspectedForgotten' => 'Needs review',
    'pending' => 'Starting',
    'active' => 'Recording',
    _ => 'Ride',
  };

  static String time(int? timestamp) {
    if (timestamp == null) return 'Not available';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp).toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year} · $hour:$minute ${date.hour < 12 ? 'AM' : 'PM'}';
  }

  static String elapsed(int startMs, int nowMs) {
    final seconds = ((nowMs - startMs).clamp(0, 1 << 62) / 1000).floor();
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainder = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
  }

  static String locationStatus(RideRoute? route, {required bool recording}) {
    if (route == null || route.pieces.isEmpty) {
      return recording
          ? 'Waiting for a GPS location…'
          : 'Your route will appear here when you ride.';
    }
    if (route.status == DistanceStatus.partial) {
      return 'Some parts of this route could not be recorded.';
    }
    return recording ? 'Your route is being recorded.' : 'Route recorded.';
  }
}
