/// Printed matter shouts — scorecards, notebook headers, receipts print
/// names in ALL CAPS. Makes a shouted string readable ("BIG PINES RV
/// PARK" -> "Big Pines Rv Park"); mixed-case input passes through
/// untouched, since it was already how the user wrote it. Extracted
/// when the scorecard and notebook-page parsers had identical copies.
String titleCaseShouted(String s) {
  if (s != s.toUpperCase()) return s;
  return s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}
