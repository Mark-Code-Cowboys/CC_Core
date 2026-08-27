import 'dart:async';

import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget app(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('entitled: the child is interactive, no paywall', (tester) async {
    var childTaps = 0;
    var paywallOpens = 0;

    await tester.pumpWidget(app(EntitlementGate(
      entitled: Stream.value(true),
      showPaywall: (_) async => paywallOpens++,
      child: ElevatedButton(
          onPressed: () => childTaps++, child: const Text('Do the thing')),
    )));
    await tester.pump();

    await tester.tap(find.text('Do the thing'));
    expect(childTaps, 1);
    expect(paywallOpens, 0);
  });

  testWidgets('not entitled: taps open the paywall, child never fires',
      (tester) async {
    var childTaps = 0;
    var paywallOpens = 0;

    await tester.pumpWidget(app(EntitlementGate(
      entitled: Stream.value(false),
      showPaywall: (_) async => paywallOpens++,
      child: ElevatedButton(
          onPressed: () => childTaps++, child: const Text('Do the thing')),
    )));
    await tester.pump();

    await tester.tap(find.text('Do the thing'));
    expect(childTaps, 0);
    expect(paywallOpens, 1);
  });

  testWidgets('while loading the gate stays closed', (tester) async {
    var paywallOpens = 0;
    final controller = StreamController<bool>();

    await tester.pumpWidget(app(EntitlementGate(
      entitled: controller.stream,
      showPaywall: (_) async => paywallOpens++,
      child: const Text('Locked until proven entitled'),
    )));

    await tester.tap(find.text('Locked until proven entitled'));
    expect(paywallOpens, 1, reason: 'no entitlement yet → locked');

    controller.add(true);
    await tester.pump();
    await tester.tap(find.text('Locked until proven entitled'));
    expect(paywallOpens, 1, reason: 'now entitled → tap reaches the child');

    await controller.close();
  });

  testWidgets('lockedBuilder replaces the default locked look',
      (tester) async {
    var paywallOpens = 0;

    await tester.pumpWidget(app(EntitlementGate(
      entitled: Stream.value(false),
      showPaywall: (_) async => paywallOpens++,
      lockedBuilder: (context, openPaywall) =>
          TextButton(onPressed: openPaywall, child: const Text('Unlock')),
      child: const Text('The real feature'),
    )));
    await tester.pump();

    expect(find.text('The real feature'), findsNothing);
    await tester.tap(find.text('Unlock'));
    expect(paywallOpens, 1);
  });

  testWidgets('purchase flips the gate open live', (tester) async {
    final entitlements = FakeEntitlementService();

    await tester.pumpWidget(app(EntitlementGate(
      entitled: entitlements.watchUnlimited(),
      showPaywall: (_) async {},
      child: const Text('Premium feature'),
      lockedBuilder: (context, openPaywall) => const Text('Locked'),
    )));
    await tester.pump();
    expect(find.text('Locked'), findsOneWidget);

    await entitlements.buyUnlimited();
    await tester.pump();
    await tester.pump();
    expect(find.text('Premium feature'), findsOneWidget);

    entitlements.dispose();
  });
}
