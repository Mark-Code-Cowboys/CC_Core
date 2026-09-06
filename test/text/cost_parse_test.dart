import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('takes the amount after the best label, not the first row', () {
    expect(
        parseCostCents(['Amount 30.00', 'Tax 2.40', 'Grand Total \$92.40']),
        9240);
    expect(parseCostCents(['Total 84.00 deposit 20.00']), 8400);
    expect(parseCostCents(['Total \$1,234.56']), 123456);
  });

  test('falls back to the largest explicit-\$ amount when unlabeled', () {
    expect(parseCostCents(['\$12.00 filter', '\$96.00 labor']), 9600);
  });

  test('never invents money from bare numbers', () {
    expect(parseCostCents(['Model 42', '3 filters', 'June 15 2026']),
        isNull);
  });

  test('parsePageDates walks range rows in print order', () {
    expect(parsePageDates(['stuff', '6/12/2026 - 6/15/2026', '7/1/2026']),
        [DateTime(2026, 6, 12), DateTime(2026, 6, 15)]);
    expect(parsePageDates(['no dates']), isEmpty);
  });
}
