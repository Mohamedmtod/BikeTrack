import 'dart:convert';
import 'dart:io';

class LogAnalysis {
  const LogAnalysis({
    required this.totalLines,
    required this.malformedLines,
    required this.acceptedFixes,
    required this.rejectedFixes,
    required this.fixTimestampGapsOver30Seconds,
    required this.receivedTimestampGapsOver30Seconds,
    required this.invalidSuccessNotifications,
    required this.recoveryAttempts,
    required this.startLatenciesMs,
    required this.tapLatenciesMs,
    required this.intentLatenciesMs,
  });

  final int totalLines;
  final int malformedLines;
  final int acceptedFixes;
  final int rejectedFixes;
  final int fixTimestampGapsOver30Seconds;
  final int receivedTimestampGapsOver30Seconds;
  final int invalidSuccessNotifications;
  final int recoveryAttempts;
  final List<int> startLatenciesMs;
  final List<int> tapLatenciesMs;
  final List<int> intentLatenciesMs;

  double get acceptedRatio {
    final totalFixes = acceptedFixes + rejectedFixes;
    return totalFixes == 0 ? 0 : acceptedFixes / totalFixes;
  }

  String report() => [
    'lines=$totalLines malformed=$malformedLines',
    'fixes accepted=$acceptedFixes rejected=$rejectedFixes '
        'accepted_ratio=${acceptedRatio.toStringAsFixed(3)}',
    'gaps_over_30s fix_ts=$fixTimestampGapsOver30Seconds '
        'recv=$receivedTimestampGapsOver30Seconds',
    'start_to_first_accepted_fix_ms=${_latencyText(startLatenciesMs)}',
    'tap_to_first_accepted_fix_ms=${_latencyText(tapLatenciesMs)}',
    'intent_to_first_accepted_fix_ms=${_latencyText(intentLatenciesMs)}',
    'invalid_notify_success=$invalidSuccessNotifications',
    'recovery_attempts=$recoveryAttempts',
  ].join('\n');

  static String _latencyText(List<int> latencies) =>
      latencies.isEmpty ? 'none' : latencies.join(',');
}

class _Record {
  const _Record(this.wallMs, this.event, this.payload);

  final int wallMs;
  final String event;
  final Map<String, dynamic> payload;

  String? get rideID => payload['ride_id'] as String?;
  String? get attemptID => payload['attempt_id'] as String?;
}

LogAnalysis analyzeLines(Iterable<String> lines) {
  final records = <_Record>[];
  var totalLines = 0;
  var malformedLines = 0;

  for (final line in lines) {
    totalLines++;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic> ||
          decoded['wall_ms'] is! num ||
          decoded['event'] is! String ||
          decoded['payload'] is! Map) {
        malformedLines++;
        continue;
      }
      records.add(
        _Record(
          (decoded['wall_ms'] as num).toInt(),
          decoded['event'] as String,
          Map<String, dynamic>.from(decoded['payload'] as Map),
        ),
      );
    } on FormatException {
      malformedLines++;
    }
  }

  final startsByAttempt = <String, _Record>{};
  for (final record in records.where(
    (record) => record.event == 'start_requested',
  )) {
    final attemptID = record.attemptID;
    if (attemptID != null && record.rideID != null) {
      startsByAttempt[attemptID] = record;
    }
  }

  final acceptedFixes = records
      .where(
        (record) => record.event == 'fix' && record.payload['accepted'] == true,
      )
      .toList();
  final rejectedFixes = records
      .where(
        (record) => record.event == 'fix' && record.payload['accepted'] != true,
      )
      .length;
  final acceptedByRide = <String, List<_Record>>{};
  for (final fix in acceptedFixes) {
    final rideID = fix.rideID;
    if (rideID != null) {
      (acceptedByRide[rideID] ??= []).add(fix);
    }
  }

  int gapsFor(String key) {
    var gaps = 0;
    int? previous;
    for (final fix in acceptedFixes) {
      final value = fix.payload[key];
      if (value is! num) {
        continue;
      }
      final timestamp = value.toInt();
      if (previous != null && timestamp - previous > 30000) {
        gaps++;
      }
      previous = timestamp;
    }
    return gaps;
  }

  List<int> latencyFor(Iterable<_Record> beginnings) {
    final result = <int>[];
    for (final beginning in beginnings) {
      final rideID =
          beginning.rideID ??
          (beginning.attemptID == null
              ? null
              : startsByAttempt[beginning.attemptID]?.rideID);
      if (rideID == null) {
        continue;
      }
      final firstFix = acceptedByRide[rideID]
          ?.where((fix) => fix.wallMs >= beginning.wallMs)
          .firstOrNull;
      if (firstFix != null) {
        result.add(firstFix.wallMs - beginning.wallMs);
      }
    }
    return result;
  }

  var invalidSuccessNotifications = 0;
  for (final notification in records.where(
    (record) => record.event == 'notify_success',
  )) {
    final rideID = notification.rideID;
    final attemptID = notification.attemptID;
    final start = attemptID == null ? null : startsByAttempt[attemptID];
    final hasAcceptedFix =
        rideID != null &&
        (acceptedByRide[rideID] ?? const <_Record>[]).any(
          (fix) => fix.wallMs <= notification.wallMs,
        );
    if (rideID == null || start?.rideID != rideID || !hasAcceptedFix) {
      invalidSuccessNotifications++;
    }
  }

  return LogAnalysis(
    totalLines: totalLines,
    malformedLines: malformedLines,
    acceptedFixes: acceptedFixes.length,
    rejectedFixes: rejectedFixes,
    fixTimestampGapsOver30Seconds: gapsFor('fix_ts_ms'),
    receivedTimestampGapsOver30Seconds: gapsFor('recv_ms'),
    invalidSuccessNotifications: invalidSuccessNotifications,
    recoveryAttempts: records
        .where((record) => record.event == 'recovery_attempt')
        .length,
    startLatenciesMs: latencyFor(
      records.where((record) => record.event == 'start_requested'),
    ),
    tapLatenciesMs: latencyFor(
      records.where((record) => record.event == 'url_received'),
    ),
    intentLatenciesMs: latencyFor(
      records.where((record) => record.event == 'intent_invoked'),
    ),
  );
}

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/analyze_log.dart <probe_log.jsonl>');
    exitCode = 64;
    return;
  }
  final file = File(arguments.single);
  if (!await file.exists()) {
    stderr.writeln('Log file not found: ${file.path}');
    exitCode = 66;
    return;
  }
  final analysis = analyzeLines(await file.readAsLines());
  stdout.writeln(analysis.report());
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
