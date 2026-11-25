import 'package:cc_core/cc_core.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

import 'places_test_db.dart';

const _policy = PlacePolicy(
  matchRadiusM: 75,
  refineMaxAccuracyM: 50,
  maxFixAge: Duration(minutes: 2),
);

final _now = DateTime(2026, 11, 25, 9);

GeoFix _fix(double lat, double lng, {double accuracyM = 10}) =>
    GeoFix(lat: lat, lng: lng, accuracyM: accuracyM, timestamp: _now);

/// ~0.0001° of latitude is ~11 m.
const _baseLat = 45.0;
const _baseLng = -122.0;

void main() {
  group('PinnedPlaces / PlaceVisits as an app subclasses them', () {
    late PlacesTestDb db;
    setUp(() => db = PlacesTestDb());
    tearDown(() => db.close());

    Future<int> venue({
      double? lat,
      double? lng,
      double? accuracyM,
      DateTime? capturedAt,
    }) => db
        .into(db.testVenues)
        .insert(
          TestVenuesCompanion.insert(
            name: 'Heart',
            kind: TestVenueKind.cafe,
            lat: Value(lat),
            lng: Value(lng),
            pinAccuracyM: Value(accuracyM),
            pinCapturedAt: Value(capturedAt),
          ),
        );

    test('a whole pin, or none, is stored', () async {
      await venue();
      await venue(lat: _baseLat, lng: _baseLng);
      await venue(
        lat: _baseLat,
        lng: _baseLng,
        accuracyM: 8,
        capturedAt: _now,
      );
      expect(await db.select(db.testVenues).get(), hasLength(3));
    });

    test('the inherited CHECKs refuse half a pin', () async {
      await expectLater(venue(lat: _baseLat), throwsA(anything));
      await expectLater(
        venue(lat: _baseLat, lng: _baseLng, accuracyM: 8),
        throwsA(anything),
      );
      await expectLater(
        venue(accuracyM: 8, capturedAt: _now),
        throwsA(anything),
      );
      expect(await db.select(db.testVenues).get(), isEmpty);
    });

    test("the app's own FK cascades visits with their place", () async {
      final id = await venue();
      await db
          .into(db.testVisits)
          .insert(TestVisitsCompanion.insert(placeId: id, visitedAt: _now));
      await expectLater(
        db
            .into(db.testVisits)
            .insert(TestVisitsCompanion.insert(placeId: 999, visitedAt: _now)),
        throwsA(anything),
      );
      await (db.delete(db.testVenues)..where((v) => v.id.equals(id))).go();
      expect(await db.select(db.testVisits).get(), isEmpty);
    });
  });

  group('checkPinFields', () {
    test('accepts whole pins and no pin', () {
      checkPinFields(lat: null, lng: null);
      checkPinFields(lat: 1, lng: 2);
      checkPinFields(lat: 1, lng: 2, accuracyM: 5, capturedAt: _now);
    });

    test('refuses halves with a readable error', () {
      expect(() => checkPinFields(lat: 1, lng: null), throwsArgumentError);
      expect(
        () => checkPinFields(lat: 1, lng: 2, accuracyM: 5),
        throwsArgumentError,
      );
      expect(
        () => checkPinFields(
          lat: null,
          lng: null,
          accuracyM: 5,
          capturedAt: _now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('matchPlacesHere', () {
    final places = <(String, GeoPin?)>[
      ('near', const GeoPin(lat: _baseLat + 0.0003, lng: _baseLng)), // ~33 m
      ('edge', const GeoPin(lat: _baseLat + 0.0006, lng: _baseLng)), // ~67 m
      ('far', const GeoPin(lat: _baseLat + 0.002, lng: _baseLng)), // ~222 m
      ('pinless', null),
    ];

    test('a fix finds the places in range, nearest first', () async {
      var loaded = 0;
      final result = await matchPlacesHere<(String, GeoPin?)>(
        source: FakeLocationSource.constant(LocationFixResult(_fix(_baseLat, _baseLng))),
        policy: _policy,
        places: () async {
          loaded++;
          return places;
        },
        pinOf: (p) => p.$2,
      );
      final found = result as PlaceMatchFound<(String, GeoPin?)>;
      expect(found.candidates.map((c) => c.item.$1), ['near', 'edge']);
      expect(found.fix.lat, _baseLat);
      expect(loaded, 1);
    });

    test('somewhere new: a fix and no candidates', () async {
      final result = await matchPlacesHere<(String, GeoPin?)>(
        source: FakeLocationSource.constant(LocationFixResult(_fix(10, 10))),
        policy: _policy,
        places: () async => places,
        pinOf: (p) => p.$2,
      );
      expect((result as PlaceMatchFound).candidates, isEmpty);
    });

    test('no fix: the reason, and places are never loaded', () async {
      for (final reason in const [
        LocationPermissionDenied(),
        LocationTimeout(),
        LocationUnavailable(),
      ]) {
        var loaded = false;
        final result = await matchPlacesHere<(String, GeoPin?)>(
          source: FakeLocationSource.constant(reason),
          policy: _policy,
          places: () async {
            loaded = true;
            return places;
          },
          pinOf: (p) => p.$2,
        );
        expect((result as PlaceMatchNoFix).reason, reason);
        expect(loaded, isFalse);
      }
    });

    test('asks for a fix no older than the policy allows', () async {
      final source = FakeLocationSource.constant(LocationFixResult(_fix(_baseLat, _baseLng)));
      await matchPlacesHere<(String, GeoPin?)>(
        source: source,
        policy: _policy,
        places: () async => places,
        pinOf: (p) => p.$2,
      );
      expect(source.requestedMaxAges, [const Duration(minutes: 2)]);
    });
  });

  group('pinUpdateFor', () {
    test('a pinless place takes the fix', () {
      final pin = pinUpdateFor(
        stored: null,
        fix: _fix(1, 2, accuracyM: 200),
        policy: _policy,
      );
      expect(pin?.lat, 1);
      expect(pin?.accuracyM, 200);
    });

    test('a pin moves only for a better fix within the threshold', () {
      final stored = GeoPin(lat: 1, lng: 2, accuracyM: 30, capturedAt: _now);
      expect(
        pinUpdateFor(stored: stored, fix: _fix(1, 2.1), policy: _policy),
        isNotNull,
      );
      expect(
        pinUpdateFor(
          stored: stored,
          fix: _fix(1, 2.1, accuracyM: 40),
          policy: _policy,
        ),
        isNull,
      );
    });

    test('no fix, no change', () {
      expect(
        pinUpdateFor(stored: null, fix: null, policy: _policy),
        isNull,
      );
    });
  });

  group('recallAtPlace', () {
    VisitWithItems<String> visit(int day, List<String> items) =>
        VisitWithItems(visitedAt: DateTime(2026, 11, day), items: items);

    test('last time is the latest visit that recorded something', () {
      final recall = recallAtPlace(
        [
          visit(1, ['Cortado']),
          visit(9, []),
          visit(5, ['Flat white', 'Croissant']),
        ],
        keyOf: (s) => s.toLowerCase(),
      );
      expect(recall.lastVisitAt, DateTime(2026, 11, 5));
      expect(recall.lastItems, ['Flat white', 'Croissant']);
      expect(recall.visitCount, 3);
    });

    test('the usual: had on more than one visit, most visits first', () {
      final recall = recallAtPlace(
        [
          visit(1, ['cortado', 'Pour over']),
          visit(2, ['Cortado', 'Cortado']), // twice in one visit counts once
          visit(3, ['Pour Over ', 'Cortado']),
          visit(4, ['Matcha']),
        ],
        keyOf: (s) => s.trim().toLowerCase(),
      );
      // The latest spelling represents each.
      expect(recall.usual, ['Cortado', 'Pour Over ']);
    });

    test('nothing recorded: empty', () {
      final recall = recallAtPlace([visit(1, [])], keyOf: (s) => s);
      expect(recall.isEmpty, isTrue);
      expect(recall.lastVisitAt, isNull);
      expect(recall.usual, isEmpty);
      expect(recall.visitCount, 1);
    });
  });
}
