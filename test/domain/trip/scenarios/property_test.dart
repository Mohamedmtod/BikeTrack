import 'dart:math';

import 'package:biketrack/domain/activity/activity_state.dart';
import 'package:biketrack/domain/activity/activity_type.dart';
import 'package:biketrack/domain/config/trip_config.dart';
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

    test('21: idle+Activity(cycling) -> idle, no commands', () {
      final result = TripStateMachine.step(
        TripState.idle(),
        ActivityChanged(
          60000,
          ActivityState(type: ActivityType.cycling, sinceMs: 0),
        ),
        cfg,
      );
      expect(result.state.isIdle, isTrue);
      expect(result.commands, isEmpty);
    });

    test('22: property: 500 random non-decreasing events never throw; '
        'status in {null,pending,active,paused,completed}; '
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
  });
}
