import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'journal_test_db.dart';

void main() {
  late JournalTestDb db;
  late FakePhotoFileStore store;
  late JournalRepository repo;

  setUp(() {
    db = JournalTestDb();
    store = FakePhotoFileStore();
    repo = JournalRepository(
      db,
      entries: db.journalEntries,
      photos: db.journalPhotos,
      tags: db.journalTags,
      photoStore: store,
    );
  });

  tearDown(() => db.close());

  test('createEntry stores story, rating, photos, and tags atomically',
      () async {
    final id = await repo.createEntry(const JournalEntryDraft(
      notes: 'Birdie on 17 into the wind.',
      rating: 5,
      tags: ['buddies trip', 'windy'],
      photos: [
        JournalPhotoDraft(path: 'card.jpg', caption: 'the card'),
        JournalPhotoDraft(path: 'view18.jpg'),
      ],
    ));

    final bundle = await repo.watchEntry(id).first;
    expect(bundle!.entry.notes, 'Birdie on 17 into the wind.');
    expect(bundle.entry.rating, 5);
    expect(bundle.photos.map((p) => p.path), ['card.jpg', 'view18.jpg']);
    expect(bundle.photos.first.caption, 'the card');
    expect(bundle.tags.map((t) => t.tag), ['buddies trip', 'windy']);
  });

  test('updateEntry rewrites both fields so clearing works', () async {
    final id = await repo.createEntry(
        const JournalEntryDraft(notes: 'draft', rating: 3));

    await repo.updateEntry(id, notes: 'final story');

    final bundle = await repo.watchEntry(id).first;
    expect(bundle!.entry.notes, 'final story');
    expect(bundle.entry.rating, isNull);
  });

  test('deleteEntries cascades rows and discards photo files', () async {
    final a = await repo.createEntry(const JournalEntryDraft(
        photos: [JournalPhotoDraft(path: 'a.jpg')]));
    final b = await repo.createEntry(const JournalEntryDraft(
        photos: [JournalPhotoDraft(path: 'b.jpg')], tags: ['keep?']));

    await repo.deleteEntries([a, b]);

    expect(await repo.watchEntry(a).first, isNull);
    expect(await db.select(db.journalPhotos).get(), isEmpty);
    expect(await db.select(db.journalTags).get(), isEmpty);
    expect(store.discarded, containsAll(['a.jpg', 'b.jpg']));
  });

  test('removePhoto drops the row and the file', () async {
    final id = await repo.createEntry(const JournalEntryDraft());
    final photoId =
        await repo.addPhoto(id, const JournalPhotoDraft(path: 'p.jpg'));

    await repo.removePhoto(photoId);

    expect((await repo.watchEntry(id).first)!.photos, isEmpty);
    expect(store.discarded, ['p.jpg']);
  });

  test('setTags replaces, and duplicate tags on one entry are rejected',
      () async {
    final id = await repo.createEntry(
        const JournalEntryDraft(tags: ['old']));

    await repo.setTags(id, ['windy', 'links']);
    expect((await repo.watchEntry(id).first)!.tags.map((t) => t.tag),
        ['windy', 'links']);

    expect(
      () => repo.addPhoto(id, const JournalPhotoDraft(path: 'x.jpg')),
      returnsNormally,
    );
    expect(
      () => repo.createEntry(const JournalEntryDraft(tags: ['a', 'a'])),
      throwsA(anything),
    );
  });

  test('getEntries bundles many ids for list joins', () async {
    final a = await repo.createEntry(const JournalEntryDraft(notes: 'A'));
    final b = await repo.createEntry(const JournalEntryDraft(
        notes: 'B', photos: [JournalPhotoDraft(path: 'b.jpg')]));

    final map = await repo.getEntries([a, b, 999]);
    expect(map.keys, containsAll([a, b]));
    expect(map[b]!.photos, hasLength(1));
    expect(map.containsKey(999), isFalse);
    expect(await repo.getEntries(const []), isEmpty);
  });

  test('searchEntryIds matches notes and tags, newest first', () async {
    final windyNotes = await repo.createEntry(
        const JournalEntryDraft(notes: 'Wind off the lake.'));
    final windyTag = await repo.createEntry(
        const JournalEntryDraft(notes: 'calm day', tags: ['windy']));
    await repo.createEntry(const JournalEntryDraft(notes: 'nothing here'));

    final hits = await repo.searchEntryIds('wind');
    expect(hits, [windyTag, windyNotes]); // newest first
  });

  test('entry rating outside 1-5 is rejected by the schema', () async {
    expect(
      () => repo.createEntry(const JournalEntryDraft(rating: 6)),
      throwsA(anything),
    );
  });
}
