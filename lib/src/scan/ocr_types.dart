import 'dart:math' as math;

/// One recognized text line with enough geometry to re-assemble rows.
/// Plugin-free so parsers and everything above stay widget-testable.
class OcrLine {
  /// Creates a line at ([left], [top]) with the given [height]. [width]
  /// and [angle] are optional: without them the line is treated as a
  /// point at its left edge on a level page, which is all the merge
  /// needed before tilt handling.
  const OcrLine(
    this.text, {
    required this.left,
    required this.top,
    required this.height,
    this.width = 0,
    this.angle,
  });

  /// The recognized text.
  final String text;

  /// Left edge of the bounding box, in image pixels.
  final double left;

  /// Top edge of the bounding box, in image pixels.
  final double top;

  /// Height of the bounding box, in image pixels.
  final double height;

  /// Width of the bounding box, in image pixels (0 when unknown).
  final double width;

  /// Tilt of the text baseline in radians, positive when the right end
  /// sits lower on the image than the left (image y grows downward).
  /// Null when the recognizer gave no corner geometry.
  final double? angle;

  /// Center of the bounding box.
  math.Point<double> get center =>
      math.Point(left + width / 2, top + height / 2);
}

/// The page's overall tilt: the width-weighted median of the lines'
/// own baseline angles, so a few short noisy lines ("9.00") can't pull
/// it around. Zero when no line carries an angle. Lines steeper than
/// 45 degrees are ignored as rotated or garbage text.
double estimateSkew(List<OcrLine> lines) {
  final known = [
    for (final l in lines)
      if (l.angle != null && l.width > 0 && l.angle!.abs() < math.pi / 4) l
  ]..sort((a, b) => a.angle!.compareTo(b.angle!));
  if (known.isEmpty) return 0;
  final total = known.fold(0.0, (sum, l) => sum + l.width);
  var seen = 0.0;
  for (final l in known) {
    seen += l.width;
    if (seen >= total / 2) return l.angle!;
  }
  return known.last.angle!;
}

/// OCR splits a page's columns ("BRISKET PLATE" ... "18.50") into
/// separate lines. Re-assembles visual rows: lines whose vertical
/// centers are within half a line-height of each other are one row,
/// joined left to right.
///
/// A photo taken at a slight angle (no document scanner, phone not
/// square to the receipt) tilts every row, so a price far to the right
/// sits visibly lower than its name and the two used to land in
/// different rows. Centers are first rotated back by the page's
/// [estimateSkew], which puts a tilted row's name and price on the
/// same level again. Extracted from Table Encore's receipt parser.
List<String> mergeOcrRows(List<OcrLine> lines) {
  final skew = estimateSkew(lines);
  final cosA = math.cos(skew);
  final sinA = math.sin(skew);
  // Vertical position after un-tilting the page around the origin.
  double level(OcrLine l) {
    final c = l.center;
    return c.y * cosA - c.x * sinA;
  }

  final sorted = List.of(lines)..sort((a, b) => level(a).compareTo(level(b)));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    if (rows.isNotEmpty) {
      final last = rows.last.last;
      final tolerance = ((line.height + last.height) / 2) * 0.5;
      if ((level(line) - level(last)).abs() <= tolerance) {
        rows.last.add(line);
        continue;
      }
    }
    rows.add([line]);
  }
  return [
    for (final row in rows)
      (row..sort((a, b) => a.left.compareTo(b.left)))
          .map((l) => l.text)
          .join(' '),
  ];
}
