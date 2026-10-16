import 'dart:convert';
import 'dart:io';

import '../../app/recorder_runtime.dart';
import '../events/event_repository.dart';
import '../projection/projection_state_repository.dart';
import 'diagnostic_entry.dart';
import 'diagnostic_repository.dart';

class DiagnosticExportResult {
  const DiagnosticExportResult(this.path, this.byteSize);

  final String path;
  final int byteSize;
}

class DiagnosticBundleExporter {
  const DiagnosticBundleExporter({
    required this.events,
    required this.diagnostics,
    required this.projections,
    required this.runtime,
    required this.documentsPath,
    this.config = const DiagnosticsConfig(),
    this.appVersion,
    this.platformMetadata,
    this.now = DateTime.now,
  });

  final EventRepository events;
  final DiagnosticRepository diagnostics;
  final ProjectionStateRepository projections;
  final RecorderRuntime runtime;
  final Future<String> Function() documentsPath;
  final DiagnosticsConfig config;
  final String? appVersion;
  final Map<String, Object?>? platformMetadata;
  final DateTime Function() now;

  Future<DiagnosticExportResult> export() async {
    final generatedAt = now().toUtc();
    final rawEvents = await events.readAll();
    final entries = await diagnostics.readAll();
    final snapshot = await projections.readStoredJson();
    final bundle = <String, Object?>{
      'manifest': {
        'format_version': 1,
        'generated_at_utc': generatedAt.toIso8601String(),
        if (appVersion != null && appVersion!.isNotEmpty)
          'app_version': appVersion,
        if (platformMetadata != null) 'platform': platformMetadata,
      },
      'raw_events': [
        for (final event in rawEvents)
          {
            'id': event.id,
            'ts_utc': event.tsUtc,
            'source': event.source.name,
            'type': event.type,
            'payloadJson': event.payloadJson,
            'trip_id': event.tripId,
            'processed': event.processed,
          },
      ],
      'diagnostic_entries': [
        for (final entry in entries)
          {
            'id': entry.id,
            'ts_utc': entry.tsUtc,
            'category': entry.category,
            'severity': entry.severity,
            'operation': entry.operation,
            'raw_event_id': entry.rawEventId,
            'details': jsonDecode(entry.detailsJson),
          },
      ],
      if (snapshot != null) 'projection_snapshot': jsonDecode(snapshot),
      'projection_runtime': {
        'state': runtime.projectionState.name,
        if (runtime.blockingProjectionEvent case final event?)
          'blocking_event_id': event.id,
        'error': ?runtime.latestProjectionError,
      },
    };
    final bytes = utf8.encode(jsonEncode(bundle));
    if (bytes.length > config.maxBundleBytes) {
      throw StateError(
        'Diagnostic bundle exceeds ${config.maxBundleBytes} bytes '
        '(${bytes.length} bytes); no file was written',
      );
    }
    final directory = await documentsPath();
    final file = File(
      '$directory${Platform.pathSeparator}biketrack-diagnostics-${generatedAt.microsecondsSinceEpoch}.json',
    );
    await file.create(exclusive: true);
    try {
      await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      try {
        await file.delete();
      } catch (_) {
        // Keep the original export error if cleanup itself fails.
      }
      rethrow;
    }
    return DiagnosticExportResult(file.path, bytes.length);
  }
}
