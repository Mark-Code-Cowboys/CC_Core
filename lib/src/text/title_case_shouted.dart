/// Printed matter shouts — scorecards, notebook headers, receipts print
/// names in ALL CAPS. Makes a shouted string readable ("BIG PINES RV
/// PARK" -> "Big Pines RV Park"); mixed-case input passes through
/// untouched, since it was already how the user wrote it.
///
/// Acronyms survive: a short word with no vowel (RV, BBQ, BLT, NY,
/// PB&J) or one of a few common vowelled ones (IPA, USA) stays upper,
/// except everyday abbreviations that are really words (St, Dr, Mr).
/// A token that starts with a digit is a unit ("16OZ" -> "16oz").
/// Extracted when the scorecard and notebook-page parsers had identical
/// copies; acronym handling added for Table Encore's receipt scanner.
String titleCaseShouted(String s) {
  if (s != s.toUpperCase()) return s;
  return s.split(' ').map(_caseWord).join(' ');
}

// Acronyms with a vowel (Y counts, so DRY and GYM stay words) that
// would otherwise be title-cased.
const _acronyms = {
  'IPA', 'IPAS', 'USA', 'UK', 'NY', 'NYC', 'BYOB', 'DIY', 'PBR',
};

// Vowel-less tokens that are abbreviations of ordinary words.
const _abbreviations = {
  'ST', 'DR', 'MR', 'MRS', 'MS', 'JR', 'SR', 'RD', 'LN', 'CT', 'PL', 'FT',
  'MT', 'SQ', 'LB', 'LBS', 'PC', 'PCS', 'HWY', 'PKWY', 'BLVD',
};

final _letters = RegExp(r'[A-Z&]+');
final _vowel = RegExp(r'[AEIOUY]');

String _caseWord(String w) {
  if (w.isEmpty) return w;
  final lower = w.toLowerCase();
  if (RegExp(r'^\d').hasMatch(w)) return lower;
  final core = _letters.firstMatch(w)?.group(0) ?? '';
  final keepUpper = _acronyms.contains(core) ||
      (core.length > 1 &&
          core.length <= 4 &&
          !_vowel.hasMatch(core) &&
          !_abbreviations.contains(core));
  if (keepUpper) return w;
  return lower[0].toUpperCase() + lower.substring(1);
}
