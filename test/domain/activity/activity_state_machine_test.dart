import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

int _s(int sec) => sec * 1000;

void main() {
  group('ActivityStateMachine (§6.1, D-024)', () {
    test('1 initial: first input cycling at t=0 -> type unknown, candidate cycling, candidateSinceMs 0', () {
      final initial = ActivityState.initial(_s(0));
      final res = ActivityStateMachine.step(
        initial,
        ActivityType.cycling,
        _s(0),
      );
      expect(res.state.type, ActivityType.unknown);
      expect(res.state.candidate, ActivityType.cycling);
      expect(res.state.candidateSinceMs, _s(0));
      expect(res.state.lastUpdateMs, _s(0));
      expect(res.changed, isFalse);
    });

    test('2 cycling at 0..25 -> still unknown; at t=30 -> cycling, sinceMs 0, changed true', () {
      var state = ActivityState.initial(_s(0));
      for (var t = 0; t <= 25; t += 5) {
        final r = ActivityStateMachine.step(state, ActivityType.cycling, _s(t));
        state = r.state;
        expect(state.type, ActivityType.unknown);
        expect(r.changed, isFalse);
      }
      final r30 = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(30),
      );
      expect(r30.state.type, ActivityType.cycling);
      expect(r30.state.sinceMs, _s(0));
      expect(r30.state.candidate, isNull);
      expect(r30.changed, isTrue);
    });

    test('3 walking at 0..15 -> unknown; at t=20 -> walking, sinceMs 0', () {
      var state = ActivityState.initial(_s(0));
      for (var t = 0; t <= 15; t += 5) {
        final r = ActivityStateMachine.step(state, ActivityType.walking, _s(t));
        state = r.state;
        expect(state.type, ActivityType.unknown);
        expect(r.changed, isFalse);
      }
      final r20 = ActivityStateMachine.step(
        state,
        ActivityType.walking,
        _s(20),
      );
      expect(r20.state.type, ActivityType.walking);
      expect(r20.state.sinceMs, _s(0));
      expect(r20.state.candidate, isNull);
      expect(r20.changed, isTrue);
    });

    test('4 flicker: cycling 0..20, walking at 25, cycling 30..55 -> unknown at 55; cycling at 60 with sinceMs 30', () {
      var state = ActivityState.initial(_s(0));
      for (var t = 0; t <= 20; t += 5) {
        state = ActivityStateMachine.step(
          state,
          ActivityType.cycling,
          _s(t),
        ).state;
      }
      state = ActivityStateMachine.step(
        state,
        ActivityType.walking,
        _s(25),
      ).state;
      expect(state.type, ActivityType.unknown);
      expect(state.candidate, ActivityType.walking);
      expect(state.candidateSinceMs, _s(25));

      for (var t = 30; t <= 55; t += 5) {
        state = ActivityStateMachine.step(
          state,
          ActivityType.cycling,
          _s(t),
        ).state;
      }
      expect(state.type, ActivityType.unknown);
      expect(state.candidate, ActivityType.cycling);
      expect(state.candidateSinceMs, _s(30));

      final r60 = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(60),
      );
      expect(r60.state.type, ActivityType.cycling);
      expect(r60.state.sinceMs, _s(30));
      expect(r60.state.candidate, isNull);
      expect(r60.changed, isTrue);
    });

    test('5 same-as-current clears candidate: from cycling state, walking at 100, cycling at 105 -> candidate null; walking at 110 -> candidateSinceMs 110', () {
      var state = const ActivityState(
        type: ActivityType.cycling,
        sinceMs: 0,
        lastUpdateMs: 95000,
      );

      state = ActivityStateMachine.step(
        state,
        ActivityType.walking,
        _s(100),
      ).state;
      expect(state.candidate, ActivityType.walking);
      expect(state.candidateSinceMs, _s(100));

      final r105 = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(105),
      );
      state = r105.state;
      expect(state.candidate, isNull);
      expect(state.candidateSinceMs, isNull);
      expect(r105.changed, isFalse);

      final r110 = ActivityStateMachine.step(
        state,
        ActivityType.walking,
        _s(110),
      );
      expect(r110.state.candidate, ActivityType.walking);
      expect(r110.state.candidateSinceMs, _s(110));
      expect(r110.changed, isFalse);
    });

    test('6 automotive: unknown at t=55, automotive at t=60', () {
      var state = ActivityState.initial(_s(0));
      for (var t = 0; t <= 55; t += 5) {
        final r = ActivityStateMachine.step(
          state,
          ActivityType.automotive,
          _s(t),
        );
        state = r.state;
        expect(state.type, ActivityType.unknown);
        expect(r.changed, isFalse);
      }
      final r60 = ActivityStateMachine.step(
        state,
        ActivityType.automotive,
        _s(60),
      );
      expect(r60.state.type, ActivityType.automotive);
      expect(r60.state.sinceMs, _s(0));
      expect(r60.state.candidate, isNull);
      expect(r60.changed, isTrue);
    });

    test('7 stationary: unknown at t=40, stationary at t=45', () {
      var state = ActivityState.initial(_s(0));
      for (var t = 0; t <= 40; t += 5) {
        final r = ActivityStateMachine.step(
          state,
          ActivityType.stationary,
          _s(t),
        );
        state = r.state;
        expect(state.type, ActivityType.unknown);
        expect(r.changed, isFalse);
      }
      final r45 = ActivityStateMachine.step(
        state,
        ActivityType.stationary,
        _s(45),
      );
      expect(r45.state.type, ActivityType.stationary);
      expect(r45.state.sinceMs, _s(0));
      expect(r45.state.candidate, isNull);
      expect(r45.changed, isTrue);
    });

    test('8 to unknown: from cycling state, unknown at 0..25 -> still cycling; at 30 -> unknown', () {
      var state = const ActivityState(
        type: ActivityType.cycling,
        sinceMs: 0,
        lastUpdateMs: -5000,
      );
      for (var t = 0; t <= 25; t += 5) {
        final r = ActivityStateMachine.step(state, ActivityType.unknown, _s(t));
        state = r.state;
        expect(state.type, ActivityType.cycling);
        expect(r.changed, isFalse);
      }
      final r30 = ActivityStateMachine.step(
        state,
        ActivityType.unknown,
        _s(30),
      );
      expect(r30.state.type, ActivityType.unknown);
      expect(r30.state.sinceMs, _s(0));
      expect(r30.state.candidate, isNull);
      expect(r30.changed, isTrue);
    });

    test('9 out-of-order: input with nowMs < lastUpdateMs -> state equal to previous, changed false', () {
      final current = const ActivityState(
        type: ActivityType.cycling,
        sinceMs: 0,
        candidate: ActivityType.walking,
        candidateSinceMs: 5000,
        lastUpdateMs: 10000,
      );
      final res = ActivityStateMachine.step(
        current,
        ActivityType.walking,
        9000,
      );
      expect(res.state, equals(current));
      expect(res.changed, isFalse);
    });

    test(
      '10 duplicate time: input with nowMs == lastUpdateMs -> state unchanged',
      () {
        final current = const ActivityState(
          type: ActivityType.cycling,
          sinceMs: 0,
          candidate: ActivityType.walking,
          candidateSinceMs: 5000,
          lastUpdateMs: 10000,
        );
        final res = ActivityStateMachine.step(
          current,
          ActivityType.walking,
          10000,
        );
        expect(res.state, equals(current));
        expect(res.changed, isFalse);
      },
    );

    test('11 evidence gap: cycling at 0, 5, 10, then cycling at 200 -> candidateSinceMs 200, type unknown; cycling every 5 s to 230 -> cycling, sinceMs 200', () {
      var state = ActivityState.initial(_s(0));
      state = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(0),
      ).state;
      state = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(5),
      ).state;
      state = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(10),
      ).state;
      expect(state.candidate, ActivityType.cycling);
      expect(state.candidateSinceMs, _s(0));
      expect(state.lastUpdateMs, _s(10));

      final r200 = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(200),
      );
      state = r200.state;
      expect(state.candidate, ActivityType.cycling);
      expect(state.candidateSinceMs, _s(200));
      expect(state.type, ActivityType.unknown);
      expect(r200.changed, isFalse);

      for (var t = 205; t <= 225; t += 5) {
        state = ActivityStateMachine.step(
          state,
          ActivityType.cycling,
          _s(t),
        ).state;
        expect(state.type, ActivityType.unknown);
      }

      final r230 = ActivityStateMachine.step(
        state,
        ActivityType.cycling,
        _s(230),
      );
      expect(r230.state.type, ActivityType.cycling);
      expect(r230.state.sinceMs, _s(200));
      expect(r230.state.candidate, isNull);
      expect(r230.changed, isTrue);
    });
  });
}
