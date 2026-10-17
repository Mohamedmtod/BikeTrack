import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../bridge/generated/recorder.g.dart' as pigeon;
import '../presentation/ride_route.dart';

abstract class RouteMapClient {
  Future<void> updateRoute(int viewId, List<pigeon.MapRoutePiece> pieces);
}

class PigeonRouteMapClient implements RouteMapClient {
  PigeonRouteMapClient([pigeon.RouteMapHostApi? api])
    : _api = api ?? pigeon.RouteMapHostApi();

  final pigeon.RouteMapHostApi _api;

  @override
  Future<void> updateRoute(int viewId, List<pigeon.MapRoutePiece> pieces) =>
      _api.updateRoute(viewId, pieces);
}

List<pigeon.MapRoutePiece> routePayload(RideRoute route) => [
  for (final piece in route.pieces)
    pigeon.MapRoutePiece(
      points: [
        for (final point in piece)
          pigeon.MapCoordinate(
            latitudeDeg: point.latDeg,
            longitudeDeg: point.lonDeg,
          ),
      ],
    ),
];

class RideMapView extends StatefulWidget {
  const RideMapView({
    super.key,
    required this.route,
    this.client,
    this.emptyMessage = 'Waiting for a GPS location…',
  });

  final RideRoute route;
  final RouteMapClient? client;
  final String emptyMessage;

  @override
  State<RideMapView> createState() => _RideMapViewState();
}

class _RideMapViewState extends State<RideMapView> {
  int? _viewId;
  int _revision = 0;
  String? _error;

  void _update() {
    final viewId = _viewId;
    if (viewId == null) return;
    final revision = ++_revision;
    (widget.client ?? PigeonRouteMapClient())
        .updateRoute(viewId, routePayload(widget.route))
        .then((_) {
          if (mounted && revision == _revision && _error != null) {
            setState(() => _error = null);
          }
        })
        .catchError((Object error) {
          if (mounted && revision == _revision) {
            setState(
              () => _error = 'Map unavailable right now. Your ride data is still available.',
            );
          }
        });
  }

  @override
  void didUpdateWidget(RideMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.route, widget.route)) _update();
  }

  @override
  void dispose() {
    _revision++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.route.pieces.isEmpty;
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return Center(
        child: Text(
          empty ? widget.emptyMessage : 'Route map is available on iPhone.',
          textAlign: TextAlign.center,
        ),
      );
    }
    return Stack(
      children: [
        UiKitView(
          viewType: 'biketrack/route-map',
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: (id) {
            _viewId = id;
            _update();
          },
        ),
        if (empty)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(widget.emptyMessage, textAlign: TextAlign.center),
              ),
            ),
          ),
        if (_error != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_error!),
              ),
            ),
          ),
      ],
    );
  }
}
