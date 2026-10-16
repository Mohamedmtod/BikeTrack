import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/bridge/generated/recorder.g.dart',
    swiftOut: 'ios/Runner/Generated/Recorder.g.swift',
    dartOptions: DartOptions(),
    swiftOptions: SwiftOptions(),
  ),
)
class RecorderStartResult {
  late bool started;
  String? rideId;
  String? reason;
}

class RecorderStatus {
  late bool recording;
  String? rideId;
  late String authorization;
}

class NativeGpsFix {
  late double latitudeDeg;
  late double longitudeDeg;
  late int fixTsMs;
  late double hAccuracyM;
  late int recvMs;
  String? rideId;
}

class RecorderLocationUpdate {
  late bool started;
  String? rideId;
}

class RecorderAuthorizationChange {
  late String authorization;
}

class RecorderLocationError {
  late String code;
  late String message;
  String? rideId;
}

@HostApi()
abstract class RecorderHostApi {
  RecorderStartResult start(String trigger, String attemptId);

  void stop();

  RecorderStatus status();

  void requestWhenInUse();

  String documentsDirectoryPath();

  void requestAlways();
}

@FlutterApi()
abstract class RecorderFlutterApi {
  void onRawFix(NativeGpsFix fix);

  void onLocationUpdate(RecorderLocationUpdate update);

  void onAuthorizationChanged(RecorderAuthorizationChange change);

  void onLocationError(RecorderLocationError error);
}
