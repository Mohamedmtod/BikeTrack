import 'package:flutter/material.dart';

import '../data/trips/projected_trip_repository.dart';
import '../presentation/ride_route.dart';
import 'ride_detail_screen.dart';
import 'ride_display.dart';
import 'ride_map_view.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key, required this.trips, this.mapClient});

  final ProjectedTripRepository trips;
  final RouteMapClient? mapClient;

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen> {
  List<ProjectedTripEvidence>? _history;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final history = await widget.trips.history();
      if (mounted) {
        setState(() {
          _history = history;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Ride history')),
    body: _error != null
        ? Center(child: Text('Could not load rides: $_error'))
        : _history == null
        ? const Center(child: CircularProgressIndicator())
        : _history!.isEmpty
        ? const Center(child: Text('No completed rides yet'))
        : ListView(
            children: [
              for (final evidence in _history!)
                ListTile(
                  title: Text('Ride ${rideTime(evidence.trip.startTimeUtc)}'),
                  subtitle: Text(
                    'Ended: ${rideTime(evidence.trip.endTimeUtc)} · ${rideDistance(RideRoute.fromEvidence(evidence))} · Reliability: ${RideRoute.fromEvidence(evidence).status.name}',
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RideDetailScreen(
                        evidence: evidence,
                        mapClient: widget.mapClient,
                      ),
                    ),
                  ),
                ),
            ],
          ),
  );
}
