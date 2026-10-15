import 'package:biketrack/bridge/generated/recorder.g.dart' as pigeon;
import 'package:biketrack/bridge/recorder_api.dart';
import 'package:biketrack/bridge/recorder_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecorderBridge commands', () {
    test('dispatches commands and maps command results', () async {
      final nativeApi = _FakeNativeRecorderApi();
      final bridge = RecorderBridge(nativeApi: nativeApi);

      final start = await bridge.start('manual', 'attempt-1');
      final status = await bridge.status();
      await bridge.stop();
      await bridge.requestWhenInUse();
      await bridge.requestAlways();

      expect(start.started, isTrue);
      expect(start.rideId, 'ride-1');
      expect(start.reason, isNull);
      expect(status.recording, isTrue);
      expect(status.rideId, 'ride-1');
      expect(status.authorization, 'always');
      expect(nativeApi.calls, <String>[
        'start:manual:attempt-1',
        'status',
        'stop',
        'requestWhenInUse',
        'requestAlways',
      ]);

      await bridge.dispose();
    });
  });

  group('RecorderBridge callbacks', () {
    test(
      'maps every raw GPS field to the domain sample and bridge metadata',
      () async {
        final bridge = RecorderBridge(nativeApi: _FakeNativeRecorderApi());
        final fix = bridge.fixes.first;

        bridge.onRawFix(
          pigeon.NativeGpsFix(
            latitudeDeg: 30.0444,
            longitudeDeg: 31.2357,
            fixTsMs: 1720000000123,
            hAccuracyM: 4.5,
            recvMs: 1720000000456,
            rideId: 'ride-1',
          ),
        );

        final event = await fix;
        expect(event.sample.position.latDeg, 30.0444);
        expect(event.sample.position.lonDeg, 31.2357);
        expect(event.sample.tsMs, 1720000000123);
        expect(event.sample.hAccuracyM, 4.5);
        expect(event.recvMs, 1720000000456);
        expect(event.rideId, 'ride-1');

        await bridge.dispose();
      },
    );

    test('maps authorization and location-error callbacks', () async {
      final bridge = RecorderBridge(nativeApi: _FakeNativeRecorderApi());
      final authorization = bridge.authorizationChanges.first;
      final error = bridge.locationErrors.first;

      bridge.onAuthorizationChanged(
        pigeon.RecorderAuthorizationChange(authorization: 'whenInUse'),
      );
      bridge.onLocationError(
        pigeon.RecorderLocationError(
          code: 'network',
          message: 'Network unavailable',
          rideId: 'ride-1',
        ),
      );

      final authorizationEvent = await authorization;
      final errorEvent = await error;
      expect(authorizationEvent.authorization, 'whenInUse');
      expect(errorEvent.code, 'network');
      expect(errorEvent.message, 'Network unavailable');
      expect(errorEvent.rideId, 'ride-1');

      await bridge.dispose();
    });
  });
}

class _FakeNativeRecorderApi implements NativeRecorderApi {
  final calls = <String>[];

  @override
  Future<void> requestAlways() async {
    calls.add('requestAlways');
  }

  @override
  Future<void> requestWhenInUse() async {
    calls.add('requestWhenInUse');
  }

  @override
  Future<pigeon.RecorderStartResult> start(
    String trigger,
    String attemptId,
  ) async {
    calls.add('start:$trigger:$attemptId');
    return pigeon.RecorderStartResult(started: true, rideId: 'ride-1');
  }

  @override
  Future<pigeon.RecorderStatus> status() async {
    calls.add('status');
    return pigeon.RecorderStatus(
      recording: true,
      rideId: 'ride-1',
      authorization: 'always',
    );
  }

  @override
  Future<void> stop() async {
    calls.add('stop');
  }
}
