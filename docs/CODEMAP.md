# CODEMAP — BikeTrack

lib/main.dart — Flutter application entry point and counter sample widget
lib/domain/domain.dart — Barrel exporting the public domain interface
lib/domain/activity/activity_type.dart — Physical activity classification enum
lib/domain/activity/classification_source.dart — Source determining activity classification enum
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
lib/domain/trip/segment_type.dart — Trip segment activity type enum
lib/domain/trip/trip_status.dart — Lifecycle status enum of a recorded trip
test/helpers/gps_helpers.dart — Shared helper functions and test fixture constants
test/widget_test.dart — Smoke test for default counter widget
test/domain/activity/activity_type_test.dart — Unit test for ActivityType enum values
test/domain/activity/classification_source_test.dart — Unit test for ClassificationSource enum values
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
test/domain/trip/segment_type_test.dart — Unit test for SegmentType enum values
test/domain/trip/trip_status_test.dart — Unit test for TripStatus enum values
