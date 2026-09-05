import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('counter shows label/detail and both taps open the paywall',
      (tester) async {
    var opened = 0;
    const limit = FreeLimit(5, 'campgrounds');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FreeTierCounter(
          usage: limit.usage(2),
          onGoPro: () => opened++,
        ),
      ),
    ));

    expect(find.text('2 of 5 free campgrounds used'), findsOneWidget);
    expect(find.textContaining('3 more free'), findsOneWidget);
    await tester.tap(find.text('Go Pro'));
    await tester.tap(find.text('2 of 5 free campgrounds used'));
    expect(opened, 2);
  });
}
