import 'package:biketrack/domain/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Domain Enums (§5.1 & D-011)', () {
    test('ActivityType contains all expected values', () {
      expect(
        ActivityType.values.map((e) => e.name).toList(),
        equals([
          'stationary',
          'walking',
          'running',
          'cycling',
          'automotive',
          'unknown',
        ]),
      );
    });

    test('Confidence contains all expected values', () {
      expect(
        Confidence.values.map((e) => e.name).toList(),
        equals(['low', 'medium', 'high']),
      );
    });

    test('TripStatus contains all expected values', () {
      expect(
        TripStatus.values.map((e) => e.name).toList(),
        equals([
          'pending',
          'active',
          'paused',
          'suspectedForgotten',
          'needsReview',
          'completed',
          'cancelled',
          'autoClosed',
        ]),
      );
    });

    test('SegmentType contains all expected values', () {
      expect(
        SegmentType.values.map((e) => e.name).toList(),
        equals(['cycling', 'walking', 'automotive', 'unknown', 'gap']),
      );
    });

    test('RecordingState contains all expected values', () {
      expect(
        RecordingState.values.map((e) => e.name).toList(),
        equals(['off', 'lowPower', 'highAccuracy']),
      );
    });

    test('EventSource contains all expected values', () {
      expect(
        EventSource.values.map((e) => e.name).toList(),
        equals([
          'motion',
          'pedometer',
          'gps',
          'nfc',
          'user',
          'system',
          'health',
        ]),
      );
    });

    test('ClassificationSource contains all expected values', () {
      expect(
        ClassificationSource.values.map((e) => e.name).toList(),
        equals(['coreMotion', 'fused', 'nfc', 'user']),
      );
    });

    test('DistanceStatus contains all expected values (D-011)', () {
      expect(
        DistanceStatus.values.map((e) => e.name).toList(),
        equals(['measured', 'partial', 'unknown']),
      );
    });
  });
}
