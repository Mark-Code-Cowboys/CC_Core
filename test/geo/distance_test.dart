import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

GeoPin _p(double lat, double lng) => GeoPin(lat: lat, lng: lng);

/// Within 0.5% of [expected].
Matcher _near(double expected) => closeTo(expected, expected * 0.005 + 0.01);

void main() {
  group('distanceMeters', () {
    test('zero for identical points', () {
      expect(distanceMeters(_p(30.25, -97.75), _p(30.25, -97.75)), 0);
    });

    test('one degree of latitude at the equator is ~111.19 km', () {
      expect(distanceMeters(_p(0, 0), _p(1, 0)), _near(111195));
    });

    test('one degree of longitude at the equator is ~111.19 km', () {
      expect(distanceMeters(_p(0, 0), _p(0, 1)), _near(111195));
    });

    test('one degree of longitude at 60° north is ~55.6 km', () {
      expect(distanceMeters(_p(60, 0), _p(60, 1)), _near(55597));
    });

    test('Statue of Liberty to Eiffel Tower is ~5837 km', () {
      expect(
        distanceMeters(_p(40.6892, -74.0445), _p(48.8584, 2.2945)),
        _near(5837000),
      );
    });

    test('antipodes are half the circumference', () {
      expect(distanceMeters(_p(0, 0), _p(0, 180)), _near(20015087));
    });

    test('table-scale: 0.0001° of latitude is ~11.1 m', () {
      expect(
        distanceMeters(_p(30.25, -97.75), _p(30.2501, -97.75)),
        _near(11.12),
      );
    });

    test('is symmetric', () {
      final a = _p(30.2672, -97.7431);
      final b = _p(30.3005, -97.7000);
      expect(distanceMeters(a, b), distanceMeters(b, a));
    });

    test('accepts a fix and a pin', () {
      final fix = GeoFix(
        lat: 30.25,
        lng: -97.75,
        accuracyM: 5,
        timestamp: DateTime(2026),
      );
      expect(distanceMeters(fix, _p(30.25, -97.75)), 0);
    });
  });
}
