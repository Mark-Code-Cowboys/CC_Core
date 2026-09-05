// Drift's `check(column...)` idiom trips this lint on rating columns.
// ignore_for_file: recursive_getters
import 'package:drift/drift.dart';

/// One journal entry: the story and how the day rated. Core owns these
/// tables; each app registers them in its own `@DriftDatabase` and its
/// domain rows (a visit, a round) carry a nullable `journalEntryId`
/// column pointing here. Deleting a domain row is the app's cue to
/// delete its entry (the FK points domain -> entry, so SQL can't
/// cascade that direction).
@UseRowClass(JournalEntry)
class JournalEntries extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// The story.
  TextColumn get notes => text().nullable()();

  /// 1-5 when rated.
  IntColumn get rating =>
      integer().nullable().check(rating.isBetweenValues(1, 5))();

  /// Audit timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Photos attached to an entry (the card, the view from 18). `path` is
/// a file name under the app's photo store, not an absolute path, so
/// OS container moves don't break references.
@UseRowClass(JournalPhoto)
class JournalPhotos extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Owning entry; rows cascade away with it.
  IntColumn get entryId =>
      integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();

  /// File name under the app's photo store.
  TextColumn get path => text()();

  /// Optional caption.
  TextColumn get caption => text().nullable()();
}

/// Free-form tags on an entry, unique per entry.
@UseRowClass(JournalTag)
class JournalTags extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// Owning entry; rows cascade away with it.
  IntColumn get entryId =>
      integer().references(JournalEntries, #id, onDelete: KeyAction.cascade)();

  /// The tag text.
  TextColumn get tag => text().withLength(min: 1, max: 60)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryId, tag},
      ];
}

/// The shared row type every app's codegen maps [JournalEntries] to.
class JournalEntry {
  /// Creates the row.
  const JournalEntry({
    required this.id,
    this.notes,
    this.rating,
    required this.createdAt,
  });

  /// Row id.
  final int id;

  /// The story.
  final String? notes;

  /// 1-5, or null when unrated.
  final int? rating;

  /// Audit timestamp.
  final DateTime createdAt;
}

/// The shared row type for [JournalPhotos].
class JournalPhoto {
  /// Creates the row.
  const JournalPhoto({
    required this.id,
    required this.entryId,
    required this.path,
    this.caption,
  });

  /// Row id.
  final int id;

  /// Owning entry.
  final int entryId;

  /// File name under the app's photo store.
  final String path;

  /// Optional caption ("the card").
  final String? caption;
}

/// The shared row type for [JournalTags].
class JournalTag {
  /// Creates the row.
  const JournalTag({required this.id, required this.entryId, required this.tag});

  /// Row id.
  final int id;

  /// Owning entry.
  final int entryId;

  /// The tag text.
  final String tag;
}
