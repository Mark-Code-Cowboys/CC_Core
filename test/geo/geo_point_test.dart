import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final when = DateTime(2026, 9, 29, 18, 30);

  group('GeoPin', () {
    test('tryFrom returns null without both coordinates', () {
      expect(GeoPin.tryFrom(lat: null, lng: null), isNull);
      expect(GeoPin.tryFrom(lat: 30, lng: null), isNull);
      expect(GeoPin.tryFrom(lat: null, lng: -97), isNull);
      expect(
        GeoPin.tryFrom(lat: null, lng: null, accuracyM: 5, capturedAt: when),
        isNull,
      );
    });

    test('tryFrom keeps metadata only when both parts are present', () {
      final full = GeoPin.tryFrom(
        lat: 30,
        lng: -97,
        accuracyM: 5,
        capturedAt: when,
      )!;
      expect(full.hasMetadata, isTrue);
      expect(full.accuracyM, 5);
      expect(full.capturedAt, when);

      final bare = GeoPin.tryFrom(lat: 30, lng: -97)!;
      expect(bare.hasMetadata, isFalse);

      final half = GeoPin.tryFrom(lat: 30, lng: -97, accuracyM: 5)!;
      expect(half.hasMetadata, isFalse);
      expect(half.accuracyM, isNull);
      expect(half.capturedAt, isNull);
    });

    test('fromFix copies every field', () {
      final fix = GeoFix(lat: 30.1, lng: -97.1, accuracyM: 8, timestamp: when);
      final pin = GeoPin.fromFix(fix);
      expect(pin.lat, 30.1);
      expect(pin.lng, -97.1);
      expect(pin.accuracyM, 8);
      expect(pin.capturedAt, when);
    });

    test('constructor rejects half the metadata', () {
      expect(
        () => GeoPin(lat: 30, lng: -97, accuracyM: 5),
        throwsAssertionError,
      );
      expect(
        () => GeoPin(lat: 30, lng: -97, capturedAt: when),
        throwsAssertionError,
      );
    });
  });

  group('GeoFix.isStale', () {
    final fix = GeoFix(lat: 30, lng: -97, accuracyM: 10, timestamp: when);

    test('fresh within maxAge, stale beyond it', () {
      const maxAge = Duration(minutes: 2);
      expect(fix.isStale(maxAge: maxAge, now: when), isFalse);
      expect(
        fix.isStale(maxAge: maxAge, now: when.add(const Duration(minutes: 2))),
        isFalse,
      );
      expect(
        fix.isStale(
          maxAge: maxAge,
          now: when.add(const Duration(minutes: 2, seconds: 1)),
        ),
        isTrue,
      );
    });
  });
}
