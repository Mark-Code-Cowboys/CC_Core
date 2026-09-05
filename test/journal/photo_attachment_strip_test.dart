import 'dart:io';

import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('strip renders thumbnails, remove buttons, and the add tile',
      (tester) async {
    var removed = 0;
    var added = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PhotoAttachmentStrip(
          items: [
            PhotoStripItem(
                file: File('/nowhere/a.jpg'), onRemove: () => removed++),
            PhotoStripItem(file: File('/nowhere/b.jpg')),
          ],
          onAdd: () => added++,
        ),
      ),
    ));
    await tester.pump();

    // Two thumbnails (the missing-file fallback resolves off the test
    // zone's clock, so assert the Image widgets, not the placeholder).
    expect(find.byType(Image), findsNWidgets(2));
    expect(find.byIcon(Icons.close), findsOneWidget); // only item 1 removable

    await tester.tap(find.byIcon(Icons.close));
    expect(removed, 1);
    await tester.tap(find.byIcon(Icons.add_a_photo_outlined));
    expect(added, 1);
  });

  testWidgets('no add tile without onAdd', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PhotoAttachmentStrip(items: [])),
    ));
    expect(find.byIcon(Icons.add_a_photo_outlined), findsNothing);
  });
}
