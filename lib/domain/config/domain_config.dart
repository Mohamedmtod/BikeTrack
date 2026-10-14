import '../activity/activity_classifier_config.dart';
import '../activity/activity_state_config.dart';
import '../gps/gps_filter_config.dart';
import 'trip_config.dart';

/// Aggregates all domain configurations into a single source of truth (§6.4, D-014, D-025).
class DomainConfig {
  final GpsFilterConfig gps;
  final ActivityClassifierConfig classifier;
  final ActivityStateConfig activityState;
  final TripConfig trip;

  ActivityClassifierConfig get activityClassifier => classifier;

  DomainConfig({
    this.gps = const GpsFilterConfig(),
    this.classifier = const ActivityClassifierConfig(),
    this.activityState = const ActivityStateConfig(),
    this.trip = const TripConfig(),
  }) : assert(trip.gapMs == gps.gapMs, 'trip.gapMs must equal gps.gapMs');
}
