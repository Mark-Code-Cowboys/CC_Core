import 'distance.dart';
import 'geo_point.dart';

/// One saved item that lies within the search radius of a fix.
class GeoCandidate<T> {
  /// Creates a candidate.
  const GeoCandidate({required this.item, required this.distanceM});

  /// The app's own object (restaurant, campground, course...).
  final T item;

  /// Meters from the fix to the item's pin.
  final double distanceM;

  @override
  String toString() => 'GeoCandidate(${distanceM.toStringAsFixed(1)}m, $item)';
}

/// Every pinned item within [radiusM] of [fix], nearest first.
///
/// Generic so core never learns an app's model: [pinOf] reads the
/// item's pin, returning null for items that have none — those are
/// never candidates. The radius is inclusive: an item exactly
/// [radiusM] away is in. Ties keep the items' input order.
List<GeoCandidate<T>> findCandidates<T>({
  required GeoPoint fix,
  required Iterable<T> items,
  required GeoPin? Function(T item) pinOf,
  required double radiusM,
}) {
  final found = <GeoCandidate<T>>[];
  for (final item in items) {
    final pin = pinOf(item);
    if (pin == null) continue;
    final d = distanceMeters(fix, pin);
    if (d <= radiusM) found.add(GeoCandidate(item: item, distanceM: d));
  }
  // List.sort is stable in Dart, so equal distances stay in input order.
  found.sort((a, b) => a.distanceM.compareTo(b.distanceM));
  return found;
}
