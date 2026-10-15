# CODEMAP — BikeTrack

lib/main.dart — Flutter application entry point and counter sample widget
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
test/helpers/gps_helpers.dart — Shared helper functions and test fixture constants
test/widget_test.dart — Smoke test for default counter widget
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
test/fixtures/latencies.jsonl — Tap and intent latency probe evidence fixture
test/fixtures/fix_timestamp_gaps.jsonl — Fix timestamp gap probe evidence fixture
test/fixtures/received_timestamp_gaps.jsonl — Received timestamp gap probe evidence fixture
test/fixtures/accepted_ratio.jsonl — Accepted/rejected fix ratio probe evidence fixture
test/fixtures/invalid_success_notification.jsonl — Invalid success-notification probe evidence fixture
test/fixtures/recovery_attempts.jsonl — Recovery-attempt probe evidence fixture
test/fixtures/malformed_lines.jsonl — Malformed JSONL probe evidence fixture
test/fixtures/empty.jsonl — Empty probe evidence fixture

