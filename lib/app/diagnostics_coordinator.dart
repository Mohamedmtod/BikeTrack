import 'dart:async';
import 'dart:convert';

import '../data/diagnostics/diagnostic_entry.dart';
import '../data/diagnostics/diagnostic_repository.dart';
import '../data/events/event_record.dart';

class DiagnosticsCoordinator {
  DiagnosticsCoordinator(this._repository, {required this.clockMs});

  final DiagnosticRepository _repository;
  final int Function() clockMs;
  final Set<Future<void>> _pending = {};

  void rawWriteFailed(NewEvent event, Object error) => _record(
    category: 'raw_event_write',
    operation: event.type,
    error: error,
    eventType: event.type,
  );

  void nativeFailed(String operation, Object error) =>
      _record(category: 'native_recorder', operation: operation, error: error);

  void projectionFailed(StoredEvent? event, Object error) => _record(
    category: 'projection_drain',
    operation: 'process_next',
    rawEventId: event?.id,
    error: error,
    eventType: event?.type,
  );

  void _record({
    required String category,
    required String operation,
    required Object error,
    String? eventType,
    int? rawEventId,
  }) {
    try {
      final details = {'error': '$error', 'event_type': ?eventType};
      final timestamp = clockMs();
      final operationFuture = Future<void>.sync(() async {
        await _repository.append(
          NewDiagnosticEntry(
            tsUtc: timestamp,
            category: category,
            severity: 'error',
            operation: operation,
            rawEventId: rawEventId,
            detailsJson: jsonEncode(details),
          ),
          nowUtcMs: timestamp,
        );
      });
      final safe = operationFuture.catchError((Object _) {
        // Diagnostics are best effort and never generate diagnostics themselves.
      });
      _pending.add(safe);
      unawaited(safe.whenComplete(() => _pending.remove(safe)));
    } catch (_) {
      // Even synchronous diagnostics failures cannot affect the source operation.
    }
  }

  Future<void> get drained async {
    await Future.wait(_pending.toList());
  }
}
