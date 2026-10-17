import 'package:flutter/material.dart';

import '../data/trips/projected_trip_repository.dart';
import '../domain/trip/distance_status.dart';
import '../domain/trip/segment_type.dart';
import '../presentation/ride_presentation.dart';
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
    final gaps = evidence.segments
        .where((segment) => segment.type == SegmentType.gap)
        .length;
    return Scaffold(
      appBar: AppBar(title: const Text('Ride detail')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Your ride', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SizedBox(
                height: RideDisplayConfig.mapHeight,
                child: RideMapView(
                  route: route,
                  client: mapClient,
                  emptyMessage: 'No route was recorded for this ride.',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            RidePresentation.distance(route),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(RidePresentation.reliability(route)),
          const SizedBox(height: 20),
          Text('Started  ${RidePresentation.time(evidence.trip.startTimeUtc)}'),
          const SizedBox(height: 8),
          Text('Ended  ${RidePresentation.time(evidence.trip.endTimeUtc)}'),
          const SizedBox(height: 8),
          Text('State  ${RidePresentation.state(evidence.trip.status.name)}'),
          if (gaps > 0) ...[
            const SizedBox(height: 20),
            Text(
              'Route interruptions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              gaps == 1
                  ? 'Location was unavailable for part of this ride. The route and distance do not connect across that break.'
                  : 'Location was unavailable for $gaps parts of this ride. The route and distance do not connect across those breaks.',
            ),
          ] else if (route.status == DistanceStatus.partial) ...[
            const SizedBox(height: 20),
            const Text(
              'Some route sections are missing. Distance includes only the parts we could measure.',
            ),
          ],
        ],
      ),
    );
  }
}
