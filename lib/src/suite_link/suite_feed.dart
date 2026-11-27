import 'dart:convert';
import 'dart:math';

import '../paywall/kv_store.dart';
import 'suite_moment.dart';
import 'suite_transport.dart';

/// A sibling app's link to Kick Rocks: entries logged here show up on
/// the Kick Rocks trip they happened during.
///
/// - [feed] after every save: quiet, when the user leaves "Add to Kick
///   Rocks automatically" on (the default) and Kick Rocks is installed.
///   Never throws, never blocks the save. Kick Rocks files it on the trip
///   it happened during and drops it if there's none.
/// - [send] from a "Send to Kick Rocks" button: opens Kick Rocks with
///   the entry, whatever the setting.
/// - [listenForOpens] for Kick Rocks' "Open in ..." back-links.
/// - [listenForDrafts] for Kick Rocks' "Log this in …": it hands over a
///   moment (time, note, pin) for the app to pre-fill a new entry with.
///   Save that entry inside [fromDraft] and Kick Rocks links its moment
///   to the entry instead of adding a second one.
///
/// Entity ids go out namespaced by install (`visit-12~k3f9qa`): after a
/// reinstall the app's ids start over at 1, and without this a new
/// `visit-1` would overwrite the old one in Kick Rocks.
class SuiteFeed {
  /// [transport] and [store] are swapped for fakes in tests.
  SuiteFeed({
    required this.sourceApp,
    required this.scheme,
    SuiteTransport transport = const MethodChannelSuiteTransport(),
    KeyValueStore? store,
    DateTime Function()? clock,
  })  : _transport = transport, // ignore: prefer_initializing_formals
        _store = store ?? SharedPrefsStore(),
        _now = clock ?? DateTime.now;

  /// This app's envelope id (`table_encore`).
  final String sourceApp;

  /// This app's deep-link scheme (`tableencore`), for back-links.
  final String scheme;

  final SuiteTransport _transport;
  final KeyValueStore _store;
  final DateTime Function() _now;
  final _lastSend = <String, DateTime>{};

  /// Prod first; the dev build is how Kick Rocks is tested before it ships.
  static const kickRocksPackages = [
    'com.codecowboys.kickrocks',
    'com.codecowboys.kickrocks.dev',
  ];

  /// Where the "Add to Kick Rocks automatically" switch is stored.
  static const autoKey = 'cc_suite_auto_kick_rocks';

  /// Where this install's namespace is stored.
  static const installKey = 'cc_suite_install_id';

  /// An app's own entity id: short, URL-safe, no `~`.
  static final localIdPattern = RegExp(r'^[A-Za-z0-9._-]{1,100}$');

  /// A back-link whose entry is within this of the link's time is the
  /// same entry, even from another install (a backup restored on a new
  /// phone keeps ids and times).
  static const sameEntryTolerance = Duration(hours: 36);

  /// The switch; on unless the user turned it off.
  Future<bool> autoSend() async => await _store.getBool(autoKey) ?? true;

  /// Flips the switch.
  Future<void> setAutoSend(bool on) => _store.setBool(autoKey, on);

  /// Whether either Kick Rocks build is on the phone. Asks every time
  /// (it can be installed or removed while this app runs).
  Future<bool> kickRocksInstalled() async =>
      await _transport.installed(kickRocksPackages) != null;

  /// This install's namespace: six random characters, made once.
  Future<String> installId() async {
    final have = await _store.getString(installKey);
    if (have != null && RegExp(r'^[a-z0-9]{6}$').hasMatch(have)) return have;
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final r = Random.secure();
    final id = String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(r.nextInt(chars.length))));
    await _store.setString(installKey, id);
    return id;
  }

  /// The envelope for one of this app's entries. [entityId] is the app's
  /// own id (`visit-12`). With [dateOnly], only [time]'s day counts: use
  /// it when the user picked a date but no time, instead of inventing a
  /// clock time that may fall outside the trip.
  SuiteMoment moment({
    required String entityId,
    required DateTime time,
    required String title,
    String? summary,
    double? lat,
    double? lng,
    bool dateOnly = false,
  }) {
    final t = title.trim().isEmpty ? 'Untitled' : title.trim();
    var s = summary?.trim();
    if (s != null && s.isEmpty) s = null;
    final pin = lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat.abs() <= 90 &&
        lng.abs() <= 180 &&
        !(lat == 0 && lng == 0);
    return SuiteMoment(
      sourceApp: sourceApp,
      entityId: entityId,
      time: dateOnly ? DateTime(time.year, time.month, time.day) : time,
      title: SuiteMoment.clip(t, SuiteMoment.maxTitle),
      summary: s == null ? null : SuiteMoment.clip(s, SuiteMoment.maxSummary),
      lat: pin ? lat : null,
      lng: pin ? lng : null,
      dateOnly: dateOnly,
    );
  }

  SuiteDraft? _saving;

  /// Calls [onDraft] for each "Log this in …" from Kick Rocks: the one
  /// the app was opened with, then any that arrive later. Anything that
  /// isn't a well-formed Kick Rocks envelope is ignored. Call once, where
  /// the app can open its new-entry screen.
  Future<void> listenForDrafts(void Function(SuiteDraft draft) onDraft) async {
    void handle(String text) {
      final d = SuiteDraft.tryParse(text);
      if (d != null) onDraft(d);
    }

    _transport.onDraft(handle);
    final first = await _transport.initialDraft();
    if (first != null) handle(first);
  }

  /// Runs [save] (the app's normal save of the entry pre-filled from
  /// [draft]); a [feed] or [send] started while it runs says the entry
  /// came from [draft]'s Kick Rocks moment.
  Future<T> fromDraft<T>(SuiteDraft draft, Future<T> Function() save) async {
    _saving = draft;
    try {
      return await save();
    } finally {
      if (identical(_saving, draft)) _saving = null;
    }
  }

  /// Quiet handoff after a save. True when Kick Rocks took it.
  Future<bool> feed(SuiteMoment m) async {
    final from = _saving?.momentId; // before any await: the save's own feed
    try {
      if (!await autoSend()) return false;
      final text = await _wire(m, fromMoment: from);
      if (text == null) return false;
      return await _transport.deliver(text, kickRocksPackages) != null;
    } on Object {
      return false;
    }
  }

  /// "Send to Kick Rocks": opens it with the entry. False when it isn't
  /// installed (or is too old to take entries). A second tap on the same
  /// entry within two seconds is ignored (reported as sent).
  Future<bool> send(SuiteMoment m) async {
    final from = _saving?.momentId;
    try {
      final now = _now();
      final last = _lastSend[m.entityId];
      if (last != null && now.difference(last).abs() < const Duration(seconds: 2)) {
        return true;
      }
      _lastSend[m.entityId] = now;
      final text = await _wire(m, fromMoment: from);
      if (text == null) return false;
      return await _transport.share(text, kickRocksPackages) != null;
    } on Object {
      return false;
    }
  }

  /// Calls [open] with the app's own entity id for each back-link into
  /// this app (`<scheme>://open/<id>~<install>?at=...`, Kick Rocks'
  /// "Open in ..."): the one it was launched with, then any that arrive
  /// later. A link that arrived before this was called (during
  /// onboarding) is delivered now. Call once, where the app can show the
  /// entry.
  ///
  /// A link from another install of this app is checked with [timeOf]
  /// (the entry's time, null when it's gone): after a reinstall, ids
  /// start over and `visit-3` may now be a different meal. A link that
  /// doesn't check out goes to [missing] instead of [open].
  Future<void> listenForOpens(
    void Function(String entityId) open, {
    Future<DateTime?> Function(String entityId)? timeOf,
    void Function(String entityId)? missing,
  }) async {
    final mine = await installId();

    Future<void> handle(String link) async {
      final u = Uri.tryParse(link);
      if (u == null || u.scheme != scheme || u.host != 'open') return;
      if (u.pathSegments.length != 1) return;
      final raw = u.pathSegments.single;
      final cut = raw.indexOf('~');
      final id = cut < 0 ? raw : raw.substring(0, cut);
      final inst = cut < 0 ? null : raw.substring(cut + 1);
      if (!localIdPattern.hasMatch(id)) return;
      if (inst == null || inst == mine || timeOf == null) return open(id);
      final at = int.tryParse(u.queryParameters['at'] ?? '');
      final t = await timeOf(id);
      final same = at != null &&
          t != null &&
          t.difference(DateTime.fromMillisecondsSinceEpoch(at)).abs() <=
              sameEntryTolerance;
      same ? open(id) : missing?.call(id);
    }

    _transport.onOpen((link) => handle(link));
    final first = await _transport.initialOpen();
    if (first != null) await handle(first);
  }

  /// The envelope as sent: namespaced id, back-link with the time.
  Future<String?> _wire(SuiteMoment m, {String? fromMoment}) async {
    if (!localIdPattern.hasMatch(m.entityId)) return null;
    final ns = '${m.entityId}~${await installId()}';
    final wired = SuiteMoment(
      sourceApp: m.sourceApp,
      entityId: ns,
      time: m.time,
      title: m.title,
      summary: m.summary,
      lat: m.lat,
      lng: m.lng,
      dateOnly: m.dateOnly,
      fromMoment: fromMoment ?? m.fromMoment,
      deepLink: Uri(
        scheme: scheme,
        host: 'open',
        pathSegments: [ns],
        queryParameters: {'at': '${m.time.millisecondsSinceEpoch}'},
      ),
    );
    final text = wired.encode();
    return utf8.encode(text).length <= SuiteMoment.maxBytes ? text : null;
  }
}

/// A Kick Rocks moment handed over by "Log this in …", for the app to
/// pre-fill a new entry with. Nothing is saved until the user saves.
class SuiteDraft {
  /// See the fields.
  const SuiteDraft({
    required this.momentId,
    required this.time,
    required this.note,
    this.tripName,
    this.lat,
    this.lng,
    this.dateOnly = false,
  });

  /// The Kick Rocks moment's id.
  final String momentId;

  /// When the moment happened (local midnight with [dateOnly]).
  final DateTime time;

  /// Only the day is known.
  final bool dateOnly;

  /// What the user wrote in Kick Rocks; null when they wrote nothing.
  final String? note;

  /// The trip it's on, when it's on one.
  final String? tripName;

  /// Where it happened, when Kick Rocks knows.
  final double? lat;

  /// Longitude; set together with [lat] or not at all.
  final double? lng;

  /// Whether there's a pin.
  bool get hasPin => lat != null && lng != null;

  /// The title Kick Rocks sends for a moment with no note.
  static const untitled = 'A moment from Kick Rocks';

  /// [text] as a draft, or null when it isn't a valid envelope from
  /// Kick Rocks (hostile input: any app could send one).
  static SuiteDraft? tryParse(String text) {
    final SuiteMoment m;
    try {
      m = SuiteMoment.decode(text);
    } on Object {
      return null;
    }
    if (m.sourceApp != 'kick_rocks') return null;
    final note = m.title == untitled ? null : m.title;
    return SuiteDraft(
      momentId: m.entityId,
      time: m.dateOnly ? m.time : m.time.toLocal(),
      dateOnly: m.dateOnly,
      note: note,
      tripName: m.summary,
      lat: m.lat,
      lng: m.lng,
    );
  }
}
