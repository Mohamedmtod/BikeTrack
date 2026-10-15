import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/analyze_log.dart';

void main() {
  test(
    'analyzes probe JSONL fixture without aborting on malformed lines',
    () async {
      final lines = await File('test/fixtures/probe_log.jsonl').readAsLines();

      final analysis = analyzeLines(lines);

      expect(analysis.totalLines, 10);
      expect(analysis.malformedLines, 1);
      expect(analysis.acceptedFixes, 2);
      expect(analysis.rejectedFixes, 1);
      expect(analysis.acceptedRatio, closeTo(2 / 3, 0.0001));
      expect(analysis.fixTimestampGapsOver30Seconds, 1);
      expect(analysis.receivedTimestampGapsOver30Seconds, 1);
      expect(analysis.startLatenciesMs, [1000]);
      expect(analysis.tapLatenciesMs, [1050]);
      expect(analysis.intentLatenciesMs, [1100]);
      expect(analysis.invalidSuccessNotifications, 1);
      expect(analysis.recoveryAttempts, 1);
    },
  );
}
