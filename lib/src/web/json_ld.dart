import 'dart:convert';

/// schema.org JSON-LD extraction from a page: the `<script
/// type="application/ld+json">` blocks, lenient decoding, and a
/// depth-limited search for objects of a given `@type` (top level,
/// `@graph`, `mainEntity`, lists). The mapping from an object to an
/// app's model stays app-side. Extracted from Trace Elements' recipe
/// import; Product, Restaurant and Menu pages carry the same shapes.

final _ldJsonScript = RegExp(
  r'<script\b[^>]*\btype\s*=\s*["'
  "'"
  r']?\s*application/ld\+json\s*["'
  "'"
  r']?[^>]*>(.*?)</script\s*>',
  caseSensitive: false,
  dotAll: true,
);

/// Every ld+json block's raw text, in page order; CDATA wrappers and
/// HTML comments inside the block removed.
List<String> extractJsonLdBlocks(String html) => [
  for (final m in _ldJsonScript.allMatches(html))
    m
        .group(1)!
        .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
        .replaceAll(RegExp(r'<!--.*?-->', dotAll: true), '')
        .trim(),
].where((s) => s.isNotEmpty).toList();

/// Decodes one block leniently: sites emit tabs and control characters
/// inside strings, which strict JSON rejects. Null when unreadable.
Object? decodeJsonLdBlock(String block) {
  try {
    return jsonDecode(block);
  } on FormatException {
    final cleaned = block
        .replaceAll('\t', ' ')
        .replaceAll(RegExp(r'[\x00-\x08\x0b\x0c\x0e-\x1f]'), '');
    try {
      return jsonDecode(cleaned);
    } on FormatException {
      return null;
    }
  }
}

bool _hasType(Object? type, String wanted) {
  final w = wanted.toLowerCase();
  bool one(Object? t) =>
      t is String && t.trim().toLowerCase().split(RegExp(r'[/:]')).last == w;
  if (type is List) return type.any(one);
  return one(type);
}

/// Every object whose `@type` is (or includes) [typeName] — matched by
/// its last path segment, so "Recipe", "schema:Recipe" and
/// "https://schema.org/Recipe" all count — anywhere in [json].
List<Map<String, dynamic>> findJsonLdObjects(
  Object? json,
  String typeName, {
  int depth = 0,
}) {
  if (depth > 6) return const [];
  final out = <Map<String, dynamic>>[];
  if (json is List) {
    for (final e in json) {
      out.addAll(findJsonLdObjects(e, typeName, depth: depth + 1));
    }
  } else if (json is Map) {
    final map = json.cast<String, dynamic>();
    if (_hasType(map['@type'], typeName)) {
      out.add(map);
    } else {
      for (final key in const [
        '@graph',
        'mainEntity',
        'mainEntityOfPage',
        'itemListElement',
        'hasPart',
      ]) {
        if (map.containsKey(key)) {
          out.addAll(findJsonLdObjects(map[key], typeName, depth: depth + 1));
        }
      }
    }
  }
  return out;
}

/// The first [typeName] object across a page's blocks, or null.
Map<String, dynamic>? firstJsonLdObject(String html, String typeName) {
  for (final block in extractJsonLdBlocks(html)) {
    final found = findJsonLdObjects(decodeJsonLdBlock(block), typeName);
    if (found.isNotEmpty) return found.first;
  }
  return null;
}

/// ISO-8601 duration ("PT1H30M", "P0DT0H45M", "PT0.5H") or a plain
/// "1 hour 30 minutes" / "45 mins" / "1 hr" string, to a [Duration].
/// Null when unreadable or zero.
Duration? parseIsoDuration(String? s) {
  if (s == null) return null;
  final t = s.trim();
  if (t.isEmpty) return null;
  final iso = RegExp(
    r'^P(?:(\d+(?:\.\d+)?)Y)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)W)?(?:(\d+(?:\.\d+)?)D)?'
    r'(?:T(?:(\d+(?:\.\d+)?)H)?(?:(\d+(?:\.\d+)?)M)?(?:(\d+(?:\.\d+)?)S)?)?$',
    caseSensitive: false,
  ).firstMatch(t);
  if (iso != null) {
    double g(int i) => double.tryParse(iso.group(i) ?? '') ?? 0;
    final minutes =
        g(1) * 525600 +
        g(2) * 43200 +
        g(3) * 10080 +
        g(4) * 1440 +
        g(5) * 60 +
        g(6) +
        g(7) / 60;
    if (minutes <= 0) return null;
    return Duration(minutes: minutes.round());
  }
  var minutes = 0.0;
  var any = false;
  for (final m in RegExp(
    r'(\d+(?:\.\d+)?)\s*(h(?:ou)?rs?|mins?(?:utes?)?|secs?(?:onds?)?)\b',
    caseSensitive: false,
  ).allMatches(t)) {
    any = true;
    final n = double.parse(m.group(1)!);
    final unit = m.group(2)!.toLowerCase();
    if (unit.startsWith('h')) {
      minutes += n * 60;
    } else if (unit.startsWith('m')) {
      minutes += n;
    } else {
      minutes += n / 60;
    }
  }
  if (!any || minutes <= 0) return null;
  return Duration(minutes: minutes.round());
}
