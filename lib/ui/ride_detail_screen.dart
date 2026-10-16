import 'package:flutter/material.dart';

import '../data/trips/projected_trip_repository.dart';
import '../domain/trip/segment_type.dart';
import '../presentation/ride_route.dart';
import 'ride_display.dart';
import 'ride_map_view.dart';

class RideDetailScreen extends StatelessWidget {
  const RideDetailScreen({super.key, required this.evidence, this.mapClient});

  final ProjectedTripEvidence evidence;
  final RouteMapClient? mapClient;

  @override
  Widget build(BuildContext context) {
    final route = RideRoute.fromEvidence(evidence);
    return Scaffold(
      appBar: AppBar(title: const Text('Ride detail')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: RideDisplayConfig.mapHeight,
            child: RideMapView(route: route, client: mapClient),
          ),
          Text('Started: ${rideTime(evidence.trip.startTimeUtc)}'),
          Text('Ended: ${rideTime(evidence.trip.endTimeUtc)}'),
          Text('Status: ${evidence.trip.status.name}'),
          Text(rideDistance(route)),
          Text('Reliability: ${route.status.name}'),
          const Text('Segments'),
          for (final segment in evidence.segments)
            ListTile(
              title: Text(
                segment.type == SegmentType.gap ? 'GPS gap' : segment.type.name,
              ),
              subtitle: Text(
                '${rideTime(segment.startUtc)} — ${rideTime(segment.endUtc)}',
              ),
            ),
        ],
      ),
    );
  }
}
