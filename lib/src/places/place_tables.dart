import 'package:drift/drift.dart';

/// A saved place with an optional pin — a restaurant, a café, a
/// campground. Core owns the pin columns and the rules that keep a pin
/// whole; the app subclasses this in its own schema and adds what its
/// places need (a city, a kind):
///
/// ```dart
/// class Venues extends PinnedPlaces {
///   IntColumn get kind => intEnum<VenueKind>()();
/// }
/// ```
///
/// The pin is where the phone was when the user confirmed being there
/// (see [shouldRefinePin]); a place saved away from it has none and
/// gets one on its next confirmed on-site visit.
///
/// The CHECK constraints come with the subclass. An app that needs
/// constraints of its own must override [customConstraints] and repeat
/// these three — drift reads the list literally.
abstract class PinnedPlaces extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// What the place is called.
  TextColumn get name => text().withLength(min: 1, max: 120)();

  /// Pin latitude; null for a pinless place.
  RealColumn get lat => real().nullable()();

  /// Pin longitude; null for a pinless place.
  RealColumn get lng => real().nullable()();

  /// Accuracy of the fix that set the pin, so a better fix can refine
  /// it; null when unknown.
  RealColumn get pinAccuracyM => real().nullable()();

  /// When the pin was set; travels with [pinAccuracyM].
  DateTimeColumn get pinCapturedAt => dateTime().nullable()();

  /// Audit timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Pin invariants, enforced by SQLite so no code path can store half
  /// a pin: lat and lng together; accuracy and capture time together
  /// and only alongside a pin. [checkPinFields] is the Dart side.
  @override
  List<String> get customConstraints => [
    'CHECK ((lat IS NULL) = (lng IS NULL))',
    'CHECK ((pin_accuracy_m IS NULL) = (pin_captured_at IS NULL))',
    'CHECK (lat IS NOT NULL OR pin_accuracy_m IS NULL)',
  ];
}

/// One visit to a [PinnedPlaces] place. The visit's story lives in the
/// journal tables, as with every other domain row. Items had there
/// (dishes, drinks) are the app's own table pointing at the visit.
///
/// Core can't know the place table's name, so the foreign keys are the
/// app's: override [customConstraints] in the subclass —
///
/// ```dart
/// class CafeVisits extends PlaceVisits {
///   @override
///   List<String> get customConstraints => [
///     'FOREIGN KEY (place_id) REFERENCES venues (id) ON DELETE CASCADE',
///     'FOREIGN KEY (journal_entry_id) REFERENCES journal_entries (id) '
///         'ON DELETE SET NULL',
///   ];
/// }
/// ```
abstract class PlaceVisits extends Table {
  /// Row id.
  IntColumn get id => integer().autoIncrement()();

  /// The place visited.
  IntColumn get placeId => integer()();

  /// When the visit happened.
  DateTimeColumn get visitedAt => dateTime()();

  /// The visit's journal entry (notes, rating, photos), if it has one.
  IntColumn get journalEntryId => integer().nullable()();
}
