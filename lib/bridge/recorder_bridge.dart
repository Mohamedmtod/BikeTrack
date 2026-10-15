import 'dart:async';

import 'package:flutter/services.dart';

import 'generated/recorder.g.dart' as pigeon;
import 'recorder_api.dart';
import 'recorder_events.dart';

class RecorderBridge implements pigeon.RecorderFlutterApi {
  RecorderBridge({NativeRecorderApi? nativeApi})
    : _nativeApi = nativeApi ?? PigeonRecorderApi();

  final NativeRecorderApi _nativeApi;
  final _fixes = StreamController<RecorderFix>.broadcast();
  final _locationUpdates = StreamController<RecorderLocationUpdate>.broadcast();
  final _authorizationChanges =
      StreamController<RecorderAuthorizationChange>.broadcast();
  final _locationErrors = StreamController<RecorderLocationError>.broadcast();

  Stream<RecorderFix> get fixes => _fixes.stream;
  Stream<RecorderLocationUpdate> get locationUpdates => _locationUpdates.stream;
  Stream<RecorderAuthorizationChange> get authorizationChanges =>
      _authorizationChanges.stream;
  Stream<RecorderLocationError> get locationErrors => _locationErrors.stream;

  void installCallbacks({BinaryMessenger? binaryMessenger}) {
    pigeon.RecorderFlutterApi.setUp(this, binaryMessenger: binaryMessenger);
  }

  Future<RecorderStart> start(String trigger, String attemptId) async {
    return RecorderStart.fromPigeon(await _nativeApi.start(trigger, attemptId));
  }

  Future<void> stop() => _nativeApi.stop();

  Future<RecorderState> status() async {
    return RecorderState.fromPigeon(await _nativeApi.status());
  }

  Future<void> requestWhenInUse() => _nativeApi.requestWhenInUse();

  Future<void> requestAlways() => _nativeApi.requestAlways();

  @override
  void onRawFix(pigeon.NativeGpsFix fix) {
    _fixes.add(RecorderFix.fromPigeon(fix));
  }

  @override
  void onLocationUpdate(pigeon.RecorderLocationUpdate update) {
    _locationUpdates.add(RecorderLocationUpdate.fromPigeon(update));
  }

  @override
  void onAuthorizationChanged(pigeon.RecorderAuthorizationChange change) {
    _authorizationChanges.add(RecorderAuthorizationChange.fromPigeon(change));
  }

  @override
  void onLocationError(pigeon.RecorderLocationError error) {
    _locationErrors.add(RecorderLocationError.fromPigeon(error));
  }

  Future<void> dispose() async {
    await _fixes.close();
    await _locationUpdates.close();
    await _authorizationChanges.close();
    await _locationErrors.close();
  }
}
