import 'dart:async';

import 'kv_store.dart';

/// How many of the gated subject have ever been created on this device.
/// Deleting never lowers it, so a [FreeLimit] fed from this tally counts
/// creations rather than current rows and a free slot can't be recycled
/// by delete-and-re-add.
///
/// Extracted from Table Encore's `RestaurantTally`; the storage [key] is
/// injected so every app keeps its own figure (and its historical key).
///
/// The stored figure is floored at the live row count whenever it is
/// bumped (see [recordCreated]) and readers should take the larger of
/// the two, so installs that predate the tally start out correct instead
/// of at zero. Backups should carry it along ([raiseTo] on restore) so
/// moving phones doesn't reset the free tier.
class LifetimeTally {
  /// Creates the tally over [_store], persisted under [key].
  LifetimeTally(this._store, {required this.key});

  /// Storage key, stable for the life of the app
  /// (e.g. `'restaurants_created_lifetime'`).
  final String key;

  final KeyValueStore _store;
  final _changes = StreamController<int>.broadcast();

  /// The persisted count; zero when nothing was ever recorded.
  Future<int> value() async => await _store.getInt(key) ?? 0;

  /// Records one creation. [liveCount] is the row count after the
  /// insert, which the tally can never sit below.
  Future<int> recordCreated({required int liveCount}) async {
    final stored = await value() + 1;
    final n = stored > liveCount ? stored : liveCount;
    await _store.setInt(key, n);
    _changes.add(n);
    return n;
  }

  /// Lifts the tally to [n] if it is currently lower (a restored
  /// backup's figure). Never lowers it.
  Future<int> raiseTo(int n) async {
    final current = await value();
    if (n <= current) return current;
    await _store.setInt(key, n);
    _changes.add(n);
    return n;
  }

  /// Current value, then every change.
  Stream<int> watch() async* {
    yield await value();
    yield* _changes.stream;
  }

  /// Closes the change stream.
  void dispose() => _changes.close();
}
