import 'dart:math' as math;

import 'geo_point.dart';

/// Mean Earth radius in meters (IUGG); haversine assumes a sphere.
const double earthRadiusMeters = 6371000.0;

/// Great-circle distance in meters between two points (haversine).
///
/// Good to well under 0.5% at any distance and to centimeters at the
/// tens-of-meters scale that place matching works at.
double distanceMeters(GeoPoint a, GeoPoint b) {
  final dLat = _radians(b.lat - a.lat);
  final dLng = _radians(b.lng - a.lng);
  final h =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(_radians(a.lat)) *
          math.cos(_radians(b.lat)) *
          math.pow(math.sin(dLng / 2), 2);
  return 2 * earthRadiusMeters * math.asin(math.sqrt(h.toDouble()));
}

double _radians(double degrees) => degrees * math.pi / 180.0;
