# CODEMAP — BikeTrack

lib/main.dart — Flutter application entry point wiring projected rides home and diagnostics
lib/domain/domain.dart — Barrel exporting the public domain interface
lib/domain/activity/activity_classifier.dart — Pure function activity classification from sensor windows
lib/domain/activity/activity_classifier_config.dart — Weights and trapezoid speed thresholds for ActivityClassifier
lib/domain/activity/activity_state.dart — ActivityState model with initial factory
lib/domain/activity/activity_state_config.dart — ActivityStateConfig thresholds and hysteresis values
lib/domain/activity/activity_state_machine.dart — Pure-Dart activity state machine step implementation
lib/domain/activity/activity_state_result.dart — Result model containing state and changed flag
lib/domain/activity/activity_type.dart — Physical activity classification enum
lib/domain/activity/activity_window.dart — Pre-aggregated sensor window model for ActivityClassifier
lib/domain/activity/classification_result.dart — Result model containing scores, best score, margin, and type
lib/domain/activity/classification_source.dart — Source determining activity classification enum
lib/domain/activity/membership.dart — Trapezoidal membership function calculation
lib/domain/config/domain_config.dart — Aggregated domain configuration root
lib/domain/config/trip_config.dart — Trip lifecycle and detection thresholds
lib/domain/geo/geo_point.dart — Immutable geographic coordinate representation
lib/domain/geo/haversine.dart — Great-circle distance calculation using Haversine formula
lib/domain/gps/filter_result.dart — Result model returned by GPS filter step
lib/domain/gps/filter_state.dart — Mutable state carried across GPS filter steps
lib/domain/gps/gps_filter.dart — Pure-Dart stateless GPS filter implementation
lib/domain/gps/gps_filter_config.dart — Configuration thresholds for GPS filter logic
lib/domain/gps/gps_sample.dart — Incoming GPS measurement data model
lib/domain/gps/reject_reason.dart — Reason enum for GPS sample rejection or special handling
lib/domain/shared/confidence.dart — Confidence level enum for detections and classifications
lib/domain/shared/event_source.dart — Originating source enum of domain events
lib/domain/shared/recording_state.dart — Recording fidelity and power state enum
lib/domain/trip/distance_status.dart — Distance reliability indicator enum
lib/domain/trip/gps_mode.dart — GPS power/accuracy mode enum commanded by TripStateMachine
lib/domain/trip/segment_type.dart — Trip segment activity type enum
lib/domain/trip/trip_close_reason.dart — Terminal trip close reason enum
lib/domain/trip/trip_command.dart — Sealed command hierarchy with value equality produced by TripStateMachine
lib/domain/trip/trip_event.dart — Sealed event hierarchy consumed by TripStateMachine
lib/domain/trip/trip_state.dart — Immutable trip state with idle factory, isIdle getter, and copyWith
lib/domain/trip/trip_state_machine.dart — Pure-Dart trip state machine dispatcher (time check, activity store, dispatch)
lib/domain/trip/trip_status.dart — Lifecycle status enum of a recorded trip
lib/domain/trip/trip_step_result.dart — Result model containing state and command list from one machine step
lib/domain/trip/transitions/active_transitions.dart — Active status transition rules (stop, pause, mode change)
lib/domain/trip/transitions/idle_transitions.dart — Idle and completed status transition rules
lib/domain/trip/transitions/paused_transitions.dart — Paused status transition rules (resume, stop, open-trip guard)
lib/domain/trip/transitions/pending_transitions.dart — Pending status transition rules (cycling detect, timeout)
lib/domain/trip/transitions/recovery_transitions.dart — GPS-gap and recovery terminal transition rules
lib/domain/trip/transitions/suspected_forgotten_transitions.dart — Suspected-forgotten transition and terminal closure rules
test/helpers/gps_helpers.dart — Shared helper functions and test fixture constants
test/fixtures/stationary_drift_30min.csv — Stationary GPS drift replay fixture spanning 30 minutes
test/fixtures/traffic_light_stops.csv — Cycling replay fixture with five 60-second stationary stops
test/fixtures/bike_then_walk.csv — Cycling-to-walking replay fixture
test/fixtures/bike_then_microbus.csv — Cycling-to-automotive replay fixture
test/fixtures/gps_tunnel_gap.csv — GPS gap replay fixture
test/fixtures/real_trip_regression_template.csv — Template-format real-trip regression replay fixture
test/replay/replay_harness.dart — Test-only CSV parser and public-domain input adapters
test/replay/domain_replay_test.dart — CSV replay tests for GPS and activity golden scenarios
test/widget_test.dart — Recorder, diagnostics, and projected ride UI tests
test/domain/activity/activity_classifier_config_test.dart — Unit tests for ActivityClassifierConfig assert validation
test/domain/activity/activity_classifier_test.dart — Unit and property tests for ActivityClassifier
test/domain/activity/activity_state_config_test.dart — Unit test for ActivityStateConfig assert validation
test/domain/activity/activity_state_machine_test.dart — Unit tests for ActivityStateMachine transitions and gap detection
test/domain/activity/activity_type_test.dart — Unit test for ActivityType enum values
test/domain/activity/classification_source_test.dart — Unit test for ClassificationSource enum values
test/domain/activity/membership_test.dart — Unit tests for trapezoidal membership function
test/domain/config/domain_config_test.dart — Unit tests for TripConfig defaults and DomainConfig gapMs assert
test/domain/geo/geo_point_test.dart — Unit tests for GeoPoint equality and toString
test/domain/geo/haversine_test.dart — Unit tests for Haversine distance and pure Dart constraint
test/domain/gps/gps_filter_checks_test.dart — Unit tests for individual GPS filter checks and resetAnchor
test/domain/gps/scenarios/drift_test.dart — Scenario tests for stationary drift and noise rejection
test/domain/gps/scenarios/motion_test.dart — Scenario tests for straight line motion and gap recovery
test/domain/gps/scenarios/outlier_test.dart — Scenario tests for single and consecutive GPS outliers
test/domain/shared/confidence_test.dart — Unit test for Confidence enum values
test/domain/shared/event_source_test.dart — Unit test for EventSource enum values
test/domain/shared/recording_state_test.dart — Unit test for RecordingState enum values
test/domain/trip/distance_status_test.dart — Unit test for DistanceStatus enum values
test/domain/trip/scenarios/active_paused_test.dart — Scenario tests 9–17, 20 for active and paused TripStateMachine transitions
test/domain/trip/scenarios/d027_regression_test.dart — Regression tests 23–26 for D-027 stale-evidence clearing and monotonic timestamp clamping
test/domain/trip/scenarios/phase2_test.dart — D-030 phase-2 trip lifecycle, recovery, and monotonicity tests
test/domain/trip/scenarios/idle_pending_test.dart — Scenario tests 1–8 for idle and pending TripStateMachine transitions
test/domain/trip/scenarios/property_test.dart — Tests 18, 19, 21 (edge cases) and 22, 27 (property tests)
test/domain/trip/segment_type_test.dart — Unit test for SegmentType enum values
test/domain/trip/trip_status_test.dart — Unit test for TripStatus enum values
probes/ios_autostart/lib/main.dart — T-012 diagnostic UI backed by the native probe method channel
probes/ios_autostart/ios/Runner/AppDelegate.swift — App-level native probe launch, lifecycle, and URL handling
probes/ios_autostart/ios/Runner/SceneDelegate.swift — Scene URL delivery and Flutter diagnostic channel adapter
probes/ios_autostart/ios/Runner/Probe/ProbeLog.swift — Durable, append-only JSONL probe log singleton
probes/ios_autostart/ios/Runner/Probe/RideRecorder.swift — App-level Core Location recorder singleton
probes/ios_autostart/ios/Runner/Probe/StartGate.swift — Correlated accepted-fix start gate singleton
probes/ios_autostart/ios/Runner/Probe/NotificationPermission.swift — Local-notification permission and scheduling singleton
probes/ios_autostart/ios/Runner/Probe/StartRideIntents.swift — Foreground/background App Intents and App Shortcuts provider
probes/ios_autostart/tool/analyze_log.dart — Dependency-free JSONL probe evidence analyzer
probes/ios_autostart/test/widget_test.dart — Method-channel-backed diagnostic UI widget test
probes/ios_autostart/test/analyze_log_test.dart — Fixture-driven JSONL analyzer test
probes/ios_autostart/test/fixtures/probe_log.jsonl — Mixed valid/malformed probe evidence fixture
probes/ios_autostart/test/fixtures/latencies.jsonl — Tap and intent latency probe evidence fixture
probes/ios_autostart/test/fixtures/clock_regression.jsonl — Wall-clock regression probe evidence fixture
probes/ios_autostart/test/fixtures/fix_timestamp_gaps.jsonl — Fix timestamp gap probe evidence fixture
probes/ios_autostart/test/fixtures/multi_ride_gaps.jsonl — Per-ride timestamp gap probe evidence fixture
probes/ios_autostart/test/fixtures/received_timestamp_gaps.jsonl — Received timestamp gap probe evidence fixture
probes/ios_autostart/test/fixtures/accepted_ratio.jsonl — Accepted/rejected fix ratio probe evidence fixture
probes/ios_autostart/test/fixtures/invalid_success_notification.jsonl — Invalid success-notification probe evidence fixture
probes/ios_autostart/test/fixtures/recovery_attempts.jsonl — Recovery-attempt probe evidence fixture
probes/ios_autostart/test/fixtures/malformed_lines.jsonl — Malformed JSONL probe evidence fixture
probes/ios_autostart/test/fixtures/missing_required_fields.jsonl — Missing sequence or uptime probe evidence fixture
probes/ios_autostart/test/fixtures/empty.jsonl — Empty probe evidence fixture
pigeons/recorder.dart — Pigeon source contract for the live native recorder bridge
ios/Runner/Generated/Recorder.g.swift — Generated Swift Pigeon bindings for recorder and route map contracts
ios/Runner/Recorder/RideRecorder.swift — Core Location live raw-fix recorder and Pigeon host implementation
lib/bridge/generated/recorder.g.dart — Generated Dart Pigeon bindings for recorder and route map contracts
lib/bridge/recorder_api.dart — Testable Dart interface and Pigeon client for recorder commands
lib/bridge/recorder_events.dart — Typed bridge events and raw-fix to GpsSample mapping
lib/bridge/recorder_bridge.dart — Recorder command facade and native callback stream adapter
test/bridge/recorder_bridge_test.dart — Unit tests for recorder command and callback bridge mappings
lib/data/database/tables.dart — Drift schema v3 including bounded diagnostic entries and projection snapshot
lib/data/database/app_database.dart — Drift v1-to-v3 migrations, diagnostics indexes, and append-only event guards
lib/data/database/app_database.g.dart — Generated Drift v3 table models and typed database bindings
lib/data/diagnostics/diagnostic_entry.dart — Diagnostics retention/size config and entry models
lib/data/diagnostics/diagnostic_repository.dart — Validated diagnostic insertion, age/count pruning, and ordered reads
lib/data/diagnostics/diagnostic_bundle_exporter.dart — Manual size-checked JSON bundle generation for Documents
lib/data/events/event_record.dart — Typed input and stored event value models
lib/data/events/event_repository.dart — Validated append, ordered unprocessed reads, and selective processing
lib/data/projection/projection_snapshot.dart — Versioned explicit-JSON restart snapshot codec for filter and trip state
lib/data/projection/projection_state_repository.dart — Singleton projection snapshot persistence
lib/data/projection/projection_id_generator.dart — Injectable trip and segment ID generator
lib/data/projection/event_projection_processor.dart — Atomic insertion-order raw-event projection into trips, segments, and GPS points
test/data/database/app_database_test.dart — Windows v3 schema, migration preservation, index, enum, and reopen tests
test/data/diagnostics/diagnostic_repository_test.dart — Diagnostic JSON integrity, retention, and pruning isolation tests
test/data/diagnostics/diagnostic_bundle_exporter_test.dart — Exact raw payload, ordered bundle, state, and oversize tests
test/data/events/event_repository_test.dart — Windows event integrity, processing, reopen, and recent-read tests
test/data/projection/projection_snapshot_test.dart — Explicit projection snapshot JSON round-trip and version-rejection tests
test/data/projection/event_projection_processor_test.dart — Migration-safe atomic event projection, order, restart, and GPS evidence tests
lib/app/recorder_runtime.dart — Observable recorder activity, callback count, and latest persistence/native errors
lib/app/raw_event_writer.dart — Shared serial raw-event append writer with central write-failure diagnostics
lib/app/diagnostics_coordinator.dart — Unawaited best-effort failure reporting across recorder and projection flows
lib/app/projection_drain_coordinator.dart — Single-flight automatic/startup projection drain, blockage and explicit retry
lib/app/recorder_event_ingestion.dart — Serial raw RecorderBridge callback persistence and runtime updates
lib/app/recorder_session.dart — Manual intent persistence and native recorder start/stop coordination
lib/debug/recorder_debug_screen.dart — Manual controls, runtime errors, and recent-event debug console
test/app/recorder_test_fakes.dart — Shared native API and event write fakes for application tests
test/app/raw_event_writer_test.dart — Serial raw append ordering, failure continuation, and central diagnostic isolation tests
test/app/diagnostics_coordinator_test.dart — Narrow best-effort reporting, swallowed persistence failures, and nonrecursion tests
test/app/projection_drain_coordinator_test.dart — Automatic, startup, single-flight, failure/retry and restart projection tests
test/app/recorder_event_ingestion_test.dart — Raw callback mapping, timestamp, ordering, and failure tests
test/app/recorder_session_test.dart — Manual start/stop intent and native error tests
lib/data/trips/projected_trip_repository.dart — Transactional projected active, terminal, segment and GPS evidence queries in stable order
lib/presentation/ride_route.dart — Testable accepted route pieces, on-demand distance and conservative reliability derivation
lib/ui/ride_map_view.dart — Flutter iOS MapKit PlatformView and typed Pigeon route payload adapter
lib/ui/ride_display.dart — Ride display configuration, distance and timing labels
lib/ui/rides_screen.dart — Manual recording home with projected route and navigation
lib/ui/ride_history_screen.dart — Terminal projected ride history with derived distance and status
lib/ui/ride_detail_screen.dart — Selected ride map, segments, gap and reliability details
ios/Runner/AppDelegate.swift — Registers recorder and native MapKit route view with blue separate polylines
test/helpers/ride_fixture.dart — Shared projected-trip SQLite fixtures for data, presentation and widget tests
test/data/trips/projected_trip_repository_test.dart — Terminal filtering, insertion ordering and snapshot-selected active ride tests
test/presentation/ride_route_test.dart — Accepted/rejected, gap/reset and measured/partial/unknown derivation tests
test/bridge/route_map_test.dart — Pigeon route-piece payload and Dart channel boundary tests

