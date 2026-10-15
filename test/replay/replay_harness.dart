import 'dart:io';

import 'package:biketrack/domain/domain.dart';

class ReplayRow {
  final int timestampMs;
  final double latitudeDeg;
  final double longitudeDeg;
  final double hAccuracyM;
  final bool isStationary;
  final ActivityType activityType;
  final Confidence confidence;
  final double? cadenceSps;
  final double? speedMps;
  final double? stopPatternScore;

  const ReplayRow({
    required this.timestampMs,
    required this.latitudeDeg,
    required this.longitudeDeg,
    required this.hAccuracyM,
    required this.isStationary,
    required this.activityType,
    required this.confidence,
    required this.cadenceSps,
    required this.speedMps,
    required this.stopPatternScore,
  });

  ActivityWindow get activityWindow => ActivityWindow(
    cmTypes: {activityType},
    cmConfidence: confidence,
    cadenceSps: cadenceSps,
    speedMps: speedMps,
    stopPatternScore: stopPatternScore,
  );

  GpsSample get gpsSample => GpsSample(
    tsMs: timestampMs,
    position: GeoPoint(latitudeDeg, longitudeDeg),
    hAccuracyM: hAccuracyM,
  );
}

List<ReplayRow> loadReplayFixture(String name) {
  final lines = File('test/fixtures/$name').readAsLinesSync();
  final rows = <ReplayRow>[];

  for (final line in lines.skip(1)) {
    if (line.isEmpty) continue;
    final fields = line.split(',');
    rows.add(
      ReplayRow(
        timestampMs: int.parse(fields[0]),
        latitudeDeg: double.parse(fields[1]),
        longitudeDeg: double.parse(fields[2]),
        hAccuracyM: double.parse(fields[3]),
        isStationary: fields[4] == 'true',
        activityType: ActivityType.values.byName(fields[5]),
        confidence: Confidence.values.byName(fields[6]),
        cadenceSps: _nullableDouble(fields[7]),
        speedMps: _nullableDouble(fields[8]),
        stopPatternScore: _nullableDouble(fields[9]),
      ),
    );
  }

  return rows;
}

double? _nullableDouble(String value) =>
    value.isEmpty ? null : double.parse(value);
