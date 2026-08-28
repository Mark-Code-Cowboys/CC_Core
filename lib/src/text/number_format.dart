import 'dart:math' as math;

/// Fixed-decimal formatting with half-to-even (banker's) rounding.
///
/// Dart's `toStringAsFixed` rounds half away from zero; domains that
/// display measured continuous values (where exact halves are rare and
/// bias matters less than stability) standardized on half-to-even in
/// the Kotlin donors, and this keeps ported goldens byte-identical.
extension DecimalString on double {
  /// This value with exactly [decimals] fraction digits, half-to-even.
  String toDecimalString(int decimals) {
    assert(decimals >= 0);
    if (decimals == 0) return _roundHalfEven(this).toString();
    final factor = math.pow(10.0, decimals).toDouble();
    final rounded = _roundHalfEven(this * factor) / factor;
    final sign = rounded < 0.0 ? '-' : '';
    final abs = rounded.abs();
    final whole = abs.truncate();
    final fracInt = _roundHalfEven((abs - whole) * factor);
    final fracStr = fracInt.toString().padLeft(decimals, '0');
    return '$sign$whole.$fracStr';
  }
}

/// IEEE roundTiesToEven, the semantics of kotlin.math.round (JVM
/// Math.rint) that the Kotlin donors formatted with.
int _roundHalfEven(double v) {
  final floor = v.floorToDouble();
  final diff = v - floor;
  if (diff > 0.5) return floor.toInt() + 1;
  if (diff < 0.5) return floor.toInt();
  final f = floor.toInt();
  return f.isEven ? f : f + 1;
}
