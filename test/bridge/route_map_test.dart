import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/domain/geo/geo_point.dart';
import 'package:flutter/services.dart';
import 'package:biketrack/domain/trip/distance_status.dart';
import 'package:biketrack/presentation/ride_route.dart';
import 'package:biketrack/ui/ride_map_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Pigeon payload keeps separate route pieces and exact coordinate order',
    () {
      final route = RideRoute(
        [
          [const GeoPoint(1.2, 3.4), const GeoPoint(1.3, 3.5)],
          [const GeoPoint(9, -12)],
        ],
        100,
        DistanceStatus.partial,
      );
      final payload = routePayload(route);
      expect(payload, hasLength(2));
      expect(
        payload[0].points.map(
          (point) => [point.latitudeDeg, point.longitudeDeg],
        ),
        [
          [1.2, 3.4],
          [1.3, 3.5],
        ],
      );
      expect(payload[1].points.single.latitudeDeg, 9);
      expect(payload[1].points.single.longitudeDeg, -12);
      expect(
        routePayload(const RideRoute([], null, DistanceStatus.unknown)),
        isEmpty,
      );
    },
  );

  test(
    'typed Flutter-to-host Pigeon channel sends view ID and distinct pieces',
    () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      const channel =
          'dev.flutter.pigeon.biketrack.RouteMapHostApi.updateRoute';
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      Object? received;
      messenger.setMockDecodedMessageHandler(
        const BasicMessageChannel<Object?>(
          channel,
          pigeon.RouteMapHostApi.pigeonChannelCodec,
        ),
        (message) async {
          received = message;
          return <Object?>[null];
        },
      );
      addTearDown(
        () => messenger.setMockDecodedMessageHandler(
          const BasicMessageChannel<Object?>(
            channel,
            pigeon.RouteMapHostApi.pigeonChannelCodec,
          ),
          null,
        ),
      );
      await PigeonRouteMapClient().updateRoute(
        7,
        routePayload(
          RideRoute(
            [
              [const GeoPoint(1, 2), const GeoPoint(3, 4)],
              [const GeoPoint(5, 6)],
            ],
            1,
            DistanceStatus.partial,
          ),
        ),
      );
      final args = received! as List<Object?>;
      expect(args[0], 7);
      final pieces = args[1]! as List<Object?>;
      expect(pieces, hasLength(2));
      expect((pieces[0] as pigeon.MapRoutePiece).points[1].longitudeDeg, 4);
      expect((pieces[1] as pigeon.MapRoutePiece).points.single.latitudeDeg, 5);
    },
  );
}
