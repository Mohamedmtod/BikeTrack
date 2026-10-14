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

TripState _activeState({
  SegmentType segment = SegmentType.cycling,
  int tripStart = 0,
  int lastEvent = 0,
}) => TripState(
  status: TripStatus.active,
  tripStartMs: tripStart,
  segmentType: segment,
  segmentStartMs: tripStart,
  lastEventMs: lastEvent,
);

void main() {
  group('TripStateMachine active/paused scenarios', () {
    test('9: active; stationary 180s -> paused at pausedSince', () {
      var state = _activeState();
      final r1 = TripStateMachine.step(
        state,
        ActivityChanged(
          140000,
          ActivityState(type: ActivityType.stationary, sinceMs: 100000),
        ),
        cfg,
      );
      expect(r1.commands, isEmpty); // 40s < 180s

      final r2 = TripStateMachine.step(r1.state, Tick(279000), cfg);
      expect(r2.state.status, TripStatus.active);
      expect(r2.commands, isEmpty); // 179s < 180s

      final r3 = TripStateMachine.step(r2.state, Tick(280000), cfg);
      expect(r3.state.status, TripStatus.paused);
      expect(r3.state.pausedSinceMs, 100000);
      expect(r3.commands, [const StartGps(GpsMode.lowPower)]);
    });

    test('10: paused+Activity(cycling) -> active, [StartGps(high)], pausedSince cleared', () {
      final state = TripState(
        status: TripStatus.paused,
        tripStartMs: 0,
        segmentType: SegmentType.cycling,
        segmentStartMs: 0,
        pausedSinceMs: 100000,
        lastEventMs: 280000,
      );
      final result = TripStateMachine.step(
        state,
        ActivityChanged(
          530000,
          ActivityState(type: ActivityType.cycling, sinceMs: 500000),
        ),
        cfg,
      );
      expect(result.state.status, TripStatus.active);
      expect(result.state.pausedSinceMs, isNull);
      expect(result.commands, [const StartGps(GpsMode.high)]);
    });

    test('11: active cycling; walking mode change after 60s', () {
      var state = _activeState();
      final r1 = TripStateMachine.step(
        state,
        ActivityChanged(
          220000,
          ActivityState(type: ActivityType.walking, sinceMs: 200000),
        ),
        cfg,
      );
      expect(r1.commands, isEmpty); // 20s < 60s

      final r2 = TripStateMachine.step(r1.state, Tick(260000), cfg);
      expect(r2.commands, [
        CloseSegment(200000),
        OpenSegment(SegmentType.walking, 200000),
      ]);
      expect(r2.state.segmentType, SegmentType.walking);
    });

    test('12: active cycling; automotive mode change (needsReview: true)', () {
      final result = TripStateMachine.step(
        _activeState(),
        ActivityChanged(
          360000,
          ActivityState(type: ActivityType.automotive, sinceMs: 300000),
        ),
        cfg,
      );
      expect(result.commands, [
        CloseSegment(300000),
        OpenSegment(SegmentType.automotive, 300000, needsReview: true),
      ]);
    });

    test('13: active walking; cycling mode change after 60s', () {
      final result = TripStateMachine.step(
        _activeState(segment: SegmentType.walking),
        ActivityChanged(
          460000,
          ActivityState(type: ActivityType.cycling, sinceMs: 400000),
        ),
        cfg,
      );
      expect(result.commands, [
        CloseSegment(400000),
        OpenSegment(SegmentType.cycling, 400000),
      ]);
    });

    test('14: active cycling; same segment type -> no mode change', () {
      final result = TripStateMachine.step(
        _activeState(),
        ActivityChanged(
          500000,
          ActivityState(type: ActivityType.cycling, sinceMs: 0),
        ),
        cfg,
      );
      expect(result.commands, isEmpty);
    });

    test('15: active+UserStop(1000s) -> completed [CloseSegment, StopGps, EndTrip]', () {
      final result = TripStateMachine.step(
        _activeState(),
        UserStop(1000000),
        cfg,
      );
      expect(result.state.status, TripStatus.completed);
      expect(result.commands, [
        CloseSegment(1000000),
        const StopGps(),
        EndTrip(1000000),
      ]);
    });

    test('16: paused(pausedSince 100s)+UserStop(900s) -> completed ending at pausedSince', () {
      final state = TripState(
        status: TripStatus.paused,
        tripStartMs: 0,
        segmentType: SegmentType.cycling,
        segmentStartMs: 0,
        pausedSinceMs: 100000,
        lastEventMs: 280000,
      );
      final result = TripStateMachine.step(state, UserStop(900000), cfg);
      expect(result.state.status, TripStatus.completed);
      expect(result.commands, [
        CloseSegment(100000),
        const StopGps(),
        EndTrip(100000),
      ]);
    });

    test('17: open trip events emit AskOpenTripDecision only', () {
      final active = _activeState(lastEvent: 0);
      final paused = TripState(
        status: TripStatus.paused,
        tripStartMs: 0,
        pausedSinceMs: 0,
        lastEventMs: 0,
      );
      expect(TripStateMachine.step(active, NfcScan(1000), cfg).commands, [
        const AskOpenTripDecision(),
      ]);
      expect(TripStateMachine.step(active, UserStart(2000), cfg).commands, [
        const AskOpenTripDecision(),
      ]);
      expect(TripStateMachine.step(paused, NfcScan(1000), cfg).commands, [
        const AskOpenTripDecision(),
      ]);
    });

    test('20: paused+Activity(walking) -> paused, no commands', () {
      final state = TripState(
        status: TripStatus.paused,
        tripStartMs: 0,
        pausedSinceMs: 100000,
        lastEventMs: 280000,
      );
      final result = TripStateMachine.step(
        state,
        ActivityChanged(
          700000,
          ActivityState(type: ActivityType.walking, sinceMs: 600000),
        ),
        cfg,
      );
      expect(result.state.status, TripStatus.paused);
      expect(result.commands, isEmpty);
    });
  });
}
