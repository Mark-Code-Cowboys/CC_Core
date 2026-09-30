import 'geo_point.dart';

/// Whether a confirmed on-site [fix] should replace the [stored] pin.
///
/// - No stored pin: yes — this is the backfill case, the fix becomes
///   the pin whatever its accuracy.
/// - Stored pin of unknown accuracy (recorded before accuracy was
///   tracked): yes when the fix is within [maxAccuracyM].
/// - Otherwise: yes only when the fix is strictly more accurate than
///   the pin and within [maxAccuracyM]; a worse or merely equal fix
///   never moves a pin.
///
/// [maxAccuracyM] is app policy; core has no default.
bool shouldRefinePin({
  required GeoPin? stored,
  required GeoFix fix,
  required double maxAccuracyM,
}) {
  if (stored == null) return true;
  if (fix.accuracyM > maxAccuracyM) return false;
  final storedAccuracy = stored.accuracyM;
  if (storedAccuracy == null) return true;
  return fix.accuracyM < storedAccuracy;
}
