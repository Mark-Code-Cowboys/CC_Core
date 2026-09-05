/// journal module of cc_core: the shared journal tables every CC app
/// registers in its own database (entries with notes/rating, photos,
/// tags — domain rows point at entries via a nullable journalEntryId),
/// a database-generic repository over them, the photo file store, and
/// the composer photo strip.
library;

export 'journal_repository.dart';
export 'journal_tables.dart';
export 'photo_attachment_strip.dart';
export 'photo_store.dart';
