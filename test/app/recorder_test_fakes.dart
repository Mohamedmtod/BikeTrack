import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_api.dart';
import 'package:biketrack/data/events/event_record.dart';
import 'package:biketrack/data/events/event_repository.dart';

class FakeNativeRecorderApi implements NativeRecorderApi {
  final calls = <String>[];
  pigeon.RecorderStartResult startResult = pigeon.RecorderStartResult(
    started: true,
    rideId: 'ride-1',
  );
  Object? startError;
  Object? stopError;

  @override
  Future<pigeon.RecorderStartResult> start(
    String trigger,
    String attemptId,
  ) async {
    calls.add('start:$trigger:$attemptId');
    if (startError case final error?) throw error;
    return startResult;
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
    if (stopError case final error?) throw error;
  }

  @override
  Future<pigeon.RecorderStatus> status() async =>
      pigeon.RecorderStatus(recording: false, authorization: 'whenInUse');

  @override
  Future<void> requestWhenInUse() async {}

  @override
  Future<void> requestAlways() async {}
}

class FakeEventRepository extends EventRepository {
  FakeEventRepository(super.database);

  Future<int> Function(NewEvent)? onAppend;

  @override
  Future<int> append(NewEvent event) =>
      onAppend?.call(event) ?? super.append(event);
}
