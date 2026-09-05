import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FirstRunFlag starts unseen and persists markSeen', () async {
    final store = InMemoryKeyValueStore();
    final flag = FirstRunFlag(store);
    expect(await flag.seen(), isFalse);

    await flag.markSeen();
    expect(await flag.seen(), isTrue);
    // A second instance over the same store agrees.
    expect(await FirstRunFlag(store).seen(), isTrue);
  });

  testWidgets('OnboardingScaffold leads with positioning and the promise',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(
      home: OnboardingScaffold(
        icon: Icons.golf_course,
        positioning: 'The book of everywhere.',
        subtitle: 'Not a gadget.',
        actions: [
          FilledButton(
              onPressed: () => tapped = true, child: const Text('Start')),
        ],
      ),
    ));

    expect(find.text('The book of everywhere.'), findsOneWidget);
    expect(find.text('Not a gadget.'), findsOneWidget);
    expect(find.text(kPrivacyBoilerplate), findsOneWidget);
    await tester.tap(find.text('Start'));
    expect(tapped, isTrue);
  });
}
