import 'dart:math';

import 'package:biketrack/domain/activity/activity_state.dart';
import 'package:biketrack/domain/activity/activity_type.dart';
import 'package:biketrack/domain/config/trip_config.dart';
import 'package:biketrack/domain/trip/gps_mode.dart';
import 'package:biketrack/domain/trip/segment_type.dart';
import 'package:biketrack/domain/trip/trip_close_reason.dart';
import 'package:biketrack/domain/trip/trip_command.dart';
import 'package:biketrack/domain/trip/trip_event.dart';
import 'package:biketrack/domain/trip/trip_state.dart';
import 'package:biketrack/domain/trip/trip_state_machine.dart';
import 'package:biketrack/domain/trip/trip_status.dart';
import 'package:flutter_test/flutter_test.dart';

const cfg = TripConfig();

ActivityChanged _activity(int nowMs, ActivityType type, int sinceMs) =>
    ActivityChanged(nowMs, ActivityState(type: type, sinceMs: sinceMs));

TripState _pausedThenSuspected() {
  var state = TripStateMachine.step(TripState.idle(), UserStart(0), cfg).state;
  state = TripStateMachine.step(
    state,
    _activity(280000, ActivityType.stationary, 100000),
    cfg,
  ).state;
  return TripStateMachine.step(state, Tick(1000000), cfg).state;
}

void main() {
  group('TripStateMachine D-030 phase 2', () {
    test('auto-starts only for cycling at the historical activity start', () {
      final walking = TripStateMachine.step(
        TripState.idle(),
        _activity(120000, ActivityType.walking, 100000),
        cfg,
      );
      expect(walking.state.isIdle, isTrue);
      expect(walking.commands, isEmpty);

      final cycling = TripStateMachine.step(
        TripState.idle(),
        _activity(120000, ActivityType.cycling, 90000),
        cfg,
      );
      expect(cycling.state.status, TripStatus.active);
      expect(cycling.state.tripStartMs, 90000);
      expect(cycling.commands, [
        StartGps(GpsMode.high),
        OpenSegment(SegmentType.cycling, 90000),
      ]);
    });

    test(
      'duplicate and stale auto-start evidence does not duplicate a trip',
      () {
        final first = TripStateMachine.step(
          TripState.idle(),
          _activity(120000, ActivityType.cycling, 90000),
          cfg,
        );
        final duplicate = TripStateMachine.step(
          first.state,
          _activity(120000, ActivityType.cycling, 90000),
          cfg,
        );
        expect(duplicate.state.status, TripStatus.active);
        expect(duplicate.commands, isEmpty);

        final stale = TripStateMachine.step(
          duplicate.state,
          _activity(119999, ActivityType.cycling, 90000),
          cfg,
        );
        expect(stale.state, duplicate.state);
        expect(stale.commands, isEmpty);
      },
    );

    test('GPS gap closes the known segment at last trusted GPS time', () {
      final active = TripStateMachine.step(
        TripState.idle(),
        UserStart(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(
        active,
        GpsGapDetected(100000, 70000),
        cfg,
      );

      expect(result.state.segmentType, SegmentType.gap);
      expect(result.state.segmentStartMs, 70000);
      expect(result.commands, [
        CloseSegment(70000),
        OpenSegment(SegmentType.gap, 70000),
        const ResetGpsAnchor(),
      ]);
    });

    test('invalid trusted GPS times remain within trip and segment bounds', () {
      final active = TripStateMachine.step(
        TripState.idle(),
        UserStart(100000),
        cfg,
      ).state;
      final beforeTrip = TripStateMachine.step(
        active,
        GpsGapDetected(200000, 50000),
        cfg,
      );
      expect(beforeTrip.commands, [
        CloseSegment(100000),
        OpenSegment(SegmentType.gap, 100000),
        const ResetGpsAnchor(),
      ]);

      final afterDetection = TripStateMachine.step(
        active,
        GpsGapDetected(200000, 300000),
        cfg,
      );
      expect(afterDetection.commands, [
        CloseSegment(200000),
        OpenSegment(SegmentType.gap, 200000),
        const ResetGpsAnchor(),
      ]);
    });

    test(
      'movement after a gap opens a new segment without bridging the gap',
      () {
        var state = TripStateMachine.step(
          TripState.idle(),
          UserStart(0),
          cfg,
        ).state;
        final gap = TripStateMachine.step(
          state,
          GpsGapDetected(100000, 70000),
          cfg,
        );
        state = gap.state;
        final resumed = TripStateMachine.step(
          state,
          _activity(120000, ActivityType.cycling, 110000),
          cfg,
        );

        expect(gap.commands.last, const ResetGpsAnchor());
        expect(resumed.state.segmentType, SegmentType.cycling);
        expect(resumed.state.segmentStartMs, 110000);
        expect(resumed.commands, [
          CloseSegment(110000),
          OpenSegment(SegmentType.cycling, 110000),
        ]);
      },
    );

    test(
      'paused inactivity reaches suspectedForgotten and cycling resumes active',
      () {
        final suspected = _pausedThenSuspected();
        expect(suspected.status, TripStatus.suspectedForgotten);
        expect(suspected.suspectedSinceMs, 1000000);

        final resumed = TripStateMachine.step(
          suspected,
          _activity(1000001, ActivityType.cycling, 990000),
          cfg,
        );
        expect(resumed.state.status, TripStatus.active);
        expect(resumed.state.pausedSinceMs, isNull);
        expect(resumed.state.suspectedSinceMs, isNull);
        expect(resumed.commands, [const StartGps(GpsMode.high)]);
      },
    );

    test('auto-close ends at the conservative last known movement time', () {
      final suspected = _pausedThenSuspected();
      final result = TripStateMachine.step(suspected, Tick(3700000), cfg);

      expect(result.state.status, TripStatus.needsReview);
      expect(result.state.closeReason, TripCloseReason.autoClosed);
      expect(result.state.segmentType, isNull);
      expect(result.state.segmentStartMs, isNull);
      expect(result.commands, [
        CloseSegment(100000),
        const StopGps(),
        EndTrip(100000),
      ]);
    });

    test('recovery keeps GPS and movement timestamps distinct and ends all segments', () {
      final active = TripStateMachine.step(
        TripState.idle(),
        UserStart(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(
        active,
        RecoveryDetected(1000000, 300000, 800000),
        cfg,
      );

      expect(result.state.status, TripStatus.needsReview);
      expect(result.state.closeReason, TripCloseReason.recoveredAfterGap);
      expect(result.state.segmentType, isNull);
      expect(result.state.segmentStartMs, isNull);
      expect(result.commands, [
        CloseSegment(300000),
        OpenSegment(SegmentType.gap, 300000),
        CloseSegment(800000),
        const StopGps(),
        EndTrip(800000),
      ]);
    });

    test(
      'duplicate and stale recovery events do not emit terminal commands twice',
      () {
        final active = TripStateMachine.step(
          TripState.idle(),
          UserStart(0),
          cfg,
        ).state;
        final recovered = TripStateMachine.step(
          active,
          RecoveryDetected(1000000, 300000, 800000),
          cfg,
        );
        final duplicate = TripStateMachine.step(
          recovered.state,
          RecoveryDetected(1000000, 300000, 800000),
          cfg,
        );
        expect(duplicate.commands, isEmpty);
        expect(duplicate.state.status, TripStatus.needsReview);

        final stale = TripStateMachine.step(
          duplicate.state,
          RecoveryDetected(999999, 100000, 900000),
          cfg,
        );
        expect(stale.state, duplicate.state);
        expect(stale.commands, isEmpty);
      },
    );

    test('user stop remains completed with a userStopped close reason', () {
      final active = TripStateMachine.step(
        TripState.idle(),
        UserStart(0),
        cfg,
      ).state;
      final result = TripStateMachine.step(active, UserStop(100000), cfg);

      expect(result.state.status, TripStatus.completed);
      expect(result.state.closeReason, TripCloseReason.userStopped);
      expect(result.commands, [
        CloseSegment(100000),
        const StopGps(),
        EndTrip(100000),
      ]);
    });

    test('property: derived timestamps stay monotonic without duplicate terminal commands', () {
      for (final seed in [17, 29]) {
        final random = Random(seed);
        var state = TripState.idle();
        var nowMs = 0;
        int? openSegmentStartMs;

        for (var i = 0; i < 500; i++) {
          nowMs += random.nextInt(120000);
          final event = switch (random.nextInt(7)) {
            0 => UserStart(nowMs),
            1 => NfcScan(nowMs),
            2 => UserStop(nowMs),
            3 => _activity(
              nowMs,
              ActivityType.values[random.nextInt(ActivityType.values.length)],
              nowMs - random.nextInt(240000),
            ),
            4 => GpsGapDetected(nowMs, nowMs - random.nextInt(480000)),
            5 => RecoveryDetected(
              nowMs,
              nowMs - random.nextInt(480000),
              random.nextBool() ? nowMs - random.nextInt(480000) : null,
            ),
            _ => Tick(nowMs),
          };

          final result = TripStateMachine.step(state, event, cfg);
          expect(
            result.commands.whereType<EndTrip>().length,
            lessThanOrEqualTo(1),
            reason: 'seed $seed i=$i emitted duplicate EndTrip commands',
          );
          expect(
            result.commands.whereType<StopGps>().length,
            lessThanOrEqualTo(1),
            reason: 'seed $seed i=$i emitted duplicate StopGps commands',
          );

          for (final command in result.commands) {
            if (command is OpenSegment) {
              expect(
                command.startMs,
                greaterThanOrEqualTo(
                  result.state.tripStartMs ?? command.startMs,
                ),
                reason: 'seed $seed i=$i opened before trip start',
              );
              openSegmentStartMs = command.startMs;
            } else if (command is CloseSegment) {
              if (openSegmentStartMs != null) {
                expect(
                  command.endMs,
                  greaterThanOrEqualTo(openSegmentStartMs),
                  reason: 'seed $seed i=$i closed before segment start',
                );
              }
              openSegmentStartMs = null;
            } else if (command is EndTrip && state.tripStartMs != null) {
              expect(
                command.endMs,
                greaterThanOrEqualTo(state.tripStartMs!),
                reason: 'seed $seed i=$i ended before trip start',
              );
            }
          }

          if (result.commands.any((command) => command is EndTrip)) {
            expect(result.state.segmentType, isNull);
            expect(result.state.segmentStartMs, isNull);
          }
          state = result.state;
        }
      }
    });
  });
}
