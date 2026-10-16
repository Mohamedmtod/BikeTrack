import '../../domain/shared/event_source.dart';

class NewEvent {
  const NewEvent({
    required this.tsUtc,
    required this.source,
    required this.type,
    required this.payloadJson,
    this.tripId,
  });

  final int tsUtc;
  final EventSource source;
  final String type;
  final String payloadJson;
  final String? tripId;
}

class StoredEvent {
  const StoredEvent({
    required this.id,
    required this.tsUtc,
    required this.source,
    required this.type,
    required this.payloadJson,
    required this.tripId,
    required this.processed,
  });

  final int id;
  final int tsUtc;
  final EventSource source;
  final String type;
  final String payloadJson;
  final String? tripId;
  final bool processed;
}
