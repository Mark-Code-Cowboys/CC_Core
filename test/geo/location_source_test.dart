import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fix = GeoFix(
    lat: 30,
    lng: -97,
    accuracyM: 8,
    timestamp: DateTime(2026),
  );

  group('FakeLocationSource', () {
    test('plays its script in order and repeats the last result', () async {
      final source = FakeLocationSource([
        const LocationTimeout(),
        LocationFixResult(fix),
      ]);
      const maxAge = Duration(minutes: 2);

      expect(await source.currentFix(maxAge: maxAge), isA<LocationTimeout>());
      final second = await source.currentFix(maxAge: maxAge);
      expect((second as LocationFixResult).fix, same(fix));
      expect(await source.currentFix(maxAge: maxAge), isA<LocationFixResult>());
      expect(source.callCount, 3);
      expect(source.requestedMaxAges, everyElement(maxAge));
    });

    test('constant answers the same every time', () async {
      final source = FakeLocationSource.constant(
        const LocationPermissionDenied(),
      );
      expect(
        await source.currentFix(maxAge: Duration.zero),
        isA<LocationPermissionDenied>(),
      );
      expect(
        await source.currentFix(maxAge: Duration.zero),
        isA<LocationPermissionDenied>(),
      );
    });

    test('LocationResult is exhaustive for a switch', () {
      String describe(LocationResult r) => switch (r) {
        LocationFixResult() => 'fix',
        LocationPermissionDenied() => 'denied',
        LocationTimeout() => 'timeout',
        LocationUnavailable() => 'unavailable',
      };
      expect(describe(LocationFixResult(fix)), 'fix');
      expect(describe(const LocationPermissionDenied()), 'denied');
      expect(describe(const LocationTimeout()), 'timeout');
      expect(describe(const LocationUnavailable()), 'unavailable');
    });
  });
}
