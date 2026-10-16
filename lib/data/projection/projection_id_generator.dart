import 'dart:math';

abstract interface class ProjectionIdGenerator {
  String nextTripId();
  String nextSegmentId();
}

class RandomProjectionIdGenerator implements ProjectionIdGenerator {
  RandomProjectionIdGenerator([Random? random])
    : _random = random ?? Random.secure();

  final Random _random;

  @override
  String nextTripId() => _nextId();

  @override
  String nextSegmentId() => _nextId();

  String _nextId() {
    final values = List<int>.generate(16, (_) => _random.nextInt(256));
    final hex = values
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
