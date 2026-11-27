import 'dart:async';
import 'dart:convert';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late InMemoryKeyValueStore kv;
  setUp(() => kv = InMemoryKeyValueStore());

  SuiteFeed make(FakeSuiteTransport t, {DateTime Function()? clock}) => SuiteFeed(
        sourceApp: 'table_encore',
        scheme: 'tableencore',
        transport: t,
        store: kv,
        clock: clock,
      );

  FakeSuiteTransport kr() => FakeSuiteTransport(installedPackage: 'com.codecowboys.kickrocks.dev');

  String env(Map<String, Object?> over) {
    final m = <String, Object?>{
      'format': 'cc-suite-moment',
      'version': 1,
      'sourceApp': 'table_encore',
      'entityId': 'visit-1~abc123',
      'time': '2026-11-24T17:30:00Z',
      'title': 'Diner',
      ...over,
    }..removeWhere((k, v) => v == #drop);
    return jsonEncode(m);
  }

  group('envelope', () {
    test('what goes out: namespaced id, back-link with the time, pin', () async {
      final t = kr();
      final f = make(t);
      final at = DateTime.utc(2026, 11, 24, 12, 30);
      await f.feed(f.moment(
          entityId: 'visit-7', time: at, title: ' Zingerman’s ', summary: 'Reuben', lat: 42.28, lng: -83.74));
      final m = SuiteMoment.decode(t.delivered.single);
      final inst = await f.installId();
      expect(m.entityId, 'visit-7~$inst');
      expect(m.title, 'Zingerman’s');
      expect(m.summary, 'Reuben');
      expect((m.lat, m.lng), (42.28, -83.74));
      expect(m.time, at);
      expect(m.deepLink.toString(), 'tableencore://open/visit-7~$inst?at=${at.millisecondsSinceEpoch}');
    });

    test('install id is made once and kept', () async {
      final a = await make(kr()).installId();
      expect(a, matches(RegExp(r'^[a-z0-9]{6}$')));
      expect(await make(kr()).installId(), a);
    });

    test('dateOnly sends the day, not a made-up clock time', () async {
      final t = kr();
      final f = make(t);
      await f.feed(f.moment(entityId: 'round-3', time: DateTime(2026, 11, 20, 15), title: 'Pines', dateOnly: true));
      final raw = jsonDecode(t.delivered.single) as Map;
      expect(raw['time'], '2026-11-20');
      expect(raw['dateOnly'], true);
      final m = SuiteMoment.decode(t.delivered.single);
      expect(m.dateOnly, isTrue);
      expect(m.time, DateTime(2026, 11, 20));
    });

    test('half a pin, a 0,0 pin or an impossible pin is no pin', () {
      final f = make(kr());
      for (final (la, lo) in [(1.0, null), (0.0, 0.0), (91.0, 10.0), (double.nan, 1.0)]) {
        final m = f.moment(entityId: 'x', time: DateTime.now(), title: 't', lat: la, lng: lo);
        expect((m.lat, m.lng), (null, null), reason: '$la,$lo');
      }
    });

    test('long titles and summaries are clipped without splitting emoji', () {
      final f = make(kr());
      final m = f.moment(entityId: 'x', time: DateTime.now(), title: '🍔' * 300, summary: '☕' * 900);
      expect(m.title.runes.length, SuiteMoment.maxTitle);
      expect(m.title.endsWith('…'), isTrue);
      expect(m.summary!.runes.length, SuiteMoment.maxSummary);
      expect(m.title.runes.where((r) => r >= 0xD800 && r <= 0xDFFF), isEmpty);
    });

    test('an id that is not URL-safe is not sent', () async {
      final t = kr();
      final f = make(t);
      expect(await f.feed(f.moment(entityId: 'a/b?c', time: DateTime.now(), title: 't')), isFalse);
      expect(await f.feed(f.moment(entityId: 'has~tilde', time: DateTime.now(), title: 't')), isFalse);
      expect(t.deliverAttempts, isEmpty);
    });
  });

  group('decode refuses hostile input with FormatException only', () {
    final bad = <String, String>{
      'not json': 'not json',
      'array': '[1,2]',
      'other format': env({'format': 'nope'}),
      'version as string': env({'version': '1'}),
      'version 0': env({'version': 0}),
      'time as number': env({'time': 1723000000}),
      'time garbage': env({'time': 'yesterday'}),
      'time year 9999': env({'time': '9999-01-01T00:00:00Z'}),
      'dateOnly bad day': env({'dateOnly': true, 'time': '2026-02-31'}),
      'dateOnly full timestamp': env({'dateOnly': true, 'time': '2026-11-24T10:00:00Z'}),
      'lat 999': env({'lat': 999, 'lng': 1}),
      'lat infinity':
          '{"format":"cc-suite-moment","version":1,"sourceApp":"table_encore","entityId":"v-1","time":"2026-11-24T17:30:00Z","title":"x","lat":1e999,"lng":1}',
      'lat without lng': env({'lat': 10}),
      'lat as string': env({'lat': '10', 'lng': '10'}),
      'sourceApp with space': env({'sourceApp': 'a b'}),
      'sourceApp uppercase': env({'sourceApp': 'TableEncore'}),
      'sourceApp missing': env({'sourceApp': #drop}),
      'entityId empty': env({'entityId': ''}),
      'entityId with slash': env({'entityId': '../x'}),
      'entityId number': env({'entityId': 12}),
      'title blank': env({'title': '  '}),
      'title number': env({'title': 5}),
      'summary number': env({'summary': 5}),
      'deepLink number': env({'deepLink': 5}),
      'too big': env({'summary': 'x' * 70000}),
    };
    for (final e in bad.entries) {
      test(e.key, () => expect(() => SuiteMoment.decode(e.value), throwsFormatException));
    }

    test('a newer version is told apart (kept for later, not dropped)', () {
      expect(() => SuiteMoment.decode(env({'version': 2})), throwsA(isA<NewerSuiteVersion>()));
    });

    test('unknown keys are ignored; oversized text is clipped', () {
      final m = SuiteMoment.decode(env({
        'future': {'x': 1},
        'title': 'T' * 400,
        'summary': 's' * 900,
      }));
      expect(m.title.runes.length, SuiteMoment.maxTitle);
      expect(m.summary!.runes.length, SuiteMoment.maxSummary);
    });
  });

  group('feed and send', () {
    test('feed delivers quietly when Kick Rocks is installed and auto is on', () async {
      final t = kr();
      final f = make(t);
      expect(await f.feed(f.moment(entityId: 'visit-1', time: DateTime.now(), title: 'Diner')), isTrue);
      expect(t.delivered, hasLength(1));
      expect(t.shared, isEmpty);
    });

    test('auto off: feed is not even attempted', () async {
      final t = kr();
      final f = make(t);
      await f.setAutoSend(false);
      expect(await f.feed(f.moment(entityId: 'visit-1', time: DateTime.now(), title: 'Diner')), isFalse);
      expect(t.deliverAttempts, isEmpty);
    });

    test('Kick Rocks missing: attempted, reported false, never throws', () async {
      final t = FakeSuiteTransport();
      final f = make(t);
      expect(await f.feed(f.moment(entityId: 'visit-1', time: DateTime.now(), title: 'Diner')), isFalse);
      expect(t.deliverAttempts, hasLength(1));
      expect(await f.kickRocksInstalled(), isFalse);
    });

    test('send opens Kick Rocks even with auto off; a double tap sends once', () async {
      final t = kr();
      var now = DateTime(2026, 11, 24, 12);
      final f = make(t, clock: () => now);
      await f.setAutoSend(false);
      final m = f.moment(entityId: 'v', time: now, title: 'x');
      expect(await f.send(m), isTrue);
      expect(await f.send(m), isTrue);
      expect(t.shared, hasLength(1));
      now = now.add(const Duration(seconds: 3));
      await f.send(m);
      expect(t.shared, hasLength(2));
    });
  });

  group('back-links', () {
    test('own-install links open; launch link first; others ignored', () async {
      final t = FakeSuiteTransport();
      final f = make(t);
      final inst = await f.installId();
      t.launchLink = 'tableencore://open/visit-3~$inst?at=1';
      final opened = <String>[];
      await f.listenForOpens(opened.add);
      t.openHandler!('tableencore://open/visit-9~$inst');
      t.openHandler!('tableencore://open/visit-10'); // legacy, no namespace
      t.openHandler!('freshpot://open/cup-1~$inst'); // not ours
      t.openHandler!('tableencore://elsewhere/visit-1');
      t.openHandler!('tableencore://open/a/b');
      t.openHandler!('tableencore://open/%2E%2E');
      await Future<void>.delayed(Duration.zero);
      expect(opened, ['visit-3', 'visit-9', 'visit-10']);
    });

    test('another install: opens only if the entry still matches the link time', () async {
      final t = FakeSuiteTransport();
      final f = make(t);
      final at = DateTime(2026, 11, 20, 12);
      final times = {'visit-1': at.add(const Duration(hours: 1)), 'visit-2': DateTime(2027, 1, 1)};
      final opened = <String>[], missing = <String>[];
      await f.listenForOpens(opened.add, timeOf: (id) async => times[id], missing: missing.add);
      final ms = at.millisecondsSinceEpoch;
      t.openHandler!('tableencore://open/visit-1~zzzzzz?at=$ms'); // restored backup: same entry
      t.openHandler!('tableencore://open/visit-2~zzzzzz?at=$ms'); // reinstall reused the id
      t.openHandler!('tableencore://open/visit-3~zzzzzz?at=$ms'); // gone
      t.openHandler!('tableencore://open/visit-1~zzzzzz'); // no time: can't tell
      await Future<void>.delayed(Duration.zero);
      expect(opened, ['visit-1']);
      expect(missing, ['visit-2', 'visit-3', 'visit-1']);
    });
  });

  group('drafts from Kick Rocks', () {
    String krEnv(Map<String, Object?> over) => env({
          'sourceApp': 'kick_rocks',
          'entityId': 'mom-9',
          'title': 'Best tacos of the trip',
          'summary': 'Lake Michigan loop',
          'lat': 45.85,
          'lng': -84.62,
          ...over,
        });

    test('launch draft and later drafts reach the handler', () async {
      final t = kr()..launchDraft = krEnv({});
      final got = <SuiteDraft>[];
      await make(t).listenForDrafts(got.add);
      expect(got.single.momentId, 'mom-9');
      expect(got.single.note, 'Best tacos of the trip');
      expect(got.single.tripName, 'Lake Michigan loop');
      expect(got.single.hasPin, isTrue);
      expect(got.single.time, DateTime.utc(2026, 11, 24, 17, 30).toLocal());
      t.draftHandler!(krEnv({'entityId': 'mom-10', 'title': SuiteDraft.untitled, 'lat': #drop, 'lng': #drop}));
      expect(got.last.momentId, 'mom-10');
      expect(got.last.note, isNull);
      expect(got.last.hasPin, isFalse);
    });

    test('only Kick Rocks envelopes, only well-formed ones', () async {
      final t = kr();
      final got = <SuiteDraft>[];
      await make(t).listenForDrafts(got.add);
      t.draftHandler!(env({})); // a sibling's envelope, not Kick Rocks
      t.draftHandler!('not json');
      t.draftHandler!(krEnv({'lat': 200}));
      t.draftHandler!(krEnv({'fromMoment': 'bad id!'}));
      expect(got, isEmpty);
    });

    test('a save inside fromDraft feeds with fromMoment; outside it does not', () async {
      final t = kr();
      final f = make(t);
      final d = SuiteDraft.tryParse(krEnv({}))!;
      final at = DateTime.utc(2026, 11, 24, 17, 30);
      final id = await f.fromDraft(d, () async {
        // Fire-and-forget, as the apps' repositories do.
        // Repositories feed unawaited, after reading the row back.
        await Future<void>.delayed(Duration.zero);
        unawaited(() async {
          await Future<void>.delayed(Duration.zero);
          await f.feed(f.moment(entityId: 'visit-3', time: at, title: 'Taqueria'));
        }());
        return 3;
      });
      expect(id, 3);
      await f.feed(f.moment(entityId: 'visit-4', time: at, title: 'Other'));
      await pumpEventQueue();
      final got = t.delivered.map(SuiteMoment.decode).toList();
      final first = got.singleWhere((m) => m.entityId.startsWith('visit-3~'));
      final second = got.singleWhere((m) => m.entityId.startsWith('visit-4~'));
      expect(first.fromMoment, 'mom-9');
      expect(second.fromMoment, isNull);
    });

    test('fromMoment survives a round trip and is optional', () {
      final m = SuiteMoment.decode(env({'fromMoment': 'mom-9'}));
      expect(m.fromMoment, 'mom-9');
      expect(SuiteMoment.decode(m.encode()).fromMoment, 'mom-9');
      expect(SuiteMoment.decode(env({})).fromMoment, isNull);
    });
  });
}
