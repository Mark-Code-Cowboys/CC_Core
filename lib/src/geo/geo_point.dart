/// Anything with WGS84 coordinates.
abstract interface class GeoPoint {
  /// Latitude in degrees, positive north.
  double get lat;

  /// Longitude in degrees, positive east.
  double get lng;
}

/// A fresh reading from the device: where it was, how sure, and when.
class GeoFix implements GeoPoint {
  /// Creates a fix. [accuracyM] is the reported horizontal accuracy
  /// radius in meters (smaller is better).
  const GeoFix({
    required this.lat,
    required this.lng,
    required this.accuracyM,
    required this.timestamp,
  });

  @override
  final double lat;

  @override
  final double lng;

  /// Horizontal accuracy radius in meters.
  final double accuracyM;

  /// When the reading was taken.
  final DateTime timestamp;

  /// True when the reading is older than [maxAge] as of [now].
  bool isStale({required Duration maxAge, DateTime? now}) =>
      (now ?? DateTime.now()).difference(timestamp) > maxAge;

  @override
  String toString() => 'GeoFix($lat, $lng, ±${accuracyM}m, $timestamp)';
}

/// A stored location on a saved place. Accuracy and capture time are
/// optional because pins recorded before the app tracked them have
/// neither; such a pin is refinable by any fix that meets the app's
/// threshold (see [shouldRefinePin]).
class GeoPin implements GeoPoint {
  /// Creates a pin. Pass [accuracyM] and [capturedAt] together or not
  /// at all.
  const GeoPin({
    required this.lat,
    required this.lng,
    this.accuracyM,
    this.capturedAt,
  }) : assert(
         (accuracyM == null) == (capturedAt == null),
         'accuracyM and capturedAt go together',
       );

  /// The pin a fix would leave behind.
  GeoPin.fromFix(GeoFix fix)
    : this(
        lat: fix.lat,
        lng: fix.lng,
        accuracyM: fix.accuracyM,
        capturedAt: fix.timestamp,
      );

  /// A pin from nullable storage columns, or null when there is no pin.
  /// Half a pin (one coordinate without the other) is treated as no
  /// pin rather than a crash, since it can only come from bad data.
  static GeoPin? tryFrom({
    required double? lat,
    required double? lng,
    double? accuracyM,
    DateTime? capturedAt,
  }) {
    if (lat == null || lng == null) return null;
    final hasMeta = accuracyM != null && capturedAt != null;
    return GeoPin(
      lat: lat,
      lng: lng,
      accuracyM: hasMeta ? accuracyM : null,
      capturedAt: hasMeta ? capturedAt : null,
    );
  }

  @override
  final double lat;

  @override
  final double lng;

  /// Horizontal accuracy of the fix that set the pin, or null when
  /// unknown.
  final double? accuracyM;

  /// When the pin was set, or null when unknown.
  final DateTime? capturedAt;

  /// True when the pin carries accuracy and capture time.
  bool get hasMetadata => accuracyM != null;

  @override
  String toString() =>
      'GeoPin($lat, $lng'
      '${accuracyM == null ? '' : ', ±${accuracyM}m'})';
}
