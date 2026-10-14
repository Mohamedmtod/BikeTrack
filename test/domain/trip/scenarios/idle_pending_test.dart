import 'package:biketrack/domain/activity/activity_state.dart';
import 'package:biketrack/domain/activity/activity_type.dart';
import 'package:biketrack/domain/config/trip_config.dart';
import 'package:biketrack/domain/trip/gps_mode.dart';
import 'package:biketrack/domain/trip/segment_type.dart';
import 'package:biketrack/domain/trip/trip_command.dart';
import 'package:biketrack/domain/trip/trip_event.dart';
import 'package:biketrack/domain/trip/trip_state.dart';
import 'package:biketrack/domain/trip/trip_state_machine.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:flutter_test/flutter_test.dart';

const cfg = TripConfig();

void main() {
  group('TripStateMachine idle/pending scenarios', () {
    test('1: idle+UserStart(0) -> active, tripStart 0, [StartGps(high), OpenSegment(cycling,0)]', () {
      final result = TripStateMachine.step(TripState.idle(), UserStart(0), cfg);
      expect(result.state.status, TripStatus.active);
      expect(result.state.tripStartMs, 0);
      expect(result.state.segmentType, SegmentType.cycling);
      expect(result.commands, [
        StartGps(GpsMode.high),
        OpenSegment(SegmentType.cycling, 0),
      ]);
    });

    test(
      '2: idle+NfcScan(0) -> pending, pendingSince 0, [StartGps(lowPower)]',
      () {
        final result = TripStateMachine.step(TripState.idle(), NfcScan(0), cfg);
        expect(result.state.status, TripStatus.pending);
        expect(result.state.pendingSinceMs, 0);
        expect(result.commands, [StartGps(GpsMode.lowPower)]);
      },
    );

    test('3: pending(0)+Activity(cycling,since 10s) at 40s -> active, tripStart 10s', () {
      var state = TripStateMachine.step(
        TripState.idle(),
        NfcScan(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(
        state,
        ActivityChanged(
          40000,
          ActivityState(type: ActivityType.cycling, sinceMs: 10000),
        ),
        cfg,
      );
      expect(result.state.status, TripStatus.active);
      expect(result.state.tripStartMs, 10000);
      expect(result.commands, [
        StartGps(GpsMode.high),
        OpenSegment(SegmentType.cycling, 10000),
      ]);
    });

    test('4: pending(0)+Activity(cycling,since -20s) at 15s -> tripStart 0 (clamped to pendingSince)', () {
      var state = TripStateMachine.step(
        TripState.idle(),
        NfcScan(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(
        state,
        ActivityChanged(
          15000,
          ActivityState(type: ActivityType.cycling, sinceMs: -20000),
        ),
        cfg,
      );
      expect(result.state.status, TripStatus.active);
      expect(result.state.tripStartMs, 0); // max(-20000, pendingSince=0) = 0
    });

    test('5: pending(0); Tick 299s -> pending []; Tick 300s -> idle [StopGps, CancelTrip]', () {
      var state = TripStateMachine.step(
        TripState.idle(),
        NfcScan(0),
        cfg,
      ).state;
      final r1 = TripStateMachine.step(state, Tick(299000), cfg);
      expect(r1.state.status, TripStatus.pending);
      expect(r1.commands, isEmpty);
      final r2 = TripStateMachine.step(r1.state, Tick(300000), cfg);
      expect(r2.state.isIdle, isTrue);
      expect(r2.commands, [const StopGps(), const CancelTrip()]);
    });

    test(
      '6: pending(0)+Activity(walking) at 30s -> pending []; Tick 300s -> idle',
      () {
        var state = TripStateMachine.step(
          TripState.idle(),
          NfcScan(0),
          cfg,
        ).state;
        final r1 = TripStateMachine.step(
          state,
          ActivityChanged(
            30000,
            ActivityState(type: ActivityType.walking, sinceMs: 5000),
          ),
          cfg,
        );
        expect(r1.state.status, TripStatus.pending);
        expect(r1.commands, isEmpty);
        final r2 = TripStateMachine.step(r1.state, Tick(300000), cfg);
        expect(r2.state.isIdle, isTrue);
        expect(r2.commands, [const StopGps(), const CancelTrip()]);
      },
    );

    test('7: pending(0)+UserStart(60s) -> active, tripStart 60s', () {
      var state = TripStateMachine.step(
        TripState.idle(),
        NfcScan(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(state, UserStart(60000), cfg);
      expect(result.state.status, TripStatus.active);
      expect(result.state.tripStartMs, 60000);
      expect(result.commands, [
        StartGps(GpsMode.high),
        OpenSegment(SegmentType.cycling, 60000),
      ]);
    });

    test('8: pending(0)+UserStop -> idle [StopGps, CancelTrip]', () {
      var state = TripStateMachine.step(
        TripState.idle(),
        NfcScan(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(state, UserStop(30000), cfg);
      expect(result.state.isIdle, isTrue);
      expect(result.commands, [const StopGps(), const CancelTrip()]);
    });
  });
}
