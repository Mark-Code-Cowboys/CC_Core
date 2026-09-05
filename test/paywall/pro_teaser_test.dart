import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the pitch and fires both callbacks',
      (tester) async {
    var pro = 0, restore = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProTeaser(
          icon: Icons.map_outlined,
          headline: 'The long arc of the road.',
          body: 'All part of Pro.',
          ctaLabel: 'See Hitch Post Pro',
          onSeePro: () => pro++,
          ungatedLabel: 'Restore a backup',
          onUngated: () => restore++,
        ),
      ),
    ));

    expect(find.text('The long arc of the road.'), findsOneWidget);
    await tester.tap(find.text('See Hitch Post Pro'));
    await tester.tap(find.text('Restore a backup'));
    expect((pro, restore), (1, 1));
  });

  testWidgets('no ungated label, no divider row', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ProTeaser(
          icon: Icons.map_outlined,
          headline: 'H',
          body: 'B',
          ctaLabel: 'C',
          onSeePro: () {},
        ),
      ),
    ));
    expect(find.byType(Divider), findsNothing);
  });
}
