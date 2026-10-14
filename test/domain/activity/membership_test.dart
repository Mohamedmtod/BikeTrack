import 'package:biketrack/domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cfg = ActivityClassifierConfig();

  group('Trapezoid membership function', () {
    test('walk(0.65) = 0.5', () {
      final res = trapezoid(
        0.65,
        cfg.walkSpeedA,
        cfg.walkSpeedB,
        cfg.walkSpeedC,
        cfg.walkSpeedD,
      );
      expect(res, closeTo(0.5, 1e-9));
    });

    test('walk(1.5) = 1.0', () {
      final res = trapezoid(
        1.5,
        cfg.walkSpeedA,
        cfg.walkSpeedB,
        cfg.walkSpeedC,
        cfg.walkSpeedD,
      );
      expect(res, closeTo(1.0, 1e-9));
    });

    test('walk(0.3) = 0.0', () {
      final res = trapezoid(
        0.3,
        cfg.walkSpeedA,
        cfg.walkSpeedB,
        cfg.walkSpeedC,
        cfg.walkSpeedD,
      );
      expect(res, closeTo(0.0, 1e-9));
    });

    test('walk(3.0) = 0.0', () {
      final res = trapezoid(
        3.0,
        cfg.walkSpeedA,
        cfg.walkSpeedB,
        cfg.walkSpeedC,
        cfg.walkSpeedD,
      );
      expect(res, closeTo(0.0, 1e-9));
    });

    test('cyc(10.5) = 0.5', () {
      final res = trapezoid(
        10.5,
        cfg.cycleSpeedA,
        cfg.cycleSpeedB,
        cfg.cycleSpeedC,
        cfg.cycleSpeedD,
      );
      expect(res, closeTo(0.5, 1e-9));
    });

    test('cyc(5) = 1.0', () {
      final res = trapezoid(
        5.0,
        cfg.cycleSpeedA,
        cfg.cycleSpeedB,
        cfg.cycleSpeedC,
        cfg.cycleSpeedD,
      );
      expect(res, closeTo(1.0, 1e-9));
    });

    test('auto(7) = 0.5', () {
      final res = trapezoid(
        7.0,
        cfg.autoSpeedA,
        cfg.autoSpeedB,
        cfg.autoSpeedC,
        cfg.autoSpeedD,
      );
      expect(res, closeTo(0.5, 1e-9));
    });

    test('auto(50) = 1.0', () {
      final res = trapezoid(
        50.0,
        cfg.autoSpeedA,
        cfg.autoSpeedB,
        cfg.autoSpeedC,
        cfg.autoSpeedD,
      );
      expect(res, closeTo(1.0, 1e-9));
    });

    test('auto(6) = 0.0', () {
      final res = trapezoid(
        6.0,
        cfg.autoSpeedA,
        cfg.autoSpeedB,
        cfg.autoSpeedC,
        cfg.autoSpeedD,
      );
      expect(res, closeTo(0.0, 1e-9));
    });
  });
}
