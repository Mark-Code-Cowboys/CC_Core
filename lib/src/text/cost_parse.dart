// In preference order: the bottom-line total beats intermediate
// amounts — the same label-priority lesson as the scorecard gross/net
// fix. Extracted from Hitch Post's receipt parser when Back Forty
// became its second consumer (Table Encore's receipt parser wants line
// items, not totals — it stays domain).
const _costWords = [
  'grand total',
  'amount due',
  'total',
  'balance',
  'amount',
  'paid',
];

// "$84.00", "$1,234.56", "84.00" — cents required so plain integers
// (site numbers, dates, quantities) never read as money.
final _money = RegExp(r'\$?\s?(\d{1,3}(?:,\d{3})*|\d+)\.(\d{2})\b');
final _explicitMoney = RegExp(r'\$\s?(\d{1,3}(?:,\d{3})*|\d+)\.(\d{2})\b');

int _centsOf(RegExpMatch m) =>
    int.parse(m.group(1)!.replaceAll(',', '')) * 100 + int.parse(m.group(2)!);

/// Transcribes the total off merged OCR [rows]: the amount printed on
/// the best-labeled row (grand total > amount due > total > balance >
/// amount > paid, taking the amount after the label else the rightmost
/// on the row); with no labeled row, the largest amount printed with an
/// explicit `$`. Null when the page shows no money — never invented.
int? parseCostCents(List<String> rows) {
  int? cents;
  var costPriority = _costWords.length;
  for (final row in rows) {
    final lower = row.toLowerCase();
    final priority = _costWords.indexWhere(lower.contains);
    if (priority == -1 || priority >= costPriority) continue;
    final amounts = _money.allMatches(row).toList();
    if (amounts.isEmpty) continue;
    final labelEnd =
        lower.indexOf(_costWords[priority]) + _costWords[priority].length;
    final afterLabel = amounts.where((m) => m.start >= labelEnd).toList();
    cents = _centsOf(afterLabel.isNotEmpty ? afterLabel.first : amounts.last);
    costPriority = priority;
    if (priority == 0) break;
  }
  if (cents != null) return cents;
  int? largest;
  for (final row in rows) {
    for (final m in _explicitMoney.allMatches(row)) {
      final value = _centsOf(m);
      if (largest == null || value > largest) largest = value;
    }
  }
  return largest;
}
