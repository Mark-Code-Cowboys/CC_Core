import 'dart:io';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegacyAndroidPrefs.parse', () {
    test('parses every scalar type the framework writes', () {
      const xml = '''
<?xml version='1.0' encoding='utf-8' standalone='yes' ?>
<map>
    <string name="tracked_element">Nickel</string>
    <int name="history_days_limit" value="180" />
    <long name="daily_limit" value="4639481672377565184" />
    <boolean name="onboarded" value="true" />
    <float name="scale" value="1.5" />
    <int name="legacy_pro_features_unlocked" value="1" />
</map>
''';

      final prefs = LegacyAndroidPrefs.parse(xml);

      expect(prefs, {
        'tracked_element': 'Nickel',
        'history_days_limit': 180,
        'daily_limit': 4639481672377565184,
        'onboarded': true,
        'scale': 1.5,
        'legacy_pro_features_unlocked': 1,
      });
    });

    test('absent keys stay absent — no defaults invented', () {
      final prefs = LegacyAndroidPrefs.parse('<map>\n</map>');
      expect(prefs, isEmpty);
    });

    test('unescapes XML entities in strings and handles empty strings', () {
      const xml = '''
<map>
    <string name="note">salt &amp; pepper &lt;3 &#8220;quoted&#8221;</string>
    <string name="empty" />
    <string name="blank"></string>
</map>
''';

      final prefs = LegacyAndroidPrefs.parse(xml);

      expect(prefs['note'], 'salt & pepper <3 “quoted”');
      expect(prefs['empty'], '');
      expect(prefs['blank'], '');
    });

    test('negative and 64-bit long values survive', () {
      const xml =
          '<map><long name="sentinel" value="-1" />'
          '<long name="big" value="9223372036854775807" /></map>';

      final prefs = LegacyAndroidPrefs.parse(xml);

      expect(prefs['sentinel'], -1);
      expect(prefs['big'], 9223372036854775807);
    });
  });

  group('LegacyAndroidPrefs.readFile', () {
    test('a missing file reads as an empty map', () async {
      final prefs = await LegacyAndroidPrefs.readFile(
        File('/nonexistent/shared_prefs/nope.xml'),
      );
      expect(prefs, isEmpty);
    });

    test('fileIn builds the conventional shared_prefs path', () {
      final f = LegacyAndroidPrefs.fileIn(
        Directory('/data/user/0/com.app'),
        'ts',
      );
      expect(f.path, '/data/user/0/com.app/shared_prefs/ts.xml');
    });
  });

  group('KeyValueStore string/double/contains', () {
    test('InMemoryKeyValueStore round-trips the new slots', () async {
      final kv = InMemoryKeyValueStore();

      expect(await kv.contains('k'), isFalse);
      await kv.setString('k', 'Nickel');
      await kv.setDouble('d', 150.0);

      expect(await kv.getString('k'), 'Nickel');
      expect(await kv.getDouble('d'), 150.0);
      expect(await kv.contains('k'), isTrue);
      expect(await kv.getString('missing'), isNull);
      expect(await kv.getDouble('missing'), isNull);
    });
  });
}
