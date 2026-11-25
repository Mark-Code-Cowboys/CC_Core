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

  test('parseLooseDates reads a whole range row in print order', () {
    expect(parseLooseDates('6/12/2026 - 6/15/2026'), [
      DateTime(2026, 6, 12),
      DateTime(2026, 6, 15),
    ]);
    expect(parseLooseDates('no dates'), isEmpty);
  });

  test('never invents a date', () {
    expect(parseLooseDate('no date here'), isNull);
    expect(parseLooseDate('2/30/2026'), isNull); // rollover rejected
  });

  test('dayFirst reads European numeric dates; ISO and words unaffected',
      () {
    expect(parseLooseDate('03/04/2026'), DateTime(2026, 3, 4));
    expect(parseLooseDate('03/04/2026', dayFirst: true), DateTime(2026, 4, 3));
    expect(parseLooseDate('25.03.2026', dayFirst: true), DateTime(2026, 3, 25));
    // A first number that can't be a day... can still be a month.
    expect(parseLooseDate('03/25/2026', dayFirst: true), DateTime(2026, 3, 25));
    expect(parseLooseDate('2026-04-03', dayFirst: true), DateTime(2026, 4, 3));
    expect(parseLooseDate('June 15, 2026', dayFirst: true),
        DateTime(2026, 6, 15));
  });

  test('numericDatesLookDayFirst decides per column', () {
    expect(numericDatesLookDayFirst(['03/04/2026', '25/03/2026']), isTrue);
    expect(numericDatesLookDayFirst(['03/04/2026', '03/25/2026']), isFalse);
    // Ambiguous throughout: month-first, like parseLooseDate.
    expect(numericDatesLookDayFirst(['03/04/2026', '05/06/2026']), isFalse);
    // Contradictory column: month-first wins (never flips a US file).
    expect(numericDatesLookDayFirst(['25/03/2026', '03/25/2026']), isFalse);
    expect(numericDatesLookDayFirst(['2026-03-25', 'n/a']), isFalse);
  });
}

