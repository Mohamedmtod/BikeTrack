import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

import 'replay_harness.dart';

void main() {
  group('CSV domain replays', () {
    test('stationary_drift_30min.csv adds zero distance', () {
      final replay = _replay('stationary_drift_30min.csv');

      expect(
        replay.rows.last.timestampMs - replay.rows.first.timestampMs,
        1800000,
      );
      expect(replay.distanceM, 0.0);
    });

    test(
      'traffic_light_stops.csv classifies five 60-second stationary stops',
      () {
        final replay = _replay('traffic_light_stops.csv');
        final stops = _stationaryRuns(replay.rows, replay.classifications);

        expect(stops, hasLength(5));
        for (final stop in stops) {
          expect(stop.last.timestampMs - stop.first.timestampMs, 60000);
        }
      },
    );

    test('bike_then_walk.csv classifies cycling followed by walking', () {
      final replay = _replay('bike_then_walk.csv');

      expect(
        replay.classifications,
        containsAllInOrder([ActivityType.cycling, ActivityType.walking]),
      );
    });

    test(
      'bike_then_microbus.csv classifies cycling followed by automotive',
      () {
        final replay = _replay('bike_then_microbus.csv');

        expect(
          replay.classifications,
          containsAllInOrder([ActivityType.cycling, ActivityType.automotive]),
        );
      },
    );

    test(
      'gps_tunnel_gap.csv resets the GPS anchor without adding distance',
      () {
        final replay = _replay('gps_tunnel_gap.csv');

        expect(replay.filterResults.last.reason, RejectReason.anchorReset);
        expect(replay.filterResults.last.distanceAddedM, 0.0);
      },
    );

    test('real_trip_regression_template.csv replays as a future regression fixture', () {
      final replay = _replay('real_trip_regression_template.csv');

      expect(replay.rows, isNotEmpty);
      expect(replay.classifications, everyElement(ActivityType.cycling));
      expect(replay.distanceM, greaterThan(0.0));
    });
  });
}

ReplayResult _replay(String fixtureName) {
  final rows = loadReplayFixture(fixtureName);
  var state = const FilterState();
  var distanceM = 0.0;
  final classifications = <ActivityType>[];
  final filterResults = <FilterResult>[];

  for (final row in rows) {
    classifications.add(ActivityClassifier.classify(row.activityWindow).type);
    final result = GpsFilter.step(
      state,
      row.gpsSample,
      nowMs: row.timestampMs,
      isStationary: row.isStationary,
      cfg: const GpsFilterConfig(),
    );
    state = result.newState;
    distanceM += result.distanceAddedM;
    filterResults.add(result);
  }

  return ReplayResult(
    rows: rows,
    classifications: classifications,
    filterResults: filterResults,
    distanceM: distanceM,
  );
}

List<List<ReplayRow>> _stationaryRuns(
  List<ReplayRow> rows,
  List<ActivityType> classifications,
) {
  final runs = <List<ReplayRow>>[];
  var current = <ReplayRow>[];

  for (var i = 0; i < rows.length; i++) {
    if (classifications[i] == ActivityType.stationary) {
      current.add(rows[i]);
    } else if (current.isNotEmpty) {
      runs.add(current);
      current = <ReplayRow>[];
    }
  }

  if (current.isNotEmpty) runs.add(current);
  return runs;
}

class ReplayResult {
  final List<ReplayRow> rows;
  final List<ActivityType> classifications;
  final List<FilterResult> filterResults;
  final double distanceM;

  const ReplayResult({
    required this.rows,
    required this.classifications,
    required this.filterResults,
    required this.distanceM,
  });
}
