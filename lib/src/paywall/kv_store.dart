import 'package:shared_preferences/shared_preferences.dart';

/// Tiny key-value persistence behind an interface so entitlement caches
/// (and other small app state) stay widget-testable without the
/// shared_preferences plugin.
abstract class KeyValueStore {
  /// Reads a bool, null when the key has never been written.
  Future<bool?> getBool(String key);

  /// Reads an int, null when the key has never been written.
  Future<int?> getInt(String key);

  /// Writes a bool.
  Future<void> setBool(String key, bool value);

  /// Writes an int.
  Future<void> setInt(String key, int value);
}

/// [KeyValueStore] backed by the shared_preferences plugin — the store
/// apps use in production.
class SharedPrefsStore implements KeyValueStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<bool?> getBool(String key) async => (await _prefs).getBool(key);

  @override
  Future<int?> getInt(String key) async => (await _prefs).getInt(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      (await _prefs).setBool(key, value);

  @override
  Future<void> setInt(String key, int value) async =>
      (await _prefs).setInt(key, value);
}

/// Plugin-free [KeyValueStore] for tests and previews.
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, Object> _data = {};

  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<int?> getInt(String key) async => _data[key] as int?;

  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _data[key] = value;
}
