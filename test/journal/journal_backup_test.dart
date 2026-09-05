import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_db.dart';

void main() {
  JournalRepository repoFor(JournalTestDb db) => JournalRepository(
        db,
        entries: db.journalEntries,
        photos: db.journalPhotos,
        tags: db.journalTags,
      );

  test('dump/restore round-trips the journal tables, ids preserved',
      () async {
    final source = JournalTestDb();
    addTearDown(source.close);
    final repo = repoFor(source);
    await repo.createEntry(const JournalEntryDraft(
      notes: 'Back in next June.',
      rating: 5,
      tags: ['creek side'],
      photos: [JournalPhotoDraft(path: 'visit-1.jpg', caption: 'the view')],
    ));
    await repo.createEntry(const JournalEntryDraft(notes: 'Tight turn.'));

    final dump = await repo.dumpJournalTables();
    expect(dump.keys,
        ['journalEntries', 'journalPhotos', 'journalTags']);

    final target = JournalTestDb();
    addTearDown(target.close);
    final restored = repoFor(target);
    await restored.restoreJournalTables(dump);

    // Byte-identical re-dump: ids, timestamps, captions all preserved.
    expect(await restored.dumpJournalTables(), dump);
    final first = await restored
        .watchEntry(dump['journalEntries']!.first['id'] as int)
        .first;
    expect(first!.entry.notes, 'Back in next June.');
    expect(first.photos.single.caption, 'the view');
    expect(first.tags.single.tag, 'creek side');
  });

  test('restore replaces what was there and rejects malformed maps',
      () async {
    final db = JournalTestDb();
    addTearDown(db.close);
    final repo = repoFor(db);
    await repo.createEntry(const JournalEntryDraft(notes: 'stale'));

    await repo.restoreJournalTables(const {
      'journalEntries': <Object?>[],
      'journalPhotos': <Object?>[],
      'journalTags': <Object?>[],
    });
    expect((await repo.dumpJournalTables())['journalEntries'], isEmpty);

    expect(
      () => repo.restoreJournalTables(const {'journalEntries': 'nope'}),
      throwsA(isA<InvalidBackupException>()),
    );
  });
}
