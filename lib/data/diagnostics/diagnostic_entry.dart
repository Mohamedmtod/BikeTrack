class DiagnosticsConfig {
  const DiagnosticsConfig({
    this.retention = const Duration(days: 30),
    this.maxEntries = 10000,
    this.maxBundleBytes = 25000000,
  }) : assert(maxEntries > 0),
       assert(maxBundleBytes > 0);

  final Duration retention;
  final int maxEntries;
  final int maxBundleBytes;
}

class NewDiagnosticEntry {
  const NewDiagnosticEntry({
    required this.tsUtc,
    required this.category,
    required this.severity,
    required this.operation,
    required this.detailsJson,
    this.rawEventId,
  });

  final int tsUtc;
  final String category;
  final String severity;
  final String operation;
  final int? rawEventId;
  final String detailsJson;
}

class StoredDiagnosticEntry extends NewDiagnosticEntry {
  const StoredDiagnosticEntry({
    required this.id,
    required super.tsUtc,
    required super.category,
    required super.severity,
    required super.operation,
    required super.detailsJson,
    super.rawEventId,
  });

  final int id;
}
