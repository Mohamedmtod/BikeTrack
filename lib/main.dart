import 'dart:async';

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
  late final RecorderEventIngestion _ingestion;
  late final RecorderSession _session;

  @override
  void initState() {
    super.initState();
    _database = AppDatabase();
    _repository = EventRepository(_database);
    _runtime = RecorderRuntime();
    _projections = ProjectionDrainCoordinator(
      EventProjectionProcessor(_database, RandomProjectionIdGenerator()),
      _repository,
      _runtime,
    );
    _writer = RawEventWriter(
      _repository,
      onPersisted: _projections.scheduleAutomatic,
    );
    _bridge = RecorderBridge();
    int clockMs() => DateTime.now().millisecondsSinceEpoch;
    _ingestion = RecorderEventIngestion(_bridge, _writer, _runtime, clockMs);
    _session = RecorderSession(_bridge, _writer, _runtime, clockMs);
    _bridge.installCallbacks();
    _projections.scheduleAutomatic();
  }

  Future<void> _disposeResources() async {
    await _ingestion.dispose();
    await _writer.drained;
    await _projections.drained;
    await _bridge.dispose();
    await _database.close();
    _runtime.dispose();
  }

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
      ),
    );
  }
}
