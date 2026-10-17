import 'package:flutter/material.dart';

import '../data/trips/projected_trip_repository.dart';
import '../presentation/ride_presentation.dart';
import '../presentation/ride_route.dart';
import 'ride_detail_screen.dart';
import 'ride_map_view.dart';

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({
    super.key,
    required this.trips,
    this.mapClient,
    this.embedded = false,
  });

  final ProjectedTripRepository trips;
  final RouteMapClient? mapClient;
  final bool embedded;

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
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not load your rides. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!),
                TextButton(onPressed: _refresh, child: const Text('Try again')),
              ],
            ),
          )
        : _history == null
        ? const Center(child: CircularProgressIndicator())
        : _history!.isEmpty
        ? const Center(
            child: Text(
              'No completed rides yet. Your rides will appear here after you stop recording.',
            ),
          )
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Your rides',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              for (final evidence in _history!) ...[
                Builder(
                  builder: (context) {
                    final route = RideRoute.fromEvidence(evidence);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => RideDetailScreen(
                              evidence: evidence,
                              mapClient: widget.mapClient,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                RidePresentation.time(
                                  evidence.trip.startTimeUtc,
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                RidePresentation.state(
                                  evidence.trip.status.name,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                RidePresentation.distance(route),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(RidePresentation.reliability(route)),
                              const SizedBox(height: 8),
                              const Text('View ride details  →'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          );
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: body,
    );
  }
}
