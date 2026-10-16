import 'dart:async';

import 'package:flutter/material.dart';

import '../app/projection_drain_coordinator.dart';
import '../app/recorder_runtime.dart';
import '../app/recorder_session.dart';
import '../data/diagnostics/diagnostic_bundle_exporter.dart';
import '../data/events/event_repository.dart';
import '../data/trips/projected_trip_repository.dart';
import '../debug/recorder_debug_screen.dart';
import '../domain/trip/distance_status.dart';
import '../presentation/ride_route.dart';
import 'ride_display.dart';
import 'ride_history_screen.dart';
import 'ride_map_view.dart';

class RidesScreen extends StatefulWidget {
  const RidesScreen({
    super.key,
    required this.session,
    required this.runtime,
    required this.trips,
    required this.events,
    required this.projections,
    required this.exporter,
    this.mapClient,
    this.clock,
  });

  final RecorderSession session;
  final RecorderRuntime runtime;
  final ProjectedTripRepository trips;
  final EventRepository events;
  final ProjectionDrainCoordinator projections;
  final DiagnosticBundleExporter exporter;
  final RouteMapClient? mapClient;
  final DateTime Function()? clock;

  @override
  State<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends State<RidesScreen> {
  ProjectedTripEvidence? _active;
  RideRoute? _route;
  String? _error;
  bool _busy = false;
  int _lastRevision = 0;
  int _readRevision = 0;
  int _attemptSequence = 0;
  Timer? _ticker;

  DateTime get _now => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    _lastRevision = widget.runtime.projectionRevision;
    widget.runtime.addListener(_onRuntime);
    _ticker = Timer.periodic(RideDisplayConfig.refreshInterval, (_) {
      if (mounted && _active != null) setState(() {});
    });
    _refresh();
  }

  void _onRuntime() {
    if (_lastRevision != widget.runtime.projectionRevision) {
      _lastRevision = widget.runtime.projectionRevision;
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final revision = ++_readRevision;
    try {
      final active = await widget.trips.active();
      if (mounted && revision == _readRevision) {
        setState(() {
          _active = active;
          _route = active == null ? null : RideRoute.fromEvidence(active);
          _error = null;
        });
      }
    } catch (error) {
      if (mounted && revision == _readRevision) {
        setState(() => _error = 'Could not load projected ride: $error');
      }
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      final attemptId = '${_now.microsecondsSinceEpoch}-${++_attemptSequence}';
      final result = await widget.session.startManual(attemptId);
      if (!result.started && mounted) {
        setState(
          () => _error = 'Start rejected: ${result.reason ?? 'unknown'}',
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not start ride: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    try {
      await widget.session.stopManual();
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not stop ride: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _readRevision++;
    _ticker?.cancel();
    widget.runtime.removeListener(_onRuntime);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final route = _route;
    final recording =
        widget.runtime.activity == RecorderActivity.recording ||
        widget.runtime.activity == RecorderActivity.starting;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BikeTrack'),
        actions: [
          IconButton(
            tooltip: 'Ride history',
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RideHistoryScreen(
                  trips: widget.trips,
                  mapClient: widget.mapClient,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Recorder diagnostics',
            icon: const Icon(Icons.bug_report_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => RecorderDebugScreen(
                  session: widget.session,
                  runtime: widget.runtime,
                  repository: widget.events,
                  projections: widget.projections,
                  exporter: widget.exporter,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: RideDisplayConfig.mapHeight,
            child: RideMapView(
              route: route ?? const RideRoute([], null, DistanceStatus.unknown),
              client: widget.mapClient,
            ),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: widget.runtime,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recorder: ${widget.runtime.activity.name}'),
                Text('Projections: ${widget.runtime.projectionState.name}'),
                if (widget.runtime.projectionState ==
                    ProjectionDrainState.blocked)
                  const Text(
                    'Route may be incomplete. Open diagnostics to retry projections.',
                  ),
              ],
            ),
          ),
          Text(
            _active == null
                ? 'No active projected ride'
                : 'Ride: ${_active!.trip.status.name}',
          ),
          Text(
            'Elapsed: ${_active == null ? '--:--:--' : elapsedTime(_active!.trip.startTimeUtc, _now.millisecondsSinceEpoch)}',
          ),
          Text(route == null ? 'Distance unknown' : rideDistance(route)),
          if (route != null) Text('Reliability: ${route.status.name}'),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 12),
          if (!recording && _active == null)
            FilledButton(
              onPressed: _busy ? null : _start,
              child: const Text('Start Ride'),
            ),
          if (recording || _active != null)
            FilledButton(
              onPressed: _busy ? null : _stop,
              child: const Text('Stop Ride'),
            ),
          TextButton(
            onPressed: _refresh,
            child: const Text('Refresh projected ride'),
          ),
        ],
      ),
    );
  }
}
