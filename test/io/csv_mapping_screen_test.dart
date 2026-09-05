import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _fields = [
  CsvField('name',
      label: 'Campground (required)',
      isRequired: true,
      guessTiers: [
        ['campground', 'park'],
        ['name'],
      ]),
  CsvField('date', label: 'Date', guessTiers: [
    ['date', 'arrive'],
  ]),
  CsvField('cost', label: 'Cost'),
];

void main() {
  test('guessCsvMapping matches tiers in order, case-insensitive', () {
    final mapping = guessCsvMapping(
        ['Name', 'Arrive Date', 'Total'], _fields);
    // Tier 1 (campground/park) misses, tier 2 (name) hits column 0.
    expect(mapping, {'name': 0, 'date': 1, 'cost': null});
  });

  testWidgets('import stays disabled until required fields are mapped '
      'and returns the chosen mapping', (tester) async {
    Map<String, int?>? received;
    const doc = CsvDocument(header: [
      'Spot',
      'When',
    ], rows: [
      ['KOA Butte', '6/15/2026'],
    ]);
    // Push over a base scaffold so the after-pop snackbar has a home.
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showCsvMappingScreen(
                context,
                doc: doc,
                fields: _fields,
                title: 'Import spreadsheet',
                footnote: 'Fine print.',
                onImport: (m) async {
                  received = m;
                  return 'Imported 1 visit';
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // No guess matches "Spot"/"When": required field unmapped.
    final button = find.widgetWithText(FilledButton, 'Import');
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    // Map the required field via its dropdown.
    await tester.tap(find.text('Campground (required)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spot').last);
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(button).onPressed, isNotNull);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(received, {'name': 0, 'date': null, 'cost': null});
    expect(find.text('Imported 1 visit'), findsOneWidget);
    // Drain the snackbar timer before teardown.
    await tester.pump(const Duration(seconds: 5));
  });
}
