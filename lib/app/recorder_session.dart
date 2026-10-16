import 'dart:convert';

import '../bridge/recorder_bridge.dart';
import '../bridge/recorder_events.dart';
import '../data/events/event_record.dart';
import '../domain/shared/event_source.dart';
import 'raw_event_writer.dart';
import 'recorder_runtime.dart';

class RecorderSession {
  RecorderSession(this._bridge, this._writer, this._runtime, this._clockMs);

  final RecorderBridge _bridge;
  final RawEventWriter _writer;
  final RecorderRuntime _runtime;
  final int Function() _clockMs;
  Future<void> _pending = Future<void>.value();

  Future<void> get drained => _pending;

  void _track(Future<dynamic> operation) {
    _pending = Future.wait<void>([
      _pending,
      operation.then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    ]);
  }

  Future<RecorderStart> startManual(String attemptId) {
    final operation = _startManual(attemptId);
    _track(operation);
    return operation;
  }

  Future<RecorderStart> _startManual(String attemptId) async {
    try {
      await _writer.append(
        NewEvent(
          tsUtc: _clockMs(),
          source: EventSource.user,
          type: 'user_start',
          payloadJson: jsonEncode({'attemptId': attemptId}),
        ),
      );
    } catch (error) {
      _runtime.persistenceFailed('user_start', error);
      rethrow;
    }

    _runtime.setActivity(RecorderActivity.starting);
    final RecorderStart result;
    try {
      result = await _bridge.start('user', attemptId);
    } catch (error) {
      _runtime.setActivity(RecorderActivity.idle);
      _runtime.nativeFailed('start', error);
      rethrow;
    }

    if (result.started) {
      _runtime.setActivity(RecorderActivity.recording);
      await _appendStartResult(
        type: 'recorder_start_confirmed',
        attemptId: attemptId,
        details: {'rideId': result.rideId},
      );
    } else {
      _runtime.setActivity(RecorderActivity.idle);
      _runtime.nativeFailed(
        'start rejected',
        result.reason ?? 'unknown reason',
      );
      await _appendStartResult(
        type: 'recorder_start_failed',
        attemptId: attemptId,
        details: {'reason': result.reason},
      );
    }
    return result;
  }

  Future<void> _appendStartResult({
    required String type,
    required String attemptId,
    required Map<String, Object?> details,
  }) async {
    try {
      await _writer.append(
        NewEvent(
          tsUtc: _clockMs(),
          source: EventSource.system,
          type: type,
          payloadJson: jsonEncode({'attemptId': attemptId, ...details}),
        ),
      );
    } catch (error) {
      _runtime.persistenceFailed(type, error);
      rethrow;
    }
  }

  Future<void> stopManual() {
    final operation = _stopManual();
    _track(operation);
    return operation;
  }

  Future<void> _stopManual() async {
    Object? writeError;
    StackTrace? writeStack;
    try {
      await _writer.append(
        NewEvent(
          tsUtc: _clockMs(),
          source: EventSource.user,
          type: 'user_stop',
          payloadJson: jsonEncode({}),
        ),
      );
    } catch (error, stack) {
      writeError = error;
      writeStack = stack;
      _runtime.persistenceFailed('user_stop', error);
    }

    _runtime.setActivity(RecorderActivity.stopping);
    try {
      await _bridge.stop();
      _runtime.setActivity(RecorderActivity.idle);
    } catch (error) {
      _runtime.nativeFailed('stop', error);
      rethrow;
    }
    if (writeError != null) {
      Error.throwWithStackTrace(writeError, writeStack!);
    }
  }
}
