import 'generated/recorder.g.dart' as pigeon;

abstract interface class NativeRecorderApi {
  Future<pigeon.RecorderStartResult> start(String trigger, String attemptId);

  Future<void> stop();

  Future<pigeon.RecorderStatus> status();

  Future<void> requestWhenInUse();

  Future<void> requestAlways();
}

class PigeonRecorderApi implements NativeRecorderApi {
  PigeonRecorderApi({pigeon.RecorderHostApi? hostApi})
    : _hostApi = hostApi ?? pigeon.RecorderHostApi();

  final pigeon.RecorderHostApi _hostApi;

  @override
  Future<pigeon.RecorderStartResult> start(String trigger, String attemptId) =>
      _hostApi.start(trigger, attemptId);

  @override
  Future<void> stop() => _hostApi.stop();

  @override
  Future<pigeon.RecorderStatus> status() => _hostApi.status();

  @override
  Future<void> requestWhenInUse() => _hostApi.requestWhenInUse();

  @override
  Future<void> requestAlways() => _hostApi.requestAlways();
}
