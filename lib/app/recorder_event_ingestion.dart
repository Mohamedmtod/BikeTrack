import 'dart:async';
import 'dart:convert';

import '../bridge/recorder_bridge.dart';
import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';
import '../domain/shared/event_source.dart';
import 'recorder_runtime.dart';

class RecorderEventIngestion {
  RecorderEventIngestion(
    RecorderBridge bridge,
    this._repository,
    this._runtime,
    this._clockMs,
  ) {
    _subscriptions.addAll([
      bridge.fixes.listen((fix) {
        _enqueue(
          () => NewEvent(
            tsUtc: fix.sample.tsMs,
            source: EventSource.gps,
            type: 'location',
            payloadJson: jsonEncode({
              'latitudeDeg': fix.sample.position.latDeg,
              'longitudeDeg': fix.sample.position.lonDeg,
              'fixTsMs': fix.sample.tsMs,
              'hAccuracyM': fix.sample.hAccuracyM,
              'recvMs': fix.recvMs,
              'rideId': fix.rideId,
            }),
          ),
        );
      }),
      bridge.locationUpdates.listen((update) {
        final timestamp = _clockMs();
        _runtime.setActivity(
          update.started ? RecorderActivity.recording : RecorderActivity.idle,
        );
        _enqueue(
          () => NewEvent(
            tsUtc: timestamp,
            source: EventSource.system,
            type: update.started
                ? 'location_updates_started'
                : 'location_updates_stopped',
            payloadJson: jsonEncode({
              'started': update.started,
              'rideId': update.rideId,
            }),
          ),
        );
      }),
      bridge.authorizationChanges.listen((change) {
        final timestamp = _clockMs();
        _enqueue(
          () => NewEvent(
            tsUtc: timestamp,
            source: EventSource.system,
            type: 'location_authorization_changed',
            payloadJson: jsonEncode({'authorization': change.authorization}),
          ),
        );
      }),
      bridge.locationErrors.listen((error) {
        final timestamp = _clockMs();
        _runtime.nativeFailed('location error ${error.code}', error.message);
        _enqueue(
          () => NewEvent(
            tsUtc: timestamp,
            source: EventSource.system,
            type: 'location_error',
            payloadJson: jsonEncode({
              'code': error.code,
              'message': error.message,
              'rideId': error.rideId,
            }),
          ),
        );
      }),
    ]);
  }

  final EventRepository _repository;
  final RecorderRuntime _runtime;
  final int Function() _clockMs;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  Future<void> _pending = Future<void>.value();

  // Queue errors are reported in runtime state, then the next callback proceeds.
  void _enqueue(NewEvent Function() makeEvent) {
    _pending = _pending.then((_) async {
      try {
        await _repository.append(makeEvent());
        _runtime.callbackPersisted();
      } catch (error) {
        _runtime.persistenceFailed('recorder callback', error);
      }
    });
  }

  Future<void> get drained => _pending;

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _pending;
  }
}
