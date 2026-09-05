import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('round-trips export JSON and media bytes', () {
    final bytes = buildBackupArchive(
      exportData: {
        'app': 'CourseLedger',
        'format': 1,
        'rows': [1, 2, 3],
      },
      media: {
        'card1.jpg': [1, 2, 3],
        'view18.jpg': [9, 8],
      },
    );

    final contents = readBackupArchive(bytes);
    expect(contents.exportData['app'], 'CourseLedger');
    expect(contents.exportData['rows'], [1, 2, 3]);
    expect(contents.media['card1.jpg'], [1, 2, 3]);
    expect(contents.media['view18.jpg'], [9, 8]);
  });

  test('custom entry names keep Table Encore backups readable', () {
    final bytes = buildBackupArchive(
      exportData: {'app': 'TableEncore'},
      media: {'dish.jpg': [1]},
      jsonEntry: 'journal.json',
      mediaPrefix: 'photos/',
    );
    final contents = readBackupArchive(bytes,
        jsonEntry: 'journal.json', mediaPrefix: 'photos/');
    expect(contents.exportData['app'], 'TableEncore');
    expect(contents.media.keys, ['dish.jpg']);
  });

  test('traversal-shaped media names are dropped', () {
    final bytes = buildBackupArchive(
      exportData: const {'ok': true},
      media: {'../evil.sh': [1], 'nested/inner.jpg': [2], 'fine.jpg': [3]},
    );
    final contents = readBackupArchive(bytes);
    expect(contents.media.keys, ['fine.jpg']);
  });

  test('rejects non-zip bytes and archives without the export entry', () {
    expect(() => readBackupArchive([1, 2, 3]),
        throwsA(isA<InvalidBackupException>()));
    final noJson = buildBackupArchive(
        exportData: const {}, jsonEntry: 'other.json');
    expect(() => readBackupArchive(noJson),
        throwsA(isA<InvalidBackupException>()));
  });
}
