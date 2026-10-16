import '../data/events/event_record.dart';
import '../data/events/event_repository.dart';

class RawEventWriter {
  RawEventWriter(this._repository);

  final EventRepository _repository;
  Future<void> _tail = Future<void>.value();

  Future<int> append(NewEvent event) {
    final operation = _tail.then((_) => _repository.append(event));
    _tail = operation.then<void>((_) {}, onError: (_, _) {});
    return operation;
  }

  Future<void> get drained => _tail;
}
