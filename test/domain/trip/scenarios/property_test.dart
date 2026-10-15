import 'dart:math';

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
  group('TripStateMachine property/edge scenarios', () {
    test('18: event with nowMs < lastEventMs -> state unchanged, []', () {
      final state = TripState(
        status: TripStatus.active,
        tripStartMs: 0,
        lastEventMs: 1000,
      );
      final result = TripStateMachine.step(state, UserStop(999), cfg);
      expect(result.state, state);
      expect(result.commands, isEmpty);
    });

    test(
      '19: completed+UserStart(2000s) -> new active trip, tripStart 2000s',
      () {
        final state = TripState(
          status: TripStatus.completed,
          tripStartMs: 0,
          lastEventMs: 1000000,
        );
        final result = TripStateMachine.step(state, UserStart(2000000), cfg);
        expect(result.state.status, TripStatus.active);
        expect(result.state.tripStartMs, 2000000);
      },
    );

    test(
      '21: idle+Activity(cycling) -> active at historical activity start',
      () {
        final result = TripStateMachine.step(
          TripState.idle(),
          ActivityChanged(
            60000,
            ActivityState(type: ActivityType.cycling, sinceMs: 0),
          ),
          cfg,
        );
        expect(result.state.status, TripStatus.active);
        expect(result.state.tripStartMs, 0);
        expect(result.commands, [
          StartGps(GpsMode.high),
          OpenSegment(SegmentType.cycling, 0),
        ]);
      },
    );

    test('22: property: 500 random non-decreasing events never throw; '
        'status in {null,pending,active,paused,suspectedForgotten,needsReview,completed}; '
        'OpenSegment.startMs >= tripStartMs', () {
      final rng = Random(7);
      var state = TripState.idle();
      int timeMs = 0;
      final activityTypes = ActivityType.values;

      for (var i = 0; i < 500; i++) {
        timeMs += rng.nextInt(200000);
        final which = rng.nextInt(5);
        final TripEvent event;
        switch (which) {
          case 0:
            event = UserStart(timeMs);
          case 1:
            event = NfcScan(timeMs);
          case 2:
            event = UserStop(timeMs);
          case 3:
            event = ActivityChanged(
              timeMs,
              ActivityState(
                type: activityTypes[rng.nextInt(activityTypes.length)],
                sinceMs: timeMs - rng.nextInt(60000),
              ),
            );
          default:
            event = Tick(timeMs);
        }

        final result = TripStateMachine.step(state, event, cfg);

        expect(
          result.state.status,
          anyOf(
            isNull,
            equals(TripStatus.pending),
            equals(TripStatus.active),
            equals(TripStatus.paused),
            equals(TripStatus.suspectedForgotten),
            equals(TripStatus.needsReview),
            equals(TripStatus.completed),
          ),
        );

        for (final cmd in result.commands) {
          if (cmd is OpenSegment) {
            expect(result.state.tripStartMs, isNotNull);
            expect(
              cmd.startMs,
              greaterThanOrEqualTo(result.state.tripStartMs!),
            );
          }
        }

        state = result.state;
      }
    });

    test(
      '27: property (seeds 7 and 11, 1000 events): '
      'at most one OpenSegment per step; '
      'CloseSegment.endMs >= its open startMs; '
      'EndTrip.endMs >= tripStartMs and co-occurs with CloseSegment; '
      'no two consecutive StartGps with same mode without StopGps between',
      () {
        for (final seed in [7, 11]) {
          final rng = Random(seed);
          var state = TripState.idle();
          int timeMs = 0;
          final activityTypes = ActivityType.values;

          // GPS tracking: null means GPS is off.
          GpsMode? lastGpsMode;
          // Tracks the startMs of the currently-open segment; null = no open segment.
          int? openSegStartMs;

          for (var i = 0; i < 1000; i++) {
            timeMs += rng.nextInt(200000);
            final which = rng.nextInt(5);
            final TripEvent event;
            switch (which) {
              case 0:
                event = UserStart(timeMs);
              case 1:
                event = NfcScan(timeMs);
              case 2:
                event = UserStop(timeMs);
              case 3:
                // sinceMs up to 600 s before nowMs (may precede trip start).
                event = ActivityChanged(
                  timeMs,
                  ActivityState(
                    type: activityTypes[rng.nextInt(activityTypes.length)],
                    sinceMs: timeMs - rng.nextInt(600000),
                  ),
                );
              default:
                event = Tick(timeMs);
            }

            final result = TripStateMachine.step(state, event, cfg);
            final cmds = result.commands;

            // At most one OpenSegment per step.
            expect(
              cmds.whereType<OpenSegment>().length,
              lessThanOrEqualTo(1),
              reason: 'seed $seed i=$i: more than one OpenSegment',
            );

            for (final cmd in cmds) {
              if (cmd is OpenSegment) {
                openSegStartMs = cmd.startMs;
              } else if (cmd is CloseSegment) {
                if (openSegStartMs != null) {
                  expect(
                    cmd.endMs,
                    greaterThanOrEqualTo(openSegStartMs),
                    reason:
                        'seed $seed i=$i: CloseSegment.endMs ${cmd.endMs} '
                        '< open startMs $openSegStartMs',
                  );
                }
                openSegStartMs = null;
              } else if (cmd is EndTrip) {
                // Must co-occur with a CloseSegment in the same step.
                expect(
                  cmds.any((c) => c is CloseSegment),
                  isTrue,
                  reason: 'seed $seed i=$i: EndTrip without CloseSegment',
                );
                // EndTrip.endMs >= tripStartMs (use pre-step state).
                if (state.tripStartMs != null) {
                  expect(
                    cmd.endMs,
                    greaterThanOrEqualTo(state.tripStartMs!),
                    reason:
                        'seed $seed i=$i: EndTrip.endMs ${cmd.endMs} '
                        '< tripStartMs ${state.tripStartMs}',
                  );
                }
              } else if (cmd is StartGps) {
                // No consecutive StartGps with the same mode without StopGps.
                if (lastGpsMode != null) {
                  expect(
                    cmd.mode,
                    isNot(lastGpsMode),
                    reason:
                        'seed $seed i=$i: consecutive StartGps(${cmd.mode}) '
                        'without StopGps',
                  );
                }
                lastGpsMode = cmd.mode;
              } else if (cmd is StopGps) {
                lastGpsMode = null;
              }
            }

            state = result.state;
          }
        }
      },
    );
  });
}
