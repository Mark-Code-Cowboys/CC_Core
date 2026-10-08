import 'dart:math' as math;

import 'ocr_types.dart';

/// Word gaps wider than this many line heights separate columns.
/// Ordinary word spacing stays under 0.6 of a line height; the gutter
/// between a cookbook's ingredient and instruction columns measured
/// 3.6 to 12 (Trace Elements, Pixel 9 Pro XL, October 2026).
const double ocrColumnGapFactor = 2.0;

/// Splits every line that carries [OcrLine.words] at word gaps wider
/// than [gapFactor] × the page's median line height, so a line the
/// recognizer glued across a column gutter ("2 qt water  Cook over
/// medium heat…") becomes one line per column. The page's height
/// rather than the line's own, because a stray tall glyph on one line
/// would otherwise hide a gutter that every other line shows. Lines
/// without word geometry pass through as they are.
List<OcrLine> splitOcrLinesAtGaps(
  List<OcrLine> lines, {
  double gapFactor = ocrColumnGapFactor,
}) {
  final threshold = gapFactor * _median([for (final l in lines) l.height]);
  final out = <OcrLine>[];
  for (final line in lines) {
    final words = line.words;
    if (words == null || words.length < 2) {
      out.add(line);
      continue;
    }
    final sorted = List.of(words)..sort((a, b) => a.left.compareTo(b.left));
    final runs = <List<OcrWord>>[
      [sorted.first],
    ];
    for (final w in sorted.skip(1)) {
      if (w.left - runs.last.last.right > threshold) {
        runs.add([w]);
      } else {
        runs.last.add(w);
      }
    }
    if (runs.length == 1) {
      out.add(line);
    } else {
      out.addAll([for (final run in runs) _lineFromWords(run, line)]);
    }
  }
  return out;
}

OcrLine _lineFromWords(List<OcrWord> words, OcrLine source) {
  var left = double.infinity;
  var top = double.infinity;
  var right = double.negativeInfinity;
  var bottom = double.negativeInfinity;
  for (final w in words) {
    left = math.min(left, w.left);
    top = math.min(top, w.top);
    right = math.max(right, w.right);
    bottom = math.max(bottom, w.top + w.height);
  }
  return OcrLine(
    words.map((w) => w.text).join(' '),
    left: left,
    top: top,
    width: right - left,
    height: bottom - top,
    angle: source.angle,
    words: words,
  );
}

/// A page's lines in reading order, as a person would read them, for
/// pages that are not a single column: cookbook spreads with an
/// ingredient column beside the instructions, a headnote across the
/// top, a two-column ingredient list on a card.
///
/// How it reads the page:
///
/// 1. Lines are split at column-wide word gaps ([splitOcrLinesAtGaps])
///    and the page's tilt is taken out ([estimateSkew]).
/// 2. Lines on one level form a row, as in [mergeOcrRows]; a row with
///    a column-wide gap between its lines has one segment per column.
/// 3. Consecutive rows whose segments fall into the same horizontal
///    bands form a block. A segment reaching across every band
///    (full-width prose under two columns) ends the block; one that
///    only straddles some of them shows those bands were one column
///    the recognizer had split, and they merge.
/// 4. A block whose rows pair a short label with a short value on the
///    right ("BRISKET PLATE … 18.50", "Flour ….. 2 cups") is a table
///    and reads row by row, like [mergeOcrRows]. Any other
///    multi-band block reads column by column.
/// 5. Within a column, a line indented past the column's left edge
///    that sits directly under the previous line is a wrapped
///    continuation and is joined to it ("¼ cup firmly packed" +
///    "light brown sugar").
///
/// An empty string separates columns and blocks, and paragraphs where
/// the vertical spacing shows one. Single-column pages come back as
/// their rows, so this is safe to use wherever [mergeOcrRows] was,
/// except for receipts and menus whose name/price rows it would read
/// as a table anyway.
List<String> layoutOcrLines(
  List<OcrLine> lines, {
  double gapFactor = ocrColumnGapFactor,
}) {
  if (lines.isEmpty) return const [];
  final split = splitOcrLinesAtGaps(lines, gapFactor: gapFactor);
  final skew = estimateSkew(split);
  final cosA = math.cos(skew);
  final sinA = math.sin(skew);
  final placed = [
    for (final l in split)
      _Placed(
        l,
        left: l.left * cosA + l.center.y * sinA,
        right: l.right * cosA + l.center.y * sinA,
        y: l.center.y * cosA - l.center.x * sinA,
      ),
  ]..sort((a, b) => a.y.compareTo(b.y));

  final lineHeight = _median([for (final p in placed) p.line.height]);
  final gap = gapFactor * lineHeight;
  final pageLeft = placed.map((p) => p.left).reduce(math.min);
  final pageRight = placed.map((p) => p.right).reduce(math.max);
  final pageWidth = math.max(pageRight - pageLeft, 1.0);

  // Rows, then segments within a row.
  final rows = <List<_Placed>>[];
  for (final p in placed) {
    if (rows.isNotEmpty) {
      final last = rows.last.last;
      final tolerance = ((p.line.height + last.line.height) / 2) * 0.5;
      if ((p.y - last.y).abs() <= tolerance) {
        rows.last.add(p);
        continue;
      }
    }
    rows.add([p]);
  }
  final segmentedRows = <List<_Segment>>[];
  for (final row in rows) {
    row.sort((a, b) => a.left.compareTo(b.left));
    final segments = <_Segment>[];
    for (final p in row) {
      if (segments.isNotEmpty && p.left - segments.last.right <= gap) {
        segments.last.add(p);
      } else {
        segments.add(_Segment(p));
      }
    }
    segmentedRows.add(segments);
  }

  // Blocks of rows that share horizontal bands.
  final blocks = <_Block>[];
  _Block? open;
  final slack = lineHeight * 0.5;
  for (final segments in segmentedRows) {
    if (open != null) {
      final placement = open.place(segments, slack);
      if (placement != null) {
        open.add(segments, placement);
        continue;
      }
      blocks.add(open);
    }
    open = _Block()..add(segments, List.generate(segments.length, (i) => i));
  }
  if (open != null) blocks.add(open);

  final out = <String>[];
  void blank() {
    if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
  }

  for (final block in blocks) {
    blank();
    if (block.bands.length > 1 && block.isTable(pageWidth)) {
      for (final row in block.rows) {
        out.add(row.map((s) => s.text).join(' '));
      }
      continue;
    }
    for (final band in block.bands) {
      blank();
      out.addAll(_readColumn(band.segments, lineHeight));
    }
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  while (out.isNotEmpty && out.first.isEmpty) {
    out.removeAt(0);
  }
  return out;
}

/// One column's segments top to bottom: an indented line directly
/// under the previous one that doesn't start a sentence of its own is
/// a wrapped continuation; a clear vertical gap is a paragraph break.
List<String> _readColumn(List<_Segment> input, double lineHeight) {
  if (input.isEmpty) return const [];
  final segments = List.of(input)..sort((a, b) => a.y.compareTo(b.y));
  final lefts = [for (final s in segments) s.left]..sort();
  final columnLeft = lefts[(lefts.length - 1) ~/ 5];
  final pitches = <double>[
    for (var i = 1; i < segments.length; i++) segments[i].y - segments[i - 1].y,
  ];
  // The column's line pitch: a low quantile rather than the median, so
  // a short column with one paragraph break still knows its own
  // spacing.
  final pitch = pitches.isEmpty
      ? lineHeight * 1.4
      : math.max(_quantile(pitches, 0.25), lineHeight);

  final out = <String>[];
  for (var i = 0; i < segments.length; i++) {
    final s = segments[i];
    if (i > 0) {
      final drop = s.y - segments[i - 1].y;
      final indent = s.left - columnLeft;
      final under = drop <= pitch * 1.45;
      final indented = indent >= lineHeight * 0.5 && indent <= lineHeight * 4;
      final continues =
          !RegExp(r'^[A-Z]').hasMatch(s.text) ||
          !RegExp(r'[.!?:]$').hasMatch(out.isEmpty ? '' : out.last);
      if (under &&
          indented &&
          continues &&
          out.isNotEmpty &&
          out.last.isNotEmpty) {
        out[out.length - 1] = '${out.last} ${s.text}';
        continue;
      }
      if (drop > pitch * 1.6 && out.isNotEmpty && out.last.isNotEmpty) {
        out.add('');
      }
    }
    out.add(s.text);
  }
  return out;
}

double _quantile(List<double> values, double q) {
  if (values.isEmpty) return 0;
  final sorted = List.of(values)..sort();
  return sorted[((sorted.length - 1) * q).round()];
}

double _median(List<double> values) {
  if (values.isEmpty) return 0;
  final sorted = List.of(values)..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}

class _Placed {
  _Placed(
    this.line, {
    required this.left,
    required this.right,
    required this.y,
  });

  final OcrLine line;

  /// Edges and level after un-tilting the page.
  final double left;
  final double right;
  final double y;
}

/// Lines on one row that sit within ordinary spacing of each other.
class _Segment {
  _Segment(_Placed first)
    : _parts = [first],
      left = first.left,
      right = first.right,
      y = first.y;

  final List<_Placed> _parts;
  final double left;
  double right;
  final double y;

  void add(_Placed p) {
    _parts.add(p);
    right = math.max(right, p.right);
  }

  /// Takes over [other]'s lines (to the right of this one).
  void absorb(_Segment other) {
    _parts.addAll(other._parts);
    right = math.max(right, other.right);
  }

  String get text => _parts.map((p) => p.line.text).join(' ');

  bool get startsNumeric => RegExp(r'^[\d¼½¾⅓⅔⅛$€£]').hasMatch(text.trim());

  double get width => right - left;
}

class _Band {
  _Band(_Segment first) : left = first.left, right = first.right {
    segments.add(first);
  }

  double left;
  double right;
  final segments = <_Segment>[];

  bool overlaps(_Segment s, double slack) =>
      s.left < right + slack && s.right > left - slack;

  void add(_Segment s) {
    segments.add(s);
    left = math.min(left, s.left);
    right = math.max(right, s.right);
  }
}

class _Block {
  final bands = <_Band>[];
  final rows = <List<_Segment>>[];

  /// Which band each segment of a row joins, or null when the row ends
  /// the block. A block with one band is a run of plain lines (a
  /// title, a headnote): the first row that doesn't sit inside it as
  /// one line starts the next block, so a centred title above two
  /// columns stays above them. In a block with several bands, a
  /// segment reaching across all of them (full-width prose under two
  /// columns) ends it; a segment touching no band opens a new one
  /// (index == bands.length); one straddling some bands but not all
  /// merges them first; and two segments landing in one band are a
  /// line the recognizer split and read as one.
  List<int>? place(List<_Segment> segments, double slack) {
    if (bands.length == 1) {
      if (segments.length > 1) return null;
      return _hits(segments.single, slack).isEmpty ? null : [0];
    }
    // Merge straddled bands before placing anything, so indices hold.
    for (final s in segments) {
      final hits = _hits(s, slack);
      if (hits.length > 1) {
        if (hits.first == 0 && hits.last == bands.length - 1) return null;
        _merge(hits);
      }
    }
    final result = <int>[];
    var fresh = bands.length;
    for (final s in segments) {
      final hits = _hits(s, slack);
      result.add(hits.isEmpty ? fresh++ : hits.single);
    }
    return result;
  }

  List<int> _hits(_Segment s, double slack) => [
    for (var i = 0; i < bands.length; i++)
      if (bands[i].overlaps(s, slack)) i,
  ];

  void _merge(List<int> indices) {
    final keep = bands[indices.first];
    for (final i in indices.skip(1).toList().reversed) {
      for (final seg in bands[i].segments) {
        keep.add(seg);
      }
      bands.removeAt(i);
    }
  }

  void add(List<_Segment> segments, List<int> placement) {
    final row = <_Segment>[];
    final byTarget = <int, _Segment>{};
    for (var i = 0; i < segments.length; i++) {
      final index = placement[i];
      final existing = byTarget[index];
      if (existing != null) {
        existing.absorb(segments[i]);
        continue;
      }
      byTarget[index] = segments[i];
      row.add(segments[i]);
      if (index < bands.length) {
        bands[index].add(segments[i]);
      } else {
        bands.add(_Band(segments[i]));
      }
    }
    rows.add(row);
    bands.sort((a, b) => a.left.compareTo(b.left));
  }

  /// Label/value rows: nearly every row has a cell in more than one
  /// band, no band is wide, the first band's cells don't start with a
  /// number and the last band's do. Two side-by-side ingredient
  /// columns both start numeric and read as columns instead.
  bool isTable(double pageWidth) {
    final paired = rows.where((r) => r.length > 1).length;
    if (paired < rows.length * 0.8) return false;
    for (final band in bands) {
      final widths = [for (final s in band.segments) s.width]..sort();
      if (_median(widths) > pageWidth * 0.35) return false;
    }
    double numericShare(_Band b) =>
        b.segments.where((s) => s.startsNumeric).length / b.segments.length;
    return numericShare(bands.first) <= 0.5 && numericShare(bands.last) >= 0.5;
  }
}
