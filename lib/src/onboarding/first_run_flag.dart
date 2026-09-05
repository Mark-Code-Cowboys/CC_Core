import '../paywall/kv_store.dart';

/// Whether the first-run flow has been completed on this device.
/// Persisted via [KeyValueStore] so it survives restarts; backups do
/// not carry it — a fresh phone greets the user again.
class FirstRunFlag {
  /// Creates the flag over [store].
  FirstRunFlag(this._store, {this.key = 'onboarding.seen'});

  /// Storage key, stable for the life of the app.
  final String key;

  final KeyValueStore _store;

  /// True once [markSeen] has run on this device.
  Future<bool> seen() async => await _store.getInt(key) == 1;

  /// Records that onboarding is done.
  Future<void> markSeen() => _store.setInt(key, 1);
}
