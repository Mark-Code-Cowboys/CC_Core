import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('encodes plain rows with CRLF endings', () {
    expect(
      buildCsv([
        ['name', 'score'],
        ['Pine Hollow', 92],
      ]),
      'name,score\r\nPine Hollow,92\r\n',
    );
  });

  test('quotes and escapes only when needed, null becomes empty', () {
    final csv = buildCsv([
      ['Bandon, Dunes', 'said "wow"', null, 'line\nbreak'],
    ]);
    expect(csv, '"Bandon, Dunes","said ""wow""",,"line\nbreak"\r\n');
  });

  test('round-trips through parseCsv', () {
    final rows = [
      ['course', 'notes'],
      ['Bandon, Dunes', 'said "wow"\nwindy'],
      ['Pine Hollow', ''],
    ];
    final doc = parseCsv(buildCsv(rows));
    expect(doc.header, rows.first);
    expect(doc.rows, rows.sublist(1));
  });
}
