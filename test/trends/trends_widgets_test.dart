import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  testWidgets('TrendGate shows the nudge until enough points exist',
      (tester) async {
    await tester.pumpWidget(host(TrendGate(
      points: 3,
      minPoints: 5,
      nudge: 'Log five scored rounds and the trend appears.',
      builder: (_) => const Text('THE CHART'),
    )));
    expect(find.text('THE CHART'), findsNothing);
    expect(find.textContaining('Log five scored rounds'), findsOneWidget);

    await tester.pumpWidget(host(TrendGate(
      points: 5,
      minPoints: 5,
      nudge: 'unused',
      builder: (_) => const Text('THE CHART'),
    )));
    expect(find.text('THE CHART'), findsOneWidget);
  });

  testWidgets('YearlyBars renders every year in the span with counts',
      (tester) async {
    await tester.pumpWidget(host(const YearlyBars(
      countsByYear: {2023: 4, 2025: 9},
    )));
    for (final label in ['2023', '2024', '2025', '4', '0', '9']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('SimpleLineChart labels range and endpoints', (tester) async {
    await tester.pumpWidget(host(SimpleLineChart(points: [
      (DateTime(2024, 5), 92),
      (DateTime(2025, 7), 84),
      (DateTime(2026, 6), 88),
    ])));
    expect(find.text('92'), findsOneWidget); // max
    expect(find.text('84'), findsOneWidget); // min
    expect(find.text('5/24'), findsOneWidget);
    expect(find.text('6/26'), findsOneWidget);
  });

  testWidgets('RegionTileGrid draws all 50 states and fills played ones',
      (tester) async {
    await tester.pumpWidget(host(const RegionTileGrid(
      tiles: usStateTiles,
      filled: {'MI', 'OH'},
    )));
    expect(usStateTiles, hasLength(50));
    expect(find.text('MI'), findsOneWidget);
    expect(find.text('HI'), findsOneWidget);

    Color colorOf(String code) {
      final container = tester.widget<Container>(find.ancestor(
        of: find.text(code),
        matching: find.byType(Container),
      ));
      return (container.decoration! as BoxDecoration).color!;
    }

    expect(colorOf('MI'), colorOf('OH'));
    expect(colorOf('MI'), isNot(colorOf('TX')));
  });
}
