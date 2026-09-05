/// One recognized text line with enough geometry to re-assemble rows.
/// Plugin-free so parsers and everything above stay widget-testable.
class OcrLine {
  /// Creates a line at ([left], [top]) with the given [height].
  const OcrLine(
    this.text, {
    required this.left,
    required this.top,
    required this.height,
  });

  /// The recognized text.
  final String text;

  /// Left edge of the bounding box, in image pixels.
  final double left;

  /// Top edge of the bounding box, in image pixels.
  final double top;

  /// Height of the bounding box, in image pixels.
  final double height;
}

/// OCR splits a page's columns ("BRISKET PLATE" ... "18.50") into
/// separate lines. Re-assembles visual rows: lines whose vertical
/// centers are within half a line-height of each other are one row,
/// joined left to right. Extracted from Table Encore's receipt parser.
List<String> mergeOcrRows(List<OcrLine> lines) {
  final sorted = List.of(lines)
    ..sort((a, b) => (a.top + a.height / 2).compareTo(b.top + b.height / 2));
  final rows = <List<OcrLine>>[];
  for (final line in sorted) {
    final center = line.top + line.height / 2;
    if (rows.isNotEmpty) {
      final last = rows.last.last;
      final lastCenter = last.top + last.height / 2;
      final tolerance = ((line.height + last.height) / 2) * 0.5;
      if ((center - lastCenter).abs() <= tolerance) {
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
