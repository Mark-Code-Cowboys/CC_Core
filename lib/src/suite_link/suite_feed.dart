import 'dart:convert';

import '../paywall/kv_store.dart';
import 'suite_moment.dart';
import 'suite_transport.dart';

/// A sibling app's link to Kick Rocks: entries logged here show up on
/// the Kick Rocks trip they happened during.
///
/// - [feed] after every save: quiet, when the user leaves "Add to Kick
///   Rocks automatically" on (the default) and Kick Rocks is installed.
///   Never throws, never blocks the save.
/// - [send] from a "Send to Kick Rocks" button: opens Kick Rocks with
///   the entry, whatever the setting.
class SuiteFeed {
  /// [transport] and [store] are swapped for fakes in tests.
  SuiteFeed({
    required this.sourceApp,
    required this.scheme,
    SuiteTransport transport = const MethodChannelSuiteTransport(),
    KeyValueStore? store,
  })  : _transport = transport, // ignore: prefer_initializing_formals
        _store = store ?? SharedPrefsStore();

  /// This app's envelope id (`table_encore`).
  final String sourceApp;

  /// This app's deep-link scheme (`tableencore`), for back-links.
  final String scheme;

  final SuiteTransport _transport;
  final KeyValueStore _store;

  /// Prod first; the dev build is how Kick Rocks is tested before it ships.
  static const kickRocksPackages = [
    'com.codecowboys.kickrocks',
    'com.codecowboys.kickrocks.dev',
  ];

  /// Where the "Add to Kick Rocks automatically" switch is stored.
  static const autoKey = 'cc_suite_auto_kick_rocks';

  /// The switch; on unless the user turned it off.
  Future<bool> autoSend() async => await _store.getBool(autoKey) ?? true;

  /// Flips the switch.
  Future<void> setAutoSend(bool on) => _store.setBool(autoKey, on);

  /// Whether either Kick Rocks build is on the phone.
  Future<bool> kickRocksInstalled() async =>
      await _transport.installed(kickRocksPackages) != null;

  /// The envelope for one of this app's entries.
  SuiteMoment moment({
    required String entityId,
    required DateTime time,
    required String title,
    String? summary,
    double? lat,
    double? lng,
  }) {
    final t = title.trim().isEmpty ? 'Untitled' : title.trim();
    var s = summary?.trim();
    if (s != null && s.isEmpty) s = null;
    if (s != null && s.length > 500) s = '${s.substring(0, 499)}…';
    return SuiteMoment(
      sourceApp: sourceApp,
      entityId: entityId,
      time: time,
      title: t.length > 200 ? t.substring(0, 200) : t,
      summary: s,
      lat: lat != null && lng != null ? lat : null,
      lng: lat != null && lng != null ? lng : null,
      deepLink: Uri.parse('$scheme://open/$entityId'),
    );
  }

  /// Quiet handoff after a save. True when Kick Rocks took it.
  Future<bool> feed(SuiteMoment m) async {
    try {
      if (!await autoSend()) return false;
      final text = _bounded(m);
      if (text == null) return false;
      return await _transport.deliver(text, kickRocksPackages) != null;
    } on Object {
      return false;
    }
  }

  /// "Send to Kick Rocks": opens it with the entry. False when it isn't
  /// installed (or is too old to take entries).
  Future<bool> send(SuiteMoment m) async {
    try {
      final text = _bounded(m);
      if (text == null) return false;
      return await _transport.share(text, kickRocksPackages) != null;
    } on Object {
      return false;
    }
  }

  /// Calls [open] with the entity id of each back-link into this app
  /// (`<scheme>://open/<id>`, Kick Rocks' "Open in ..."): the one it was
  /// launched with, then any that arrive later. Call once at startup.
  Future<void> listenForOpens(void Function(String entityId) open) async {
    String? idOf(String link) {
      final u = Uri.tryParse(link);
      if (u == null || u.scheme != scheme || u.host != 'open') return null;
      final id = u.pathSegments.isEmpty ? '' : u.pathSegments.first;
      return id.isEmpty ? null : id;
    }

    _transport.onOpen((link) {
      final id = idOf(link);
      if (id != null) open(id);
    });
    final first = await _transport.initialOpen();
    final id = first == null ? null : idOf(first);
    if (id != null) open(id);
  }

  String? _bounded(SuiteMoment m) {
    final text = m.encode();
    return utf8.encode(text).length <= SuiteMoment.maxBytes ? text : null;
  }
}
