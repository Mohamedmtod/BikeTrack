import 'package:biketrack/app/recorder_runtime.dart';
import 'package:biketrack/domain/trip/distance_status.dart';
import 'package:biketrack/presentation/ride_presentation.dart';
import 'package:biketrack/presentation/ride_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unknown distance is never formatted as zero', () {
    const unknown = RideRoute([], null, DistanceStatus.unknown);
    expect(RidePresentation.distance(unknown), 'Distance unavailable');
    expect(RidePresentation.reliability(unknown), 'Distance not yet available');
    expect(
      RidePresentation.locationStatus(unknown, recording: true),
      'Waiting for a GPS location…',
    );
  });

  test('measured and partial distances have distinct human-facing labels', () {
    const measured = RideRoute([], 111.2, DistanceStatus.measured);
    const partial = RideRoute([], 111.2, DistanceStatus.partial);
    expect(RidePresentation.distance(measured), '0.11 km');
    expect(RidePresentation.reliability(measured), 'Measured distance');
    expect(
      RidePresentation.reliability(partial),
      'Partial distance · some sections missing',
    );
    expect(RidePresentation.state('needsReview'), 'Needs review');
    expect(RidePresentation.state('completed'), 'Completed');
  });

  test('home state prefers actionable failure and safe finishing state', () {
    RideHomeState state(
      RecorderActivity activity, {
      bool active = false,
      bool stopping = false,
      bool blocked = false,
    }) => RidePresentation.homeState(
      activity: activity,
      hasOpenRide: active,
      stopping: stopping,
      blocked: blocked,
      error: false,
    );
    expect(state(RecorderActivity.idle), RideHomeState.ready);
    expect(state(RecorderActivity.starting), RideHomeState.ready);
    expect(state(RecorderActivity.recording), RideHomeState.recording);
    expect(state(RecorderActivity.idle, active: true), RideHomeState.attention);
    expect(
      state(RecorderActivity.idle, active: true, stopping: true),
      RideHomeState.stopping,
    );
    expect(
      state(RecorderActivity.recording, stopping: true),
      RideHomeState.stopping,
    );
    expect(
      state(RecorderActivity.recording, blocked: true),
      RideHomeState.attention,
    );
    expect(
      RidePresentation.homeTitle(RideHomeState.attention),
      'Ride needs attention',
    );
  });

  test('elapsed clamps negative time and formats hours', () {
    expect(RidePresentation.elapsed(2000, 1000), '00:00:00');
    expect(RidePresentation.elapsed(0, 3661000), '01:01:01');
    expect(RidePresentation.time(null), 'Not available');
  });
}
