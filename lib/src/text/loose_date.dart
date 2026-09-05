const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

final _numericDate = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b');
final _isoDate = RegExp(r'\b(\d{4})-(\d{1,2})-(\d{1,2})\b');
final _writtenDate = RegExp(
    r'\b(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\.?\s+'
    r'(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b',
    caseSensitive: false);

/// Reads a date out of free text — receipts, scorecards, notebook
/// pages, spreadsheet cells: "6/15/2026", "6-15-26", "2026-06-15",
/// "June 15, 2026". US month-first for the numeric forms (with a
/// day-first rescue when the first number can't be a month). Null when
/// nothing parseable is found — callers never invent a date. Extracted
/// from Course Ledger when Hitch Post became its second consumer.
DateTime? parseLooseDate(String text) {
  final iso = _isoDate.firstMatch(text);
  if (iso != null) {
    return _validDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
        int.parse(iso.group(3)!));
  }
  final written = _writtenDate.firstMatch(text);
  if (written != null) {
    final month = _months.indexWhere((m) =>
            m.toLowerCase() == written.group(1)!.toLowerCase()) +
        1;
    return _validDate(
        int.parse(written.group(3)!), month, int.parse(written.group(2)!));
  }
  final numeric = _numericDate.firstMatch(text);
  if (numeric != null) {
    var a = int.parse(numeric.group(1)!);
    var b = int.parse(numeric.group(2)!);
    var year = int.parse(numeric.group(3)!);
    if (year < 100) year += year >= 70 ? 1900 : 2000;
    if (a > 12 && b <= 12) (a, b) = (b, a); // day-first rescue
    return _validDate(year, a, b);
  }
  return null;
}

DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (year < 1900 || year > 2100) return null;
  final d = DateTime(year, month, day);
  // Reject rollovers like Feb 30 -> Mar 2.
  return (d.month == month && d.day == day) ? d : null;
}
