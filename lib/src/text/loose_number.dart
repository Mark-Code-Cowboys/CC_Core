/// Numbers the way people write them: "1 1/2", "1-1/2", "1½", "1 ½",
/// "¾", "3/4", ".5", "2.25", "7". The inverse, [formatQuantity], prints
/// common fractions back as glyphs. Lifted from Trace Elements'
/// ingredient parser; label weights and scorecard entries read the
/// same way.
library;

/// Unicode vulgar fractions and their values.
const Map<String, double> unicodeFractions = {
  '½': 0.5,
  '⅓': 1 / 3,
  '⅔': 2 / 3,
  '¼': 0.25,
  '¾': 0.75,
  '⅕': 0.2,
  '⅖': 0.4,
  '⅗': 0.6,
  '⅘': 0.8,
  '⅙': 1 / 6,
  '⅚': 5 / 6,
  '⅛': 0.125,
  '⅜': 0.375,
  '⅝': 0.625,
  '⅞': 0.875,
};

/// Every unicode vulgar fraction glyph, for character classes.
const String unicodeFractionChars = '½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞';

/// Regex source matching one loose number; alternatives are ordered so
/// the longest reading wins.
const String looseNumberPattern =
    r'(?:\d+\s*[' +
    unicodeFractionChars +
    r']|\d+[\s-]+\d+/\d+|\d+/\d+|\d*\.\d+|\d+|[' +
    unicodeFractionChars +
    r'])';

/// Parses one token matched by [looseNumberPattern]. Null for an empty
/// token, a zero denominator, or anything else.
double? parseLooseNumber(String token) {
  final t = token.trim();
  if (t.isEmpty) return null;
  final uni = RegExp('^(\\d+)\\s*([$unicodeFractionChars])\$').firstMatch(t);
  if (uni != null) {
    return double.parse(uni.group(1)!) + unicodeFractions[uni.group(2)!]!;
  }
  final mixed = RegExp(r'^(\d+)[\s-]+(\d+)/(\d+)$').firstMatch(t);
  if (mixed != null) {
    final den = double.parse(mixed.group(3)!);
    if (den == 0) return null;
    return double.parse(mixed.group(1)!) + double.parse(mixed.group(2)!) / den;
  }
  final frac = RegExp(r'^(\d+)/(\d+)$').firstMatch(t);
  if (frac != null) {
    final den = double.parse(frac.group(2)!);
    if (den == 0) return null;
    return double.parse(frac.group(1)!) / den;
  }
  if (t.length == 1 && unicodeFractions.containsKey(t)) {
    return unicodeFractions[t];
  }
  return double.tryParse(t);
}

/// The first loose number inside free text, or null.
double? firstLooseNumberIn(String text) {
  final m = RegExp(looseNumberPattern).firstMatch(text);
  return m == null ? null : parseLooseNumber(m.group(0)!);
}

/// Whole numbers bare, common fractions as glyphs ("2½", "¼"), else up
/// to two decimals with trailing zeros dropped.
String formatQuantity(double v) {
  const fractions = <(double, String)>[
    (0.25, '¼'),
    (0.5, '½'),
    (0.75, '¾'),
    (1 / 3, '⅓'),
    (2 / 3, '⅔'),
    (0.125, '⅛'),
  ];
  final whole = v.floor();
  final frac = v - whole;
  for (final (value, glyph) in fractions) {
    if ((frac - value).abs() < 0.01) {
      return whole == 0 ? glyph : '$whole$glyph';
    }
  }
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
}
