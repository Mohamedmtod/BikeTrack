import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';

class RawEventWriter {
  RawEventWriter(this._repository, {this.onPersisted});

  final EventRepository _repository;
  final void Function()? onPersisted;
  Future<void> _tail = Future<void>.value();

  Future<int> append(NewEvent event) {
    final operation = _tail.then((_) async {
      final id = await _repository.append(event);
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
