import 'geo_point.dart';

/// What asking the device for its location produced.
sealed class LocationResult {
  const LocationResult();
}

/// A usable fix.
final class LocationFixResult extends LocationResult {
  /// Wraps [fix].
  const LocationFixResult(this.fix);

  /// The reading.
  final GeoFix fix;
}

/// The user has not granted location permission (or has revoked it).
final class LocationPermissionDenied extends LocationResult {
  /// Creates the result.
  const LocationPermissionDenied();
}

/// No fix arrived before the caller's deadline.
final class LocationTimeout extends LocationResult {
  /// Creates the result.
  const LocationTimeout();
}

/// Location is off, unsupported here, or the only fix on hand is too
/// old to trust.
final class LocationUnavailable extends LocationResult {
  /// Creates the result.
  const LocationUnavailable();
}

/// The device-location seam. Core ships no implementation; each app
/// wraps its own plugin (Table Encore: geolocator) and tests use
/// [FakeLocationSource].
abstract interface class LocationSource {
  /// The current fix, or why there is none. A fix older than [maxAge]
  /// must be reported as [LocationUnavailable], not handed back stale.
  Future<LocationResult> currentFix({required Duration maxAge});
}
