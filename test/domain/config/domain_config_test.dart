import 'package:biketrack/domain/config/domain_config.dart';
import 'package:biketrack/domain/config/trip_config.dart';
import 'package:biketrack/domain/gps/gps_filter_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TripConfig', () {
    test('13 default TripConfig values equal D-025 exactly', () {
      const cfg = TripConfig();
      expect(cfg.pendingMs, 300000); // 5 min
      expect(cfg.pauseMs, 180000); // 3 min
      expect(cfg.forgotMs, 900000); // 15 min
      expect(cfg.autoCloseMs, 2700000); // 45 min
      expect(cfg.modeChangeMs, 60000); // 60 s
      expect(cfg.gapMs, 30000); // 30 s
      expect(cfg.pauseRegionRadiusM, 100.0);
      expect(cfg.cadenceWalkingMinSps, 1.2);
    });
  });

  group('DomainConfig', () {
    test(
      '14 DomainConfig with trip.gapMs != gps.gapMs throws AssertionError',
      () {
        expect(
          () => DomainConfig(
            gps: const GpsFilterConfig(gapMs: 30000),
            trip: const TripConfig(gapMs: 20000),
          ),
          throwsA(isA<AssertionError>()),
        );
        expect(() => DomainConfig(), returnsNormally);
      },
    );
  });
}
