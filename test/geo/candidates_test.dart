import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A stand-in for an app model: core must work without knowing it.
class _Place {
  const _Place(this.name, {this.lat, this.lng});

  final String name;
  final double? lat;
  final double? lng;

  GeoPin? get pin => GeoPin.tryFrom(lat: lat, lng: lng);

  @override
  String toString() => name;
}

/// Meters north of [lat] as a latitude offset (≈ 1° per 111.2 km).
double _north(double meters) => meters / 111195.0;

const _origin = GeoPin(lat: 30.25, lng: -97.75);

List<GeoCandidate<_Place>> _find(
  List<_Place> places,
  double radiusM, {
  GeoPoint fix = _origin,
}) => findCandidates<_Place>(
  fix: fix,
  items: places,
  pinOf: (p) => p.pin,
  radiusM: radiusM,
);

void main() {
  group('findCandidates', () {
    test('empty when nothing is saved', () {
      expect(_find(const [], 75), isEmpty);
    });

    test('excludes pinless items even at distance zero', () {
      final found = _find([
        const _Place('Pinless'),
        _Place('Here', lat: _origin.lat, lng: _origin.lng),
      ], 75);
      expect(found.map((c) => c.item.name), ['Here']);
    });

    test(
      'radius is inclusive: exactly at the radius is in, just past is out',
      () {
        final edge = _Place(
          'Edge',
          lat: _origin.lat + _north(75),
          lng: _origin.lng,
        );
        final exact = distanceMeters(_origin, edge.pin!);

        expect(_find([edge], exact).map((c) => c.item.name), ['Edge']);
        expect(_find([edge], exact - 1e-9), isEmpty);
      },
    );

    test('sorts a cluster nearest first with distances', () {
      final places = [
        _Place('C 40m', lat: _origin.lat + _north(40), lng: _origin.lng),
        _Place('A 10m', lat: _origin.lat + _north(10), lng: _origin.lng),
        _Place('D 70m', lat: _origin.lat - _north(70), lng: _origin.lng),
        _Place('B 25m', lat: _origin.lat - _north(25), lng: _origin.lng),
        _Place('Out 90m', lat: _origin.lat + _north(90), lng: _origin.lng),
      ];
      final found = _find(places, 75);
      expect(found.map((c) => c.item.name), [
        'A 10m',
        'B 25m',
        'C 40m',
        'D 70m',
      ]);
      expect(found[0].distanceM, closeTo(10, 0.1));
      expect(found[3].distanceM, closeTo(70, 0.1));
    });

    test('same name at different pins are separate candidates', () {
      final places = [
        _Place('Chain Cafe', lat: _origin.lat + _north(30), lng: _origin.lng),
        _Place('Chain Cafe', lat: _origin.lat + _north(5000), lng: _origin.lng),
        _Place('Chain Cafe', lat: _origin.lat - _north(60), lng: _origin.lng),
      ];
      final found = _find(places, 75);
      expect(found, hasLength(2));
      expect(found.map((c) => c.distanceM.round()), [30, 60]);
      expect(identical(found[0].item, places[0]), isTrue);
      expect(identical(found[1].item, places[2]), isTrue);
    });

    test('equal distances keep input order', () {
      final places = [
        _Place('North', lat: _origin.lat + _north(20), lng: _origin.lng),
        _Place('South', lat: _origin.lat - _north(20), lng: _origin.lng),
      ];
      expect(_find(places, 75).map((c) => c.item.name), ['North', 'South']);
    });

    test('radius variety: 15 m, 75 m, 400 m', () {
      final places = [
        _Place('10m', lat: _origin.lat + _north(10), lng: _origin.lng),
        _Place('50m', lat: _origin.lat + _north(50), lng: _origin.lng),
        _Place('300m', lat: _origin.lat + _north(300), lng: _origin.lng),
        _Place('1km', lat: _origin.lat + _north(1000), lng: _origin.lng),
      ];
      expect(_find(places, 15).map((c) => c.item.name), ['10m']);
      expect(_find(places, 75).map((c) => c.item.name), ['10m', '50m']);
      expect(_find(places, 400).map((c) => c.item.name), [
        '10m',
        '50m',
        '300m',
      ]);
    });

    test('takes a fix as the origin', () {
      final fix = GeoFix(
        lat: _origin.lat,
        lng: _origin.lng,
        accuracyM: 5,
        timestamp: DateTime(2026),
      );
      final places = [
        _Place('Near', lat: _origin.lat + _north(10), lng: _origin.lng),
      ];
      expect(_find(places, 75, fix: fix), hasLength(1));
    });
  });
}
