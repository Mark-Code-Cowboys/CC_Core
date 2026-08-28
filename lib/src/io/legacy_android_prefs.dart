import 'dart:io';

/// Reader for Android's native SharedPreferences XML files, for one-time
/// migrations of apps rewritten onto Flutter: the Flutter
/// shared_preferences plugin reads only its own `FlutterSharedPreferences`
/// file, so a rewrite shipping as an update to a native (or KMP) app must
/// lift the old app's settings out of `shared_prefs/<name>.xml` itself.
///
/// The file lives in the app's own sandbox
/// (`<dataDir>/shared_prefs/<name>.xml`), so plain `dart:io` reads work —
/// no platform channel. Parses exactly the format the Android framework
/// writes (`SharedPreferencesImpl.writeToFile`): a `<map>` of
/// `<string>`, `<int>`, `<long>`, `<boolean>`, `<float>` entries.
/// String sets (`<set>`) are skipped. Absent keys stay absent — the
/// written/never-written distinction is load-bearing for defaults, so
/// the result only contains keys the old app actually stored.
class LegacyAndroidPrefs {
  LegacyAndroidPrefs._();

  /// Parses [xml] (the content of a shared_prefs file) into a map of
  /// key → String | int | bool | double. `<long>` values land as Dart
  /// ints (64-bit, lossless); apps that packed doubles into long bits
  /// convert those themselves.
  static Map<String, Object> parse(String xml) {
    final result = <String, Object>{};

    // <int name="k" value="1" />, <long>, <boolean>, <float>
    final valueEntry = RegExp(
        r'<(int|long|boolean|float)\s+name="([^"]*)"\s+value="([^"]*)"');
    for (final m in valueEntry.allMatches(xml)) {
      final key = _unescape(m.group(2)!);
      final raw = m.group(3)!;
      switch (m.group(1)!) {
        case 'int':
        case 'long':
          result[key] = int.parse(raw);
        case 'boolean':
          result[key] = raw == 'true';
        case 'float':
          result[key] = double.parse(raw);
      }
    }

    // <string name="k">value</string> — value may be empty or multiline.
    // A self-closing <string name="k" /> is an empty string.
    final stringEntry = RegExp(
        r'<string\s+name="([^"]*)"\s*(?:/>|>(.*?)</string>)',
        dotAll: true);
    for (final m in stringEntry.allMatches(xml)) {
      result[_unescape(m.group(1)!)] = _unescape(m.group(2) ?? '');
    }

    return result;
  }

  /// Reads and parses [file]; empty map when the file doesn't exist
  /// (fresh install, or the old app never wrote these prefs).
  static Future<Map<String, Object>> readFile(File file) async {
    if (!file.existsSync()) return const {};
    return parse(await file.readAsString());
  }

  /// The conventional location of a native SharedPreferences file on
  /// Android: `<dataDir>/shared_prefs/<name>.xml`. [dataDir] is the
  /// app's data directory (the parent of `files/`, which path_provider
  /// exposes as the application support directory).
  static File fileIn(Directory dataDir, String prefsName) =>
      File('${dataDir.path}/shared_prefs/$prefsName.xml');

  static String _unescape(String s) {
    if (!s.contains('&')) return s;
    return s
        .replaceAllMapped(
            RegExp(r'&#(\d+);'), (m) => String.fromCharCode(int.parse(m[1]!)))
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&amp;', '&');
  }
}
