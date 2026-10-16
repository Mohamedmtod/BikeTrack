import 'dart:async';
import 'dart:io';

import 'app/diagnostics_coordinator.dart';
import 'bridge/generated/recorder.g.dart';
import 'data/diagnostics/diagnostic_bundle_exporter.dart';
import 'data/diagnostics/diagnostic_repository.dart';
import 'data/projection/projection_state_repository.dart';

import 'package:flutter/material.dart';

import 'app/projection_drain_coordinator.dart';
import 'app/raw_event_writer.dart';
import 'app/recorder_event_ingestion.dart';
import 'app/recorder_runtime.dart';
import 'app/recorder_session.dart';
import 'bridge/recorder_bridge.dart';
import 'data/database/app_database.dart';
import 'data/events/event_repository.dart';
import 'data/projection/event_projection_processor.dart';
import 'data/projection/projection_id_generator.dart';
import 'debug/recorder_debug_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BikeTrackApp());
}

Future<void> disposeRecorderResources({
  required RecorderEventIngestion ingestion,
  required RecorderSession session,
  required RawEventWriter writer,
  required ProjectionDrainCoordinator projections,
  required RecorderBridge bridge,
  required AppDatabase database,
  required RecorderRuntime runtime,
  DiagnosticsCoordinator? diagnostics,
}) async {
  await ingestion.dispose();
  await session.drained;
  await writer.drained;
  await projections.drained;
  await bridge.dispose();
  if (diagnostics != null) await diagnostics.drained;
  await database.close();
  runtime.dispose();
}

class BikeTrackApp extends StatefulWidget {
  const BikeTrackApp({super.key});

  @override
  State<BikeTrackApp> createState() => _BikeTrackAppState();
}

class _BikeTrackAppState extends State<BikeTrackApp> {
  late final AppDatabase _database;
  late final RecorderBridge _bridge;
  late final EventRepository _repository;
  late final RawEventWriter _writer;
  late final ProjectionDrainCoordinator _projections;
  late final RecorderRuntime _runtime;
  late final DiagnosticsCoordinator _diagnostics;
  late final DiagnosticBundleExporter _exporter;
  late final RecorderEventIngestion _ingestion;
  late final RecorderSession _session;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _repository = EventRepository(_database);
    int clockMs() => DateTime.now().millisecondsSinceEpoch;
    _diagnostics = DiagnosticsCoordinator(
      DiagnosticRepository(_database),
      clockMs: clockMs,
    );
    _runtime = RecorderRuntime(diagnostics: _diagnostics);
    _exporter = DiagnosticBundleExporter(
      events: _repository,
      diagnostics: DiagnosticRepository(_database),
      projections: ProjectionStateRepository(_database),
      runtime: _runtime,
      documentsPath: RecorderHostApi().documentsDirectoryPath,
      platformMetadata: {
        'operating_system': Platform.operatingSystem,
        'operating_system_version': Platform.operatingSystemVersion,
      },
    );
    _projections = ProjectionDrainCoordinator(
      EventProjectionProcessor(_database, RandomProjectionIdGenerator()),
      _repository,
      _runtime,
    );
    _writer = RawEventWriter(
      _repository,
      onPersisted: _projections.scheduleAutomatic,
      diagnostics: _diagnostics,
    );
    _bridge = RecorderBridge();
    _ingestion = RecorderEventIngestion(_bridge, _writer, _runtime, clockMs);
    _session = RecorderSession(_bridge, _writer, _runtime, clockMs);
    _bridge.installCallbacks();
    _projections.scheduleAutomatic();
  }

  Future<void> _disposeResources() => disposeRecorderResources(
    ingestion: _ingestion,
    session: _session,
    writer: _writer,
    projections: _projections,
    bridge: _bridge,
    database: _database,
    runtime: _runtime,
    diagnostics: _diagnostics,
  );

  @override
  void dispose() {
    unawaited(_disposeResources());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BikeTrack recorder',
      home: RecorderDebugScreen(
        session: _session,
        runtime: _runtime,
        repository: _repository,
        projections: _projections,
        exporter: _exporter,
      ),
    );
  }
}
