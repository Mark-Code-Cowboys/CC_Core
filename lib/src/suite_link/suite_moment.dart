import 'dart:convert';

/// The suite moment envelope, v1: one entry from one app ("ate here" at
/// a restaurant, a souvenir, a campsite) handed to another. JSON, UTF-8,
/// at most [maxBytes].
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
  });

  /// Envelope `format` tag.
  static const format = 'cc-suite-moment';
  /// The envelope version this code writes and the newest it reads.
  static const version = 1;
  /// Android share-intent type.
  static const mime = 'application/vnd.codecowboys.moment+json';
  /// Largest envelope a receiver takes.
  static const maxBytes = 65536;

  /// `table_encore`, `fresh_pot`, `pocket_curio`, `hitch_post`,
  /// `course_ledger`, `kick_rocks`, ...
  final String sourceApp;

  /// Stable id of the entry in its own app. The receiver updates
  /// instead of duplicating when the same (app, id) comes again.
  final String entityId;
  /// When it happened.
  final DateTime time;

  /// Headline (the restaurant), at most 200 characters.
  final String title;

  /// A line under it (the dishes).
  final String? summary;

  /// Optional; sending a location is the source app's choice.
  final double? lat;

  /// Longitude; set together with [lat] or not at all.
  final double? lng;

  /// Back to the entry in its own app (`tableencore://open/visit-12`).
  final Uri? deepLink;

  /// The envelope as JSON.
  Map<String, Object?> toJson() => {
        'format': format,
        'version': version,
        'sourceApp': sourceApp,
        'entityId': entityId,
        'time': time.toUtc().toIso8601String(),
        'title': title,
        'summary': ?summary,
        'lat': ?lat,
        'lng': ?lng,
        'deepLink': ?deepLink?.toString(),
      };

  /// The envelope as text.
  String encode() => jsonEncode(toJson());

  /// Strict parse: an unknown format or a newer version is refused;
  /// unknown extra keys are ignored (forward compatible).
  static SuiteMoment decode(String text) {
    final Object? j;
    try {
      j = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Not a suite moment');
    }
    if (j is! Map || j['format'] != format) {
      throw const FormatException('Not a suite moment');
    }
    final v = j['version'];
    if (v is! int || v > version) {
      throw const FormatException('From a newer app version');
    }
    final time = DateTime.tryParse(j['time'] as String? ?? '');
    final source = j['sourceApp'], id = j['entityId'], title = j['title'];
    if (time == null || source is! String || id is! String || title is! String) {
      throw const FormatException('Incomplete suite moment');
    }
    final lat = j['lat'], lng = j['lng'], summary = j['summary'];
    final hasPin = lat is num && lng is num;
    return SuiteMoment(
      sourceApp: source,
      entityId: id,
      time: time,
      title: title.length > 200 ? title.substring(0, 200) : title,
      summary: summary is String ? summary : null,
      lat: hasPin ? lat.toDouble() : null,
      lng: hasPin ? lng.toDouble() : null,
      deepLink: j['deepLink'] is String ? Uri.tryParse(j['deepLink'] as String) : null,
    );
  }
}
