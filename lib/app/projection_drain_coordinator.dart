import 'dart:async';

import '../data/events/event_repository.dart';
import '../data/projection/event_projection_processor.dart';
import 'recorder_runtime.dart';

class ProjectionDrainCoordinator {
  ProjectionDrainCoordinator(this._processor, this._events, this._runtime);

  final ProjectionProcessor _processor;
  final EventRepository _events;
  final RecorderRuntime _runtime;
  Completer<void>? _completion;
  bool _requested = false;

  void scheduleAutomatic() {
    if (_runtime.projectionState == ProjectionDrainState.blocked) return;
    _requested = true;
    if (_completion != null) return;
    _completion = Completer<void>();
    scheduleMicrotask(_drain);
  }

  Future<void> retry() async {
    if (_runtime.projectionState == ProjectionDrainState.blocked) {
      await drained;
      if (_runtime.projectionState == ProjectionDrainState.blocked) {
        _runtime.projectionStarted();
        scheduleAutomatic();
      }
    }
    await drained;
  }

  Future<void> get drained => _completion?.future ?? Future<void>.value();

  Future<void> _drain() async {
    try {
      do {
        _runtime.projectionStarted();
        do {
          _requested = false;
          while (await _processor.processNext()) {}
        } while (_requested);
        _runtime.projectionCompleted();
      } while (_requested);
    } catch (error) {
      try {
        final blocking = await _events.readNextUnprocessed();
        _runtime.projectionFailed(blocking, error);
      } catch (lookupError) {
        _runtime.projectionFailed(
          null,
          '$error (blocking event lookup failed: $lookupError)',
        );
      }
    } finally {
      final completion = _completion!;
      _completion = null;
      _requested = false;
      completion.complete();
    }
  }
}
