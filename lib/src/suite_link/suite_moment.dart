import 'dart:convert';

/// The suite moment envelope, v1: one entry from one app ("ate here" at
/// a restaurant, a souvenir, a campsite) handed to another. JSON, UTF-8,
/// at most [maxBytes].
///
/// [decode] treats its input as hostile: any app on the phone can share
/// text into Kick Rocks, so every field is type-, range- and size-checked
/// and anything off is a [FormatException] (never a TypeError).
class SuiteMoment {
  /// One entry; see the fields.
  const SuiteMoment({
    required this.sourceApp,
    required this.entityId,
    required this.time,
    required this.title,
    this.summary,
    this.lat,
    this.lng,
    this.deepLink,
    this.dateOnly = false,
    this.fromMoment,
  });

  /// Envelope `format` tag.
  static const format = 'cc-suite-moment';

  /// The envelope version this code writes and the newest it reads.
  static const version = 1;

  /// Android share-intent type.
  static const mime = 'application/vnd.codecowboys.moment+json';

  /// Largest envelope a receiver takes.
  static const maxBytes = 65536;

  /// Longest title kept (in characters).
  static const maxTitle = 200;

  /// Longest summary kept (in characters).
  static const maxSummary = 500;

  /// `sourceApp` shape: short snake_case.
  static final appPattern = RegExp(r'^[a-z][a-z0-9_]{1,39}$');

  /// `entityId` shape: short and URL-safe. `~` separates the per-install
  /// namespace SuiteFeed adds.
  static final idPattern = RegExp(r'^[A-Za-z0-9._~-]{1,120}$');

  /// `table_encore`, `fresh_pot`, `pocket_curio`, `hitch_post`,
  /// `course_ledger`, `kick_rocks`, ...
  final String sourceApp;

  /// Stable id of the entry in its own app. The receiver updates
  /// instead of duplicating when the same (app, id) comes again.
  final String entityId;

  /// When it happened. With [dateOnly], local midnight of that day.
  final DateTime time;

  /// Headline (the restaurant), at most [maxTitle] characters.
  final String title;

  /// A line under it (the dishes), at most [maxSummary] characters.
  final String? summary;

  /// Optional; sending a location is the source app's choice.
  final double? lat;

  /// Longitude; set together with [lat] or not at all.
  final double? lng;

  /// Back to the entry in its own app (`tableencore://open/visit-12`).
  final Uri? deepLink;

  /// Only the day is known (a date picked without a time): the receiver
  /// matches a trip that day instead of a clock time. v1 readers that
  /// predate it ignore the key.
  final bool dateOnly;

  /// The Kick Rocks moment this entry was logged from ("Log this in…"),
  /// so Kick Rocks links that moment instead of adding a second one.
  /// Same shape as [entityId]. v1 readers that predate it ignore it.
  final String? fromMoment;

  /// The envelope as JSON.
  Map<String, Object?> toJson() => {
        'format': format,
        'version': version,
        'sourceApp': sourceApp,
        'entityId': entityId,
        'time': dateOnly ? ymd(time) : time.toUtc().toIso8601String(),
        'title': title,
        'summary': ?summary,
        'lat': ?lat,
        'lng': ?lng,
        'deepLink': ?deepLink?.toString(),
        if (dateOnly) 'dateOnly': true,
        'fromMoment': ?fromMoment,
      };

  /// The envelope as text.
  String encode() => jsonEncode(toJson());

  /// `2026-11-24` for [d]'s calendar day.
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// [s] cut to [max] characters (runes) without splitting an emoji.
  static String clip(String s, int max) {
    final runes = s.runes;
    if (runes.length <= max) return s;
    return '${String.fromCharCodes(runes.take(max - 1))}…';
  }

  /// Strict parse: an unknown format, a wrong type, an out-of-range
  /// coordinate or a malformed id is refused; a newer version is a
  /// [NewerSuiteVersion]; unknown extra keys are ignored.
  static SuiteMoment decode(String text) {
    if (text.length > maxBytes) throw const FormatException('Too big');
    final Object? j;
    try {
      j = jsonDecode(text);
    } on Object {
      throw const FormatException('Not a suite moment');
    }
    if (j is! Map || j['format'] != format) {
      throw const FormatException('Not a suite moment');
    }
    final v = j['version'];
    if (v is! int || v < 1) throw const FormatException('Not a suite moment');
    if (v > version) throw const NewerSuiteVersion();

    final source = j['sourceApp'], id = j['entityId'], title = j['title'];
    if (source is! String || !appPattern.hasMatch(source)) {
      throw const FormatException('Bad sourceApp');
    }
    if (id is! String || !idPattern.hasMatch(id)) {
      throw const FormatException('Bad entityId');
    }
    if (title is! String || title.trim().isEmpty) {
      throw const FormatException('Missing title');
    }
    final dateOnly = j['dateOnly'] == true;
    final rawTime = j['time'];
    if (rawTime is! String || rawTime.length > 40) {
      throw const FormatException('Bad time');
    }
    DateTime? time;
    if (dateOnly) {
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(rawTime);
      if (m != null) {
        final y = int.parse(m[1]!), mo = int.parse(m[2]!), d = int.parse(m[3]!);
        final t = DateTime(y, mo, d);
        if (t.month == mo && t.day == d) time = t; // rejects 2026-02-31
      }
    } else {
      time = DateTime.tryParse(rawTime);
    }
    if (time == null || time.year < 1970 || time.year > 2200) {
      throw const FormatException('Bad time');
    }

    final lat = j['lat'], lng = j['lng'];
    double? la, lo;
    if (lat != null || lng != null) {
      if (lat is! num || lng is! num) {
        throw const FormatException('Bad location');
      }
      la = lat.toDouble();
      lo = lng.toDouble();
      if (!la.isFinite || !lo.isFinite || la.abs() > 90 || lo.abs() > 180) {
        throw const FormatException('Bad location');
      }
    }
    final summary = j['summary'];
    if (summary != null && summary is! String) {
      throw const FormatException('Bad summary');
    }
    final from = j['fromMoment'];
    if (from != null && (from is! String || !idPattern.hasMatch(from))) {
      throw const FormatException('Bad fromMoment');
    }
    final link = j['deepLink'];
    if (link != null && link is! String) {
      throw const FormatException('Bad deepLink');
    }

    return SuiteMoment(
      sourceApp: source,
      entityId: id,
      time: time,
      title: clip(title.trim(), maxTitle),
      summary: summary is String && summary.trim().isNotEmpty
          ? clip(summary.trim(), maxSummary)
          : null,
      lat: la,
      lng: lo,
      deepLink:
          link is String && link.length <= 2048 ? Uri.tryParse(link) : null,
      dateOnly: dateOnly,
      fromMoment: from as String?,
    );
  }
}

/// The envelope is from a newer version of the format: keep it and try
/// again once this app updates, rather than throwing it away.
class NewerSuiteVersion extends FormatException {
  /// See the class.
  const NewerSuiteVersion() : super('From a newer app version');
}
