import 'package:cc_core/cc_core.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'places_test_db.g.dart';

/// What an app's place adds on top of the core pin columns.
enum TestVenueKind { cafe, roaster }

/// A consumer place table, as an app writes it: core columns and
/// constraints inherited, one column of its own.
class TestVenues extends PinnedPlaces {
  IntColumn get kind => intEnum<TestVenueKind>()();
}

/// A consumer visit table with the app's own foreign keys.
class TestVisits extends PlaceVisits {
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY (place_id) REFERENCES test_venues (id) ON DELETE CASCADE',
    'FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) '
        'ON DELETE SET NULL',
  ];
}

@DriftDatabase(
  tables: [TestVenues, TestVisits, JournalEntries, JournalPhotos, JournalTags],
)
class PlacesTestDb extends _$PlacesTestDb {
  PlacesTestDb() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
