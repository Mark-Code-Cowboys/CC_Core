import 'package:drift/drift.dart';
import 'package:stream_transform/stream_transform.dart';

import 'journal_tables.dart';
import 'photo_store.dart';

/// A photo being attached, before it has a database id.
class JournalPhotoDraft {
  /// Creates the draft.
  const JournalPhotoDraft({required this.path, this.caption});

  /// File name under the app's photo store.
  final String path;

  /// Optional caption.
  final String? caption;
}

/// An entry being composed, before it has a database id.
class JournalEntryDraft {
  /// Creates the draft.
  const JournalEntryDraft({
    this.notes,
    this.rating,
    this.tags = const [],
    this.photos = const [],
  });

  /// The story.
  final String? notes;

  /// 1-5, or null.
  final int? rating;

  /// Tags to attach.
  final List<String> tags;

  /// Photos to attach.
  final List<JournalPhotoDraft> photos;
}

/// An entry with everything attached to it.
class JournalEntryWithMedia {
  /// Creates the bundle.
  const JournalEntryWithMedia(this.entry, {required this.photos, required this.tags});

  /// The entry row.
  final JournalEntry entry;

  /// Attached photos, insertion order.
  final List<JournalPhoto> photos;

  /// Attached tags, insertion order.
  final List<JournalTag> tags;
}

/// CRUD and search over the shared journal tables, generic over the
/// app's generated table classes so one repository serves every CC app
/// database. Construct with the generated getters:
///
/// ```dart
/// JournalRepository(db,
///     entries: db.journalEntries,
///     photos: db.journalPhotos,
///     tags: db.journalTags,
///     photoStore: store);
/// ```
///
/// Photo *files* are discarded through [photoStore] whenever their rows
/// go away; pass null in tests that don't care about files.
class JournalRepository<ET extends JournalEntries, PT extends JournalPhotos,
    TT extends JournalTags> {
  /// Creates the repository over the app's database and journal tables.
  JournalRepository(
    this._db, {
    required this.entries,
    required this.photos,
    required this.tags,
    PhotoFileStore? photoStore,
    // ignore: prefer_initializing_formals
  }) : _photoStore = photoStore;

  final GeneratedDatabase _db;

  /// The app's generated journal-entries table.
  final TableInfo<ET, JournalEntry> entries;

  /// The app's generated journal-photos table.
  final TableInfo<PT, JournalPhoto> photos;

  /// The app's generated journal-tags table.
  final TableInfo<TT, JournalTag> tags;

  final PhotoFileStore? _photoStore;

  // The DSL column types (TextColumn, IntColumn) don't expose the SQL
  // name statically; at runtime every column on a generated table is a
  // GeneratedColumn.
  static String _n(Column<Object> c) => (c as GeneratedColumn).name;

  Future<void> _discard(Iterable<String> paths) async {
    for (final path in paths) {
      await _photoStore?.discard(path);
    }
  }

  /// Creates the entry with its photos and tags atomically; returns the
  /// entry id.
  Future<int> createEntry(JournalEntryDraft d) {
    return _db.transaction(() async {
      final e = entries.asDslTable;
      final entryId =
          await _db.into(entries).insert(RawValuesInsertable<JournalEntry>({
        if (d.notes != null) _n(e.notes): Variable(d.notes),
        if (d.rating != null) _n(e.rating): Variable(d.rating),
      }));
      for (final photo in d.photos) {
        await _insertPhoto(entryId, photo);
      }
      for (final tag in d.tags) {
        await _insertTag(entryId, tag);
      }
      return entryId;
    });
  }

  /// Rewrites the entry's story and rating (both columns, so clearing
  /// works).
  Future<void> updateEntry(int id, {String? notes, int? rating}) {
    final e = entries.asDslTable;
    return (_db.update(entries)..where((t) => t.id.equals(id)))
        .write(RawValuesInsertable<JournalEntry>({
      _n(e.notes): Variable(notes),
      _n(e.rating): Variable(rating),
    }));
  }

  /// Deletes the entries, their photo/tag rows (FK cascade), and their
  /// photo files. The call every domain delete routes through.
  Future<void> deleteEntries(Iterable<int> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return;
    final paths = await _photoPathsFor(idList);
    await (_db.delete(entries)..where((t) => t.id.isIn(idList))).go();
    await _discard(paths);
  }

  /// Deletes one entry; see [deleteEntries].
  Future<void> deleteEntry(int id) => deleteEntries([id]);

  Future<List<String>> _photoPathsFor(List<int> entryIds) async {
    final p = photos.asDslTable;
    final query = _db.selectOnly(photos)
      ..addColumns([p.path])
      ..where(p.entryId.isIn(entryIds));
    return [
      for (final row in await query.get()) row.read(p.path)!,
    ];
  }

  Future<int> _insertPhoto(int entryId, JournalPhotoDraft d) {
    final p = photos.asDslTable;
    return _db.into(photos).insert(RawValuesInsertable<JournalPhoto>({
      _n(p.entryId): Variable(entryId),
      _n(p.path): Variable(d.path),
      if (d.caption != null) _n(p.caption): Variable(d.caption),
    }));
  }

  Future<int> _insertTag(int entryId, String tag) {
    final t = tags.asDslTable;
    return _db.into(tags).insert(RawValuesInsertable<JournalTag>({
      _n(t.entryId): Variable(entryId),
      _n(t.tag): Variable(tag),
    }));
  }

  /// Attaches one photo.
  Future<int> addPhoto(int entryId, JournalPhotoDraft d) =>
      _insertPhoto(entryId, d);

  /// Removes one photo row and its file.
  Future<void> removePhoto(int photoId) async {
    final row = await (_db.select(photos)
          ..where((t) => t.id.equals(photoId)))
        .getSingleOrNull();
    await (_db.delete(photos)..where((t) => t.id.equals(photoId))).go();
    if (row != null) await _discard([row.path]);
  }

  /// Replaces the entry's tags.
  Future<void> setTags(int entryId, List<String> values) {
    return _db.transaction(() async {
      await (_db.delete(tags)..where((x) => x.entryId.equals(entryId))).go();
      for (final value in values) {
        await _insertTag(entryId, value);
      }
    });
  }

  /// The entry with its media, kept live as any of it changes.
  Stream<JournalEntryWithMedia?> watchEntry(int id) {
    final entryQuery = _db.select(entries)..where((t) => t.id.equals(id));
    return entryQuery.watchSingleOrNull().switchMap((entry) {
      if (entry == null) return Stream.value(null);
      final photoQuery = _db.select(photos)
        ..where((p) => p.entryId.equals(id))
        ..orderBy([(p) => OrderingTerm.asc(p.id)]);
      final tagQuery = _db.select(tags)
        ..where((t) => t.entryId.equals(id))
        ..orderBy([(t) => OrderingTerm.asc(t.id)]);
      return photoQuery.watch().combineLatest(
          tagQuery.watch(),
          (photoRows, List<JournalTag> tagRows) => JournalEntryWithMedia(
              entry,
              photos: photoRows,
              tags: tagRows));
    });
  }

  /// One-shot bundle fetch for list joins: entry id -> media.
  Future<Map<int, JournalEntryWithMedia>> getEntries(
      Iterable<int> ids) async {
    final idList = ids.toList();
    if (idList.isEmpty) return const {};
    final entryRows = await (_db.select(entries)
          ..where((t) => t.id.isIn(idList)))
        .get();
    final photoRows = await (_db.select(photos)
          ..where((p) => p.entryId.isIn(idList))
          ..orderBy([(p) => OrderingTerm.asc(p.id)]))
        .get();
    final tagRows = await (_db.select(tags)
          ..where((t) => t.entryId.isIn(idList))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return {
      for (final entry in entryRows)
        entry.id: JournalEntryWithMedia(
          entry,
          photos: [
            for (final p in photoRows)
              if (p.entryId == entry.id) p,
          ],
          tags: [
            for (final t in tagRows)
              if (t.entryId == entry.id) t,
          ],
        ),
    };
  }

  /// Entry ids whose notes or tags match [query], newest first — for
  /// app-side joins back to domain rows.
  Future<List<int>> searchEntryIds(String query) async {
    final like = '%${query.trim()}%';
    final e = entries.asDslTable;
    final t = tags.asDslTable;
    final tagMatches = _db.selectOnly(tags)
      ..addColumns([t.entryId])
      ..where(t.tag.like(like));
    final tagIds = [
      for (final row in await tagMatches.get()) row.read(t.entryId)!,
    ];
    final entryMatches = _db.selectOnly(entries)
      ..addColumns([e.id])
      ..where(e.notes.like(like) | e.id.isIn(tagIds))
      ..orderBy([OrderingTerm.desc(e.id)]);
    return [
      for (final row in await entryMatches.get()) row.read(e.id)!,
    ];
  }

  /// Every stored photo file that exists, keyed by path — the backup
  /// archive's media map.
  Future<Map<String, List<int>>> collectMedia(PhotoService store) async {
    final rows = await _db.select(photos).get();
    final media = <String, List<int>>{};
    for (final row in rows) {
      final file = store.fileFor(row.path);
      if (file.existsSync()) {
        media[row.path] = await file.readAsBytes();
      }
    }
    return media;
  }
}
