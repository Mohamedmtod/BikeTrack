import 'diagnostics_coordinator.dart';
import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';

class RawEventWriter {
  RawEventWriter(this._repository, {this.onPersisted, this.diagnostics});

  final EventRepository _repository;
  final DiagnosticsCoordinator? diagnostics;
  final void Function()? onPersisted;
  Future<void> _tail = Future<void>.value();

  Future<int> append(NewEvent event) {
    final operation = _tail.then((_) async {
      final int id;
      try {
        id = await _repository.append(event);
      } catch (error) {
        try {
          diagnostics?.rawWriteFailed(event, error);
        } catch (_) {
          // Best-effort reporting must preserve the append error.
        }
        rethrow;
      }
      try {
        onPersisted?.call();
      } catch (_) {
        // A notification failure cannot turn a committed append into a failed write.
      }
      return id;
    });
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<void> get drained => _tail;
}
