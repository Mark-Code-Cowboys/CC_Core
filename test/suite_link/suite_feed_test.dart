import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  SuiteFeed make(FakeSuiteTransport t, [KeyValueStore? s]) => SuiteFeed(
        sourceApp: 'table_encore',
        scheme: 'tableencore',
        transport: t,
        store: s ?? InMemoryKeyValueStore(),
      );

  test('envelope round-trips with a back-link', () {
    final f = make(FakeSuiteTransport());
    final m = f.moment(
      entityId: 'visit-7',
      time: DateTime.utc(2026, 11, 24, 12, 30),
      title: ' Zingerman’s ',
      summary: 'Reuben',
      lat: 42.28,
      lng: -83.74,
    );
    final back = SuiteMoment.decode(m.encode());
    expect(back.title, 'Zingerman’s');
    expect(back.summary, 'Reuben');
    expect(back.lat, 42.28);
    expect(back.deepLink.toString(), 'tableencore://open/visit-7');
    expect(back.time, DateTime.utc(2026, 11, 24, 12, 30));
  });

  test('half a pin is no pin', () {
    final m = make(FakeSuiteTransport())
        .moment(entityId: 'x', time: DateTime.now(), title: 't', lat: 1);
    expect(m.lat, isNull);
    expect(m.lng, isNull);
  });

  test('decode refuses newer versions and other formats', () {
    expect(() => SuiteMoment.decode('{"format":"nope"}'), throwsFormatException);
    expect(
      () => SuiteMoment.decode(
          '{"format":"cc-suite-moment","version":2,"sourceApp":"a","entityId":"b","time":"2026-01-01T00:00:00Z","title":"t"}'),
      throwsFormatException,
    );
    expect(() => SuiteMoment.decode('not json'), throwsFormatException);
  });

  test('feed delivers quietly when Kick Rocks is installed and auto is on', () async {
    final t = FakeSuiteTransport(installedPackage: 'com.codecowboys.kickrocks.dev');
    final f = make(t);
    final m = f.moment(entityId: 'visit-1', time: DateTime.now(), title: 'Diner');
    expect(await f.feed(m), isTrue);
    expect(t.delivered, hasLength(1));
    expect(t.shared, isEmpty);
  });

  test('feed does nothing when auto is off or Kick Rocks is missing', () async {
    final t = FakeSuiteTransport(installedPackage: 'com.codecowboys.kickrocks');
    final f = make(t);
    await f.setAutoSend(false);
    final m = f.moment(entityId: 'visit-1', time: DateTime.now(), title: 'Diner');
    expect(await f.feed(m), isFalse);
    expect(t.delivered, isEmpty);

    final missing = make(FakeSuiteTransport());
    expect(await missing.feed(m), isFalse);
    expect(await missing.kickRocksInstalled(), isFalse);
  });

  test('send opens Kick Rocks even with auto off', () async {
    final t = FakeSuiteTransport(installedPackage: 'com.codecowboys.kickrocks');
    final f = make(t);
    await f.setAutoSend(false);
    expect(await f.send(f.moment(entityId: 'v', time: DateTime.now(), title: 'x')), isTrue);
    expect(t.shared, hasLength(1));
  });

  test('back-links reach the app as entity ids, launch link first', () async {
    final t = FakeSuiteTransport()..launchLink = 'tableencore://open/visit-3';
    final opened = <String>[];
    await make(t).listenForOpens(opened.add);
    t.openHandler!('tableencore://open/visit-9');
    t.openHandler!('freshpot://open/cup-1'); // not ours
    t.openHandler!('tableencore://elsewhere/visit-1');
    expect(opened, ['visit-3', 'visit-9']);
  });
}
