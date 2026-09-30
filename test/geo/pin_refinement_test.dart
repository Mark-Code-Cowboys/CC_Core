import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final when = DateTime(2026, 9, 29, 18, 30);
  GeoFix fix(double accuracyM) =>
      GeoFix(lat: 30, lng: -97, accuracyM: accuracyM, timestamp: when);
  GeoPin pin(double accuracyM) =>
      GeoPin(lat: 30, lng: -97, accuracyM: accuracyM, capturedAt: when);
  const threshold = 50.0;

  bool refine(GeoPin? stored, double newAccuracy) => shouldRefinePin(
    stored: stored,
    fix: fix(newAccuracy),
    maxAccuracyM: threshold,
  );

  group('shouldRefinePin', () {
    test('better and within threshold: refine', () {
      expect(refine(pin(40), 10), isTrue);
      expect(refine(pin(40), 39.9), isTrue);
    });

    test('better but past the threshold: keep', () {
      expect(refine(pin(200), 60), isFalse);
      expect(refine(pin(200), 50.1), isFalse);
    });

    test('exactly at the threshold counts as within it', () {
      expect(refine(pin(60), 50), isTrue);
    });

    test('worse or equal: keep', () {
      expect(refine(pin(10), 20), isFalse);
      expect(refine(pin(10), 10), isFalse);
    });

    test('no stored pin: backfill whatever the accuracy', () {
      expect(refine(null, 10), isTrue);
      expect(refine(null, 500), isTrue);
    });

    test('stored pin of unknown accuracy: refine when within threshold', () {
      const legacy = GeoPin(lat: 30, lng: -97);
      expect(refine(legacy, 30), isTrue);
      expect(refine(legacy, 50), isTrue);
      expect(refine(legacy, 51), isFalse);
    });
  });
}
