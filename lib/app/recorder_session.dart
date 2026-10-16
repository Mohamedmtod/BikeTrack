import 'dart:convert';

import '../bridge/recorder_bridge.dart';
import '../bridge/recorder_events.dart';
import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';
import '../domain/shared/event_source.dart';
import 'recorder_runtime.dart';

class RecorderSession {
  RecorderSession(this._bridge, this._repository, this._runtime, this._clockMs);

  final RecorderBridge _bridge;
  final EventRepository _repository;
  final RecorderRuntime _runtime;
  final int Function() _clockMs;

  Future<RecorderStart> startManual(String attemptId) async {
    try {
      await _repository.append(
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
    try {
      final result = await _bridge.start('user', attemptId);
      if (result.started) {
        _runtime.setActivity(RecorderActivity.recording);
      } else {
        _runtime.setActivity(RecorderActivity.idle);
        _runtime.nativeFailed(
          'start rejected',
          result.reason ?? 'unknown reason',
        );
      }
      return result;
    } catch (error) {
      _runtime.setActivity(RecorderActivity.idle);
      _runtime.nativeFailed('start', error);
      rethrow;
    }
  }

  Future<void> stopManual() async {
    Object? writeError;
    StackTrace? writeStack;
    try {
      await _repository.append(
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
