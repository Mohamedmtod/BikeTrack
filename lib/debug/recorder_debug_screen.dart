import 'package:flutter/material.dart';

import '../app/projection_drain_coordinator.dart';
import '../app/recorder_runtime.dart';
import '../app/recorder_session.dart';
import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';

class RecorderDebugScreen extends StatefulWidget {
  const RecorderDebugScreen({
    super.key,
    required this.session,
    required this.runtime,
    required this.repository,
    required this.projections,
  });

  final RecorderSession session;
  final RecorderRuntime runtime;
  final EventRepository repository;
  final ProjectionDrainCoordinator projections;

  @override
  State<RecorderDebugScreen> createState() => _RecorderDebugScreenState();
}

class _RecorderDebugScreenState extends State<RecorderDebugScreen> {
  static const _recentLimit = 20;
  final _attemptId = TextEditingController();
  List<StoredEvent> _events = [];
  String? _readError;
  late ProjectionDrainState _lastProjectionState;

  @override
  void initState() {
    super.initState();
    _lastProjectionState = widget.runtime.projectionState;
    widget.runtime.addListener(_onRuntimeChanged);
    _refresh();
  }

  void _onRuntimeChanged() {
    final state = widget.runtime.projectionState;
    if (state == _lastProjectionState) return;
    _lastProjectionState = state;
    if (state != ProjectionDrainState.draining) _refresh();
  }

  Future<void> _refresh() async {
    try {
      final events = await widget.repository.readRecent(_recentLimit);
      if (mounted) {
        setState(() {
          _events = events;
          _readError = null;
        });
      }
    } catch (error) {
      if (mounted) setState(() => _readError = '$error');
    }
  }

  Future<void> _start() async {
    try {
      await widget.session.startManual(_attemptId.text);
    } catch (_) {
      // The session reports the persistence or native failure in runtime state.
    } finally {
      await _refresh();
    }
  }

  Future<void> _stop() async {
    try {
      await widget.session.stopManual();
    } catch (_) {
      // The session reports the persistence or native failure in runtime state.
    } finally {
      await _refresh();
    }
  }

  Future<void> _retryProjections() async {
    await widget.projections.retry();
    await _refresh();
  }

  @override
  void dispose() {
    widget.runtime.removeListener(_onRuntimeChanged);
    _attemptId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorder debug')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _attemptId,
            decoration: const InputDecoration(labelText: 'Attempt ID'),
          ),
          Row(
            children: [
              ElevatedButton(onPressed: _start, child: const Text('Start')),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _stop, child: const Text('Stop')),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _refresh,
                tooltip: 'Refresh events',
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          ListenableBuilder(
            listenable: widget.runtime,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recorder: ${widget.runtime.activity.name}'),
                Text(
                  'Persisted callbacks: ${widget.runtime.persistedCallbackCount}',
                ),
                Text(
                  'Persistence error: ${widget.runtime.latestPersistenceError ?? 'none'}',
                ),
                Text(
                  'Native error: ${widget.runtime.latestNativeError ?? 'none'}',
                ),
                Text('Projections: ${widget.runtime.projectionState.name}'),
                if (widget.runtime.projectionState ==
                    ProjectionDrainState.blocked) ...[
                  if (widget.runtime.blockingProjectionEvent case final event?)
                    Text(
                      'Blocking event: #${event.id} / ${event.type} / ${event.tsUtc}\n${event.payloadJson}',
                    ),
                  Text(
                    'Projection error: ${widget.runtime.latestProjectionError ?? 'unknown'}',
                  ),
                  ElevatedButton(
                    onPressed: _retryProjections,
                    child: const Text('Retry projections'),
                  ),
                ],
              ],
            ),
          ),
          if (_readError != null) Text('Recent events error: $_readError'),
          const Text('Recent events'),
          for (final event in _events)
            ListTile(
              title: Text(
                '#${event.id} / ${event.source.name} / ${event.type} / ${event.tsUtc} / ${event.processed ? 'processed' : 'pending'}',
              ),
              subtitle: Text(
                'Trip: ${event.tripId ?? 'none'}\n${event.payloadJson}',
              ),
            ),
        ],
      ),
    );
  }
}
