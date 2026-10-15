import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/analyze_log.dart';

Future<LogAnalysis> analyzeFixture(String name) async {
  final lines = await File('test/fixtures/$name.jsonl').readAsLines();
  return analyzeLines(lines);
}

void main() {
  test('measures tap and intent latency to the first accepted fix', () async {
    final analysis = await analyzeFixture('latencies');

    expect(analysis.startLatenciesMs, [1000]);
    expect(analysis.tapLatenciesMs, [1050]);
    expect(analysis.intentLatenciesMs, [1100]);
  });

  test('uses sequence and uptime when the wall clock regresses', () async {
    final analysis = await analyzeFixture('clock_regression');

    expect(analysis.startLatenciesMs, [1000]);
    expect(analysis.invalidSuccessNotifications, 0);
  });

  test('counts fix timestamp gaps over 30 seconds', () async {
    final analysis = await analyzeFixture('fix_timestamp_gaps');

    expect(analysis.fixTimestampGapsOver30Seconds, 1);
  });

  test('keeps timestamp gaps within each ride', () async {
    final analysis = await analyzeFixture('multi_ride_gaps');

    expect(analysis.fixTimestampGapsOver30Seconds, 0);
    expect(analysis.receivedTimestampGapsOver30Seconds, 0);
  });

  test('counts received timestamp gaps over 30 seconds', () async {
    final analysis = await analyzeFixture('received_timestamp_gaps');

    expect(analysis.receivedTimestampGapsOver30Seconds, 1);
  });

  test('calculates the accepted and rejected fix ratio', () async {
    final analysis = await analyzeFixture('accepted_ratio');

    expect(analysis.acceptedFixes, 2);
    expect(analysis.rejectedFixes, 3);
    expect(analysis.acceptedRatio, closeTo(2 / 5, 0.0001));
  });

  test('counts success notifications without a prior accepted fix', () async {
    final analysis = await analyzeFixture('invalid_success_notification');

    expect(analysis.invalidSuccessNotifications, 1);
  });

  test('counts recovery attempts', () async {
    final analysis = await analyzeFixture('recovery_attempts');

    expect(analysis.recoveryAttempts, 2);
  });

  test('skips and counts malformed lines without crashing', () async {
    final analysis = await analyzeFixture('malformed_lines');

    expect(analysis.totalLines, 3);
    expect(analysis.malformedLines, 2);
    expect(analysis.acceptedFixes, 1);
  });

  test('counts records missing sequence or uptime as malformed', () async {
    final analysis = await analyzeFixture('missing_required_fields');

    expect(analysis.totalLines, 3);
    expect(analysis.malformedLines, 2);
    expect(analysis.acceptedFixes, 1);
  });

  test('handles an empty file', () async {
    final analysis = await analyzeFixture('empty');

    expect(analysis.totalLines, 0);
    expect(analysis.malformedLines, 0);
    expect(analysis.acceptedFixes, 0);
    expect(analysis.rejectedFixes, 0);
  });
}
