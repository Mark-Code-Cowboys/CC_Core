/// Small HTML-to-text helpers: entity unescaping and tag stripping for
/// strings that arrive with markup in them (JSON-LD fields, API
/// attribution strings, pasted text). Not an HTML parser.
library;

const Map<String, String> _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'ensp': ' ',
  'emsp': ' ',
  'thinsp': ' ',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
  'middot': '·',
  'bull': '•',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
  'frac12': '½',
  'frac14': '¼',
  'frac34': '¾',
  'frac13': '⅓',
  'frac23': '⅔',
  'frac18': '⅛',
  'frac38': '⅜',
  'frac58': '⅝',
  'frac78': '⅞',
  'deg': '°',
  'times': '×',
  'divide': '÷',
  'copy': '©',
  'reg': '®',
  'trade': '™',
  'eacute': 'é',
  'egrave': 'è',
  'ecirc': 'ê',
  'agrave': 'à',
  'aacute': 'á',
  'acirc': 'â',
  'auml': 'ä',
  'ouml': 'ö',
  'uuml': 'ü',
  'ntilde': 'ñ',
  'ccedil': 'ç',
  'iacute': 'í',
  'oacute': 'ó',
  'uacute': 'ú',
  'szlig': 'ß',
  'oslash': 'ø',
  'aring': 'å',
  'aelig': 'æ',
};

final _entity = RegExp(r'&(#x[0-9a-fA-F]+|#\d+|[a-zA-Z][a-zA-Z0-9]*);');

/// Replaces named and numeric character references. Unknown names are
/// left as they are.
String unescapeHtml(String s) {
  if (!s.contains('&')) return s;
  return s.replaceAllMapped(_entity, (m) {
    final ref = m.group(1)!;
    if (ref.startsWith('#x') || ref.startsWith('#X')) {
      final code = int.tryParse(ref.substring(2), radix: 16);
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    if (ref.startsWith('#')) {
      final code = int.tryParse(ref.substring(1));
      return code == null ? m.group(0)! : String.fromCharCode(code);
    }
    return _namedEntities[ref] ?? m.group(0)!;
  });
}

final _blockBreak = RegExp(
  r'<\s*(?:br|/p|/li|/div|/h[1-6]|/tr)\s*/?\s*>',
  caseSensitive: false,
);
final _tag = RegExp(r'<[^>]+>');

/// Tags out, entities decoded, whitespace collapsed. Block-level
/// closers become newlines so a `<p>`-per-step string still splits
/// into lines; use [stripHtmlInline] when the result must be one line.
String stripHtml(String s) {
  var t = s.replaceAll(_blockBreak, '\n');
  t = t.replaceAll(_tag, ' ');
  t = unescapeHtml(t);
  t = t.replaceAll('\r', '');
  final lines = t
      .split('\n')
      .map((l) => l.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .where((l) => l.isNotEmpty);
  return lines.join('\n');
}

/// [stripHtml] flattened to a single line.
String stripHtmlInline(String s) =>
    stripHtml(s).replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
