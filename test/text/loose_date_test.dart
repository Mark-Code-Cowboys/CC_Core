import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads the common receipt/spreadsheet/scorecard forms', () {
    expect(parseLooseDate('6/15/2026'), DateTime(2026, 6, 15));
    expect(parseLooseDate('06-15-26'), DateTime(2026, 6, 15));
    expect(parseLooseDate('2026-06-15'), DateTime(2026, 6, 15));
    expect(parseLooseDate('June 15, 2026'), DateTime(2026, 6, 15));
    expect(parseLooseDate('paid Jun 15 2026 pm'), DateTime(2026, 6, 15));
    expect(parseLooseDate('15/6/2026'), DateTime(2026, 6, 15)); // day-first
  });

  test('never invents a date', () {
    expect(parseLooseDate('no date here'), isNull);
    expect(parseLooseDate('2/30/2026'), isNull); // rollover rejected
  });
}
