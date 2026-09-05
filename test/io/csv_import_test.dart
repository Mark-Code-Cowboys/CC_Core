import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses plain rows with a header', () {
    final doc = parseCsv('name,score\nPine Hollow,92\nEagle Crest,88\n');
    expect(doc.header, ['name', 'score']);
    expect(doc.rows, [
      ['Pine Hollow', '92'],
      ['Eagle Crest', '88'],
    ]);
  });

  test('handles quotes, embedded commas, escaped quotes, and newlines', () {
    final doc = parseCsv(
        'name,notes\r\n"Bandon, Dunes","said ""wow""\nwindy day"\r\n');
    expect(doc.header, ['name', 'notes']);
    expect(doc.rows.single, ['Bandon, Dunes', 'said "wow"\nwindy day']);
  });

  test('short rows survive and rowCell answers null past the end', () {
    final doc = parseCsv('a,b,c\n1,2\n');
    final row = doc.rows.single;
    expect(row, ['1', '2']);
    expect(doc.rowCell(row, 1), '2');
    expect(doc.rowCell(row, 2), isNull);
    expect(doc.rowCell(row, 9), isNull);
  });

  test('blank cells read as null via rowCell', () {
    final doc = parseCsv('a,b\n1,\n');
    expect(doc.rowCell(doc.rows.single, 1), isNull);
  });

  test('empty input yields an empty document', () {
    final doc = parseCsv('');
    expect(doc.header, isEmpty);
    expect(doc.rows, isEmpty);
  });
}
