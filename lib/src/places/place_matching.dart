import '../geo/geo.dart';
// ignore: unused_import, for doc references.
import 'place_tables.dart';

/// An app's place-matching numbers. Core has no defaults: each app
/// decides how close is "here" (Table Encore: 75 m), how good a fix
/// must be to move a pin, and how old a fix may be.
class PlacePolicy {
  /// Creates the policy.
  const PlacePolicy({
    required this.matchRadiusM,
    required this.refineMaxAccuracyM,
    required this.maxFixAge,
  });

  /// Saved places within this distance of the fix are candidates.
  final double matchRadiusM;

  /// A confirmed on-site fix only refines a stored pin when at least
  /// this accurate (see [shouldRefinePin]).
  final double refineMaxAccuracyM;

  /// A fix older than this is not trusted.
  final Duration maxFixAge;
}

/// What looking for "where am I" produced at the start of a visit.
sealed class PlaceMatch<P> {
  const PlaceMatch();
}

/// No usable fix: [reason] says why (permission denied, timeout,
/// unavailable). The app falls back to picking or naming the place.
final class PlaceMatchNoFix<P> extends PlaceMatch<P> {
  /// Wraps the location result that wasn't a fix.
  const PlaceMatchNoFix(this.reason);

  /// Why there is no fix.
  final LocationResult reason;
}

/// A fix, and the saved places in range of it, nearest first — empty
/// when this is somewhere new.
final class PlaceMatchFound<P> extends PlaceMatch<P> {
  /// Creates the match.
  const PlaceMatchFound({required this.fix, required this.candidates});

  /// The fix the candidates were measured from; keep it to pin a new
  /// place or refine a confirmed one ([pinUpdateFor]).
  final GeoFix fix;

  /// Places within [PlacePolicy.matchRadiusM], nearest first.
  final List<GeoCandidate<P>> candidates;
}

/// One foreground fix, then the saved places in range of it: the start
/// of every "back here again?" flow. Asks [source] once (the app's
/// plugin wrapper owns permission and timeouts); [places] is only read
/// when there is a fix. Pinless places never match.
Future<PlaceMatch<P>> matchPlacesHere<P>({
  required LocationSource source,
  required PlacePolicy policy,
  required Future<List<P>> Function() places,
  required GeoPin? Function(P place) pinOf,
}) async {
  final result = await source.currentFix(maxAge: policy.maxFixAge);
  switch (result) {
    case LocationFixResult(:final fix):
      return PlaceMatchFound(
        fix: fix,
        candidates: findCandidates<P>(
          fix: fix,
          items: await places(),
          pinOf: pinOf,
          radiusM: policy.matchRadiusM,
        ),
      );
    case LocationPermissionDenied() ||
        LocationTimeout() ||
        LocationUnavailable():
      return PlaceMatchNoFix(result);
  }
}

/// The pin a confirmed on-site visit should leave on [stored], or null
/// to leave it alone: a pinless place takes the fix as its pin; a
/// pinned one only moves for a better fix within the policy's accuracy
/// threshold ([shouldRefinePin]). No fix, no change.
GeoPin? pinUpdateFor({
  required GeoPin? stored,
  required GeoFix? fix,
  required PlacePolicy policy,
}) {
  if (fix == null) return null;
  final refine = shouldRefinePin(
    stored: stored,
    fix: fix,
    maxAccuracyM: policy.refineMaxAccuracyM,
  );
  return refine ? GeoPin.fromFix(fix) : null;
}

/// The Dart side of [PinnedPlaces]' CHECK constraints, so a bad write
/// fails with a readable error instead of a SQL one: lat and lng
/// together; accuracy and capture time together, and only with a pin.
void checkPinFields({
  required double? lat,
  required double? lng,
  double? accuracyM,
  DateTime? capturedAt,
}) {
  if ((lat == null) != (lng == null)) {
    throw ArgumentError('A pin needs both lat and lng, or neither');
  }
  if ((accuracyM == null) != (capturedAt == null)) {
    throw ArgumentError(
      'Pin accuracy and capture time go together, or neither',
    );
  }
  if (lat == null && accuracyM != null) {
    throw ArgumentError('Pin accuracy without a pin');
  }
}
