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
import '../presentation/ride_presentation.dart';
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
  bool _stopping = false;
  int _tab = 0;
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
      if (mounted && _active != null && _tab == 0) setState(() {});
    });
    _refresh();
  }

  void _onRuntime() {
    if (_lastRevision != widget.runtime.projectionRevision) {
      _lastRevision = widget.runtime.projectionRevision;
      _refresh();
    }
  }

  Future<void> _refresh({bool clearError = false}) async {
    final revision = ++_readRevision;
    try {
      final active = await widget.trips.active();
      if (mounted && revision == _readRevision) {
        setState(() {
          _active = active;
          _route = active == null ? null : RideRoute.fromEvidence(active);
          if (clearError) _error = null;
        });
      }
    } catch (_) {
      if (mounted && revision == _readRevision) {
        setState(
          () => _error = 'Could not load your ride. Try again or open Debug.',
        );
      }
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final attemptId = '${_now.microsecondsSinceEpoch}-${++_attemptSequence}';
      final result = await widget.session.startManual(attemptId);
      if (!result.started && mounted) {
        setState(
          () => _error =
              'Ride could not start. Check location access or open Debug.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Ride could not start. Check location access or open Debug.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() {
      _busy = true;
      _stopping = true;
      _error = null;
    });
    try {
      await widget.session.stopManual();
      await widget.projections.drained;
      await _refresh();
      if (mounted &&
          _active == null &&
          widget.runtime.projectionState != ProjectionDrainState.blocked) {
        setState(() => _tab = 1);
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Ride could not be saved normally. Check History or open Debug.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _stopping = false;
        });
      }
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('BikeTrack')),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tab == 0) _rideAction(),
        NavigationBar(
          selectedIndex: _tab,
          onDestinationSelected: (index) {
            if (index == 0) _refresh();
            setState(() => _tab = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.directions_bike),
              label: 'Ride',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
            NavigationDestination(
              icon: Icon(Icons.bug_report_outlined),
              label: 'Debug',
            ),
          ],
        ),
      ],
    ),
    body: switch (_tab) {
      0 => _rideBody(),
      1 => RideHistoryScreen(
        trips: widget.trips,
        mapClient: widget.mapClient,
        embedded: true,
      ),
      _ => RecorderDebugScreen(
        session: widget.session,
        runtime: widget.runtime,
        repository: widget.events,
        projections: widget.projections,
        exporter: widget.exporter,
        embedded: true,
      ),
    },
  );

  Widget _rideAction() => ListenableBuilder(
    listenable: widget.runtime,
    builder: (context, _) {
      final activity = widget.runtime.activity;
      final recording = activity == RecorderActivity.recording;
      final state = RidePresentation.homeState(
        activity: activity,
        hasOpenRide: _active != null,
        stopping: _stopping,
        blocked: widget.runtime.projectionState == ProjectionDrainState.blocked,
        error: _error != null,
      );
      if (!recording && (state != RideHomeState.ready || _active != null)) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: _busy || activity == RecorderActivity.starting
                ? null
                : recording
                ? _stop
                : _start,
            icon: Icon(
              recording ? Icons.stop_circle_outlined : Icons.play_arrow,
            ),
            label: Text(recording ? 'Stop Ride' : 'Start Ride'),
          ),
        ),
      );
    },
  );

  Widget _rideBody() => ListenableBuilder(
    listenable: widget.runtime,
    builder: (context, _) {
      final activity = widget.runtime.activity;
      final recording = activity == RecorderActivity.recording;
      final blocked =
          widget.runtime.projectionState == ProjectionDrainState.blocked;
      final state = RidePresentation.homeState(
        activity: activity,
        hasOpenRide: _active != null,
        stopping: _stopping,
        blocked: blocked,
        error: _error != null,
      );
      final route = _route;
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            RidePresentation.homeTitle(state),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(switch (state) {
            RideHomeState.ready => 'Tap Start Ride when you are ready to go.',
            RideHomeState.recording => 'Your ride is in progress.',
            RideHomeState.stopping => 'Finishing and saving your ride…',
            RideHomeState.attention =>
              blocked
                  ? 'Your route is not updating. Open Debug to retry.'
                  : _error ??
                        (_active != null && activity == RecorderActivity.idle
                            ? 'Recording stopped, but this ride is still open. Open Debug to check it.'
                            : 'Check your ride in History or open Debug.'),
          }),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: SizedBox(
                height: RideDisplayConfig.mapHeight,
                child: RideMapView(
                  route:
                      route ??
                      const RideRoute([], null, DistanceStatus.unknown),
                  client: widget.mapClient,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (recording || _active != null) ...[
            if (_active != null)
              Text(
                'Elapsed  ${RidePresentation.elapsed(_active!.trip.startTimeUtc, _now.millisecondsSinceEpoch)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            Text(
              RidePresentation.distance(route),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(RidePresentation.reliability(route)),
            const SizedBox(height: 8),
            Text(RidePresentation.locationStatus(route, recording: recording)),
            const SizedBox(height: 20),
          ],
          if (state == RideHomeState.attention && !recording)
            TextButton(
              onPressed: () => _refresh(clearError: true),
              child: const Text('Try again'),
            ),
        ],
      );
    },
  );
}
