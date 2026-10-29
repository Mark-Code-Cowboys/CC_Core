/// Repairs the classic OCR confusions in a quantity position: a
/// lowercase L / capital I / pipe read for "1", a letter O for "0",
/// "Z" for "2" and "S" for "5" inside a fraction, a stray space
/// inside a fraction, and a small typeset ¼ or ½ read as "Va" / "Vz"
/// in front of a measure, and "0Z" for "oz" after an amount. Only touches characters next to digits, slashes
/// or a following short unit word, so ordinary words are left alone
/// ("lemon", "Ice", "Oil"). Lifted from Trace Elements' recipe-card
/// scanner; receipts, scorecards and labels misread the same way.
///
/// Transcription-only (the module guardrail): this changes how a line
/// is *read*, never what the user sees as the source text — callers
/// keep the original line alongside.
String repairOcrDigits(String line) {
  var s = line;
  // "l cup", "I tsp", "| lb", "l/2" → "1 …".
  s = s.replaceFirstMapped(
    RegExp(
      r'^\s*[lI|](?=\s+(?:\d|[½¼¾⅓⅔⅛]|[A-Za-z]{1,12}\.?(?:\s|$))|[\d/½¼¾⅓⅔⅛])',
    ),
    (_) => '1',
  );
  // "Va teaspoon", "Vz cup": a small ¼ / ½ glyph read as letters
  // (ML Kit on a Yellowstone cookbook page, 2026). Only before a
  // measure, where a two-letter word can't stand.
  s = s.replaceFirstMapped(
    RegExp(
      r'^(\s*)(?:V[a4]|V[z2]|Y2)(?=\s+(?:teaspoons?|tsps?|tablespoons?|'
      r'tbsps?|cups?|c\.|pounds?|lbs?|ounces?|oz|pints?|pts?|quarts?|qts?|'
      r'inch(?:es)?)(?:\b|(?<=\.)))',
      caseSensitive: false,
    ),
    (m) =>
        '${m.group(1)}${RegExp(r'[a4]$', caseSensitive: false).hasMatch(m.group(0)!) ? '¼' : '½'}',
  );
  // "16 0Z can": the unit's O read as a zero.
  s = s.replaceAllMapped(
    RegExp(r'(\d\s*)[0O][Zz](?=\.?(?:\s|$))'),
    (m) => '${m.group(1)}oz',
  );
  // "1 l/2", "2 l/4": a mixed number whose numerator OCR'd as l/I.
  s = s.replaceAllMapped(
    RegExp(r'(\d)\s+[lI|](/\d)'),
    (m) => '${m.group(1)} 1${m.group(2)}',
  );
  // "1/Z" → "1/2", "1/S" → "1/5", "1/O" → "1/0".
  s = s.replaceAllMapped(RegExp(r'(\d)/([ZzSsOo])(?=\s|$|[A-Za-z])'), (m) {
    const map = {'Z': '2', 'z': '2', 'S': '5', 's': '5', 'O': '0', 'o': '0'};
    return '${m.group(1)}/${map[m.group(2)!]}';
  });
  // "O.5", "1O" (digit-adjacent O → 0).
  s = s.replaceAllMapped(RegExp(r'(?<=\d)[Oo](?=\d|\.|\s|$)'), (_) => '0');
  s = s.replaceAllMapped(RegExp(r'^\s*[Oo](?=[.,]\d)'), (_) => '0');
  // "1 /2", "1/ 2" → "1/2".
  s = s.replaceAllMapped(
    RegExp(r'(\d)\s+/\s*(\d)'),
    (m) => '${m.group(1)}/${m.group(2)}',
  );
  s = s.replaceAllMapped(
    RegExp(r'(\d)/\s+(\d)'),
    (m) => '${m.group(1)}/${m.group(2)}',
  );
  return s;
}
