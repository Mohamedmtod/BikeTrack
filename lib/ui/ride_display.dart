import '../domain/trip/distance_status.dart';
import '../presentation/ride_route.dart';

abstract final class RideDisplayConfig {
  static const millisecondsPerSecond = 1000;
  static const metersPerKilometer = 1000;
  static const mapHeight = 270.0;
  static const refreshInterval = Duration(seconds: 1);
}

String rideDistance(RideRoute route) {
  if (route.distanceM == null || route.status == DistanceStatus.unknown) {
    return 'Distance unknown';
  }
  return '${(route.distanceM! / RideDisplayConfig.metersPerKilometer).toStringAsFixed(2)} km (${route.status.name})';
}

String rideTime(int? timestamp) => timestamp == null
    ? 'Unknown'
    : DateTime.fromMillisecondsSinceEpoch(timestamp)
          .toLocal()
          .toString()
          .split('.')
          .first;

String elapsedTime(int startMs, int nowMs) {
  final seconds =
      ((nowMs - startMs).clamp(0, 1 << 62) /
              RideDisplayConfig.millisecondsPerSecond)
          .floor();
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainder = seconds % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainder.toString().padLeft(2, '0')}';
}
