import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('taps set, re-tapping the current rating clears',
      (tester) async {
    int? rating = 3;
    await tester.pumpWidget(MaterialApp(
      home: StatefulBuilder(
        builder: (context, setState) => Scaffold(
          body: RatingStars(
            rating: rating,
            onChanged: (r) => setState(() => rating = r),
          ),
        ),
      ),
    ));

    expect(find.byIcon(Icons.star), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.star_border).last); // 5th star
    await tester.pump();
    expect(rating, 5);
    await tester.tap(find.byIcon(Icons.star).last); // tap current -> clear
    await tester.pump();
    expect(rating, isNull);
  });
}
