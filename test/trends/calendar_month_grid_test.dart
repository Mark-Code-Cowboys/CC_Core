import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('grid aligns days Sunday-first and covers the whole month',
      (tester) async {
    final seen = <DateTime>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          // June 2026: starts on a Monday (leading = 1), 30 days.
          child: CalendarMonthGrid(
            year: 2026,
            month: 6,
            dayBuilder: (context, date) {
              seen.add(date);
              return Text('${date.day}');
            },
          ),
        ),
      ),
    ));

    expect(seen, hasLength(30));
    expect(seen.first, DateTime(2026, 6, 1));
    expect(seen.last, DateTime(2026, 6, 30));
    expect(find.text('Sun'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    // Monday June 1st sits in column 1 -> its center is right of the
    // empty Sunday column's slot.
    final one = tester.getCenter(find.text('1'));
    final eight = tester.getCenter(find.text('8'));
    expect(one.dx, eight.dx, reason: 'the 1st and 8th share a column');
  });

  testWidgets('window nav labels and gates the arrows', (tester) async {
    var prev = 0, next = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TrendWindowNav(
          label: 'June 2026',
          onPrev: () => prev++,
          onNext: () => next++,
          nextEnabled: false,
        ),
      ),
    ));

    expect(find.text('June 2026'), findsOneWidget);
    await tester.tap(find.byTooltip('Previous'));
    await tester.tap(find.byTooltip('Next'), warnIfMissed: false);
    expect(prev, 1);
    expect(next, 0); // disabled at the present edge
  });
}
