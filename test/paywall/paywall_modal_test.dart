import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A page with a button that opens a paywall-style sheet whose buy
/// button runs [action] through [runStoreAction].
Widget _app(Future<void> Function() action, {VoidCallback? onTapped}) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showPaywallModal<void>(
              context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Pro'),
                    FilledButton(
                      onPressed: () {
                        onTapped?.call();
                        runStoreAction(context, action);
                      },
                      child: const Text('Buy'),
                    ),
                  ],
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );

Future<void> _openAndBuy(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Buy'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unavailable store shows its snackbar on the sheet, '
      'not on the page behind it', (tester) async {
    await tester.pumpWidget(
        _app(() async => throw const StoreUnavailableException()));
    await _openAndBuy(tester);

    final message = find.text('Store not available on this device right now.');
    expect(message, findsOneWidget);
    expect(find.descendant(of: find.byType(BottomSheet), matching: message),
        findsOneWidget);
  });

  testWidgets('other store failures show their reason on the sheet',
      (tester) async {
    await tester.pumpWidget(_app(() async => throw Exception('declined')));
    await _openAndBuy(tester);

    expect(
        find.descendant(
            of: find.byType(BottomSheet),
            matching: find.textContaining('declined')),
        findsOneWidget);
  });

  testWidgets('the overlay passes taps through and the sheet keeps its '
      'content height', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_app(() async {}, onTapped: () => taps++));
    await _openAndBuy(tester);
    expect(taps, 1);

    final sheet = tester.getSize(find.byType(BottomSheet));
    final screen = tester.getSize(find.byType(MaterialApp));
    expect(sheet.height, lessThan(screen.height / 2));
    expect(sheet.width, screen.width);
  });
}
