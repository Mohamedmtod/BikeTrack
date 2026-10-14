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
  group('D-027 regression tests', () {
    // All times in ms unless noted.

    test('23: stale stationary before UserStart is cleared; pause timer '
        'starts from tripStartMs=0, fires at t=180s', () {
      // idle; Activity(stationary, since -500s) at -400s
      var r = TripStateMachine.step(
        TripState.idle(),
        ActivityChanged(
          -400000,
          ActivityState(type: ActivityType.stationary, sinceMs: -500000),
        ),
        cfg,
      );
      expect(r.state.isIdle, isTrue);
      expect(r.commands, isEmpty);

      // UserStart(0) -> active, stale activity cleared
      r = TripStateMachine.step(r.state, UserStart(0), cfg);
      expect(r.state.status, TripStatus.active);
      expect(r.state.lastActivityType, isNull); // D-027(1) cleared
      expect(r.commands, [
        StartGps(GpsMode.high),
        OpenSegment(SegmentType.cycling, 0),
      ]);

      // Tick(1s) -> active, [] (no activity stored yet)
      r = TripStateMachine.step(r.state, Tick(1000), cfg);
      expect(r.state.status, TripStatus.active);
      expect(r.commands, isEmpty);

      // Activity(stationary, since -500s) at 10s -> [] (pauseStart=max(-500000,0)=0; 10s < 180s)
      r = TripStateMachine.step(
        r.state,
        ActivityChanged(
          10000,
          ActivityState(type: ActivityType.stationary, sinceMs: -500000),
        ),
        cfg,
      );
      expect(r.state.status, TripStatus.active);
      expect(r.commands, isEmpty);

      // Tick(179s) -> active, [] (179s - 0 = 179s < 180s)
      r = TripStateMachine.step(r.state, Tick(179000), cfg);
      expect(r.state.status, TripStatus.active);
      expect(r.commands, isEmpty);

      // Tick(180s) -> paused, pausedSince = 0 (180s - 0 = 180s >= 180s)
      r = TripStateMachine.step(r.state, Tick(180000), cfg);
      expect(r.state.status, TripStatus.paused);
      expect(r.state.pausedSinceMs, 0);
      expect(r.commands, [const StartGps(GpsMode.lowPower)]);
    });

    test('24: segment switchAt clamped to segmentStartMs when lasSince precedes it', () {
      // Active state, tripStart=0, cycling segment from 0
      var state = TripState(
        status: TripStatus.active,
        tripStartMs: 0,
        segmentType: SegmentType.cycling,
        segmentStartMs: 0,
        lastEventMs: 0,
      );

      // Activity(walking, since 400s) at 460s:
      // switchAt = max(400000, segmentStartMs=0) = 400000; 460000-400000=60s >= 60s -> switch
      var r = TripStateMachine.step(
        state,
        ActivityChanged(
          460000,
          ActivityState(type: ActivityType.walking, sinceMs: 400000),
        ),
        cfg,
      );
      expect(r.commands, [
        CloseSegment(400000),
        OpenSegment(SegmentType.walking, 400000),
      ]);
      expect(r.state.segmentStartMs, 400000);

      // Activity(automotive, since 350s) at 470s:
      // switchAt = max(350000, segmentStartMs=400000) = 400000 (clamped to current segment start)
      // elapsed = 470000 - 400000 = 70s >= 60s -> switch
      r = TripStateMachine.step(
        r.state,
        ActivityChanged(
          470000,
          ActivityState(type: ActivityType.automotive, sinceMs: 350000),
        ),
        cfg,
      );
      expect(r.commands, [
        CloseSegment(400000),
        OpenSegment(SegmentType.automotive, 400000, needsReview: true),
      ]);
    });

    test('25: stale cycling from completed trip does not auto-start next pending trip', () {
      // UserStart(0) -> active (clears lastActivity per D-027)
      var r = TripStateMachine.step(TripState.idle(), UserStart(0), cfg);
      expect(r.state.status, TripStatus.active);

      // Activity(cycling, since 0) at 30s -> active, [] (same segment)
      r = TripStateMachine.step(
        r.state,
        ActivityChanged(
          30000,
          ActivityState(type: ActivityType.cycling, sinceMs: 0),
        ),
        cfg,
      );
      expect(r.commands, isEmpty);
      expect(r.state.lastActivityType, ActivityType.cycling);

      // UserStop(500s) -> completed; lastActivityType=cycling preserved
      r = TripStateMachine.step(r.state, UserStop(500000), cfg);
      expect(r.state.status, TripStatus.completed);
      expect(r.state.lastActivityType, ActivityType.cycling);

      // NfcScan(1000s) -> pending; lastActivity CLEARED (D-027: completed->pending)
      r = TripStateMachine.step(r.state, NfcScan(1000000), cfg);
      expect(r.state.status, TripStatus.pending);
      expect(r.state.lastActivityType, isNull); // D-027(1)

      // Tick(1001s) -> pending, [] — stale cycling does NOT auto-start
      r = TripStateMachine.step(r.state, Tick(1001000), cfg);
      expect(r.state.status, TripStatus.pending);
      expect(r.commands, isEmpty);

      // Activity(cycling, since 1010s) at 1040s -> active, tripStart=1010s
      // start = max(1010000, pendingSinceMs=1000000) = 1010000
      r = TripStateMachine.step(
        r.state,
        ActivityChanged(
          1040000,
          ActivityState(type: ActivityType.cycling, sinceMs: 1010000),
        ),
        cfg,
      );
      expect(r.state.status, TripStatus.active);
      expect(r.state.tripStartMs, 1010000);
    });

    test(
      '26: paused + UserStart -> unchanged state, [AskOpenTripDecision]',
      () {
        final state = TripState(
          status: TripStatus.paused,
          tripStartMs: 0,
          segmentType: SegmentType.cycling,
          segmentStartMs: 0,
          pausedSinceMs: 100000,
          lastEventMs: 280000,
        );
        final r = TripStateMachine.step(state, UserStart(300000), cfg);
        expect(r.state, state.copyWith(lastEventMs: 300000));
        expect(r.commands, [const AskOpenTripDecision()]);
      },
    );
  });
}
