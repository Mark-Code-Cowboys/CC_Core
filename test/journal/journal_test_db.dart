import 'package:cc_core/cc_core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'journal_test_db.g.dart';

/// A minimal consumer database, registering the journal tables exactly
/// as apps do — proves the @UseRowClass wiring and gives the repo
/// tests a real schema.
@DriftDatabase(tables: [JournalEntries, JournalPhotos, JournalTags])
class JournalTestDb extends _$JournalTestDb {
  JournalTestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
