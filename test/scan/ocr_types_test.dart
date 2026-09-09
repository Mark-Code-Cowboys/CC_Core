import 'dart:math' as math;

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line on a page tilted by [skew] radians: its top follows the
/// baseline down from the row's left-edge [top].
OcrLine _tilted(
  String text, {
  required double left,
  required double width,
  required double top,
  required double skew,
  double height = 20,
}) {
  final cx = left + width / 2;
  return OcrLine(
    text,
    left: left,
    top: top + cx * math.tan(skew),
    height: height,
    width: width,
    angle: skew,
  );
}

void main() {
  group('mergeOcrRows', () {
    test('joins lines with matching vertical centers, left to right', () {
      final rows = mergeOcrRows(const [
        OcrLine('18.50', left: 300, top: 100, height: 20),
        OcrLine('BRISKET PLATE', left: 10, top: 102, height: 20),
        OcrLine('COLESLAW', left: 10, top: 140, height: 20),
      ]);
      expect(rows, ['BRISKET PLATE 18.50', 'COLESLAW']);
    });

    test('keeps distinct rows apart even when close', () {
      final rows = mergeOcrRows(const [
        OcrLine('a', left: 0, top: 0, height: 10),
        OcrLine('b', left: 0, top: 11, height: 10),
      ]);
      expect(rows, ['a', 'b']);
    });

    test('empty input yields no rows', () {
      expect(mergeOcrRows(const []), isEmpty);
    });

    test('a tilted receipt keeps each price with its name', () {
      // 3 degrees over ~600px drops the price column ~30px, more than
      // a line height — split into separate rows before tilt handling.
      final skew = 3 * math.pi / 180;
      final lines = [
        _tilted('BRISKET PLATE',
            left: 10, width: 220, top: 100, skew: skew),
        _tilted('18.50', left: 600, width: 60, top: 100, skew: skew),
        _tilted('QUESO', left: 10, width: 90, top: 140, skew: skew),
        _tilted('9.00', left: 600, width: 50, top: 140, skew: skew),
        _tilted('TOTAL', left: 10, width: 80, top: 180, skew: skew),
        _tilted('27.50', left: 600, width: 60, top: 180, skew: skew),
      ];

      expect(mergeOcrRows(lines),
          ['BRISKET PLATE 18.50', 'QUESO 9.00', 'TOTAL 27.50']);
    });

    test('a tilt the other way works too', () {
      final skew = -2.5 * math.pi / 180;
      final lines = [
        _tilted('AL PASTOR', left: 10, width: 150, top: 100, skew: skew),
        _tilted('3.50', left: 500, width: 50, top: 100, skew: skew),
        _tilted('CHURROS', left: 10, width: 130, top: 130, skew: skew),
        _tilted('6.00', left: 500, width: 50, top: 130, skew: skew),
      ];

      expect(mergeOcrRows(lines), ['AL PASTOR 3.50', 'CHURROS 6.00']);
    });
  });

  group('estimateSkew', () {
    test('is zero without angles', () {
      expect(estimateSkew(const [OcrLine('a', left: 0, top: 0, height: 1)]),
          0);
    });

    test('is the width-weighted median, so short noisy lines lose', () {
      final skew = estimateSkew(const [
        OcrLine('long', left: 0, top: 0, height: 1, width: 300, angle: 0.05),
        OcrLine('long', left: 0, top: 0, height: 1, width: 280, angle: 0.05),
        OcrLine('9.00', left: 0, top: 0, height: 1, width: 40, angle: 0.30),
        OcrLine('4.25', left: 0, top: 0, height: 1, width: 40, angle: -0.2),
      ]);
      expect(skew, 0.05);
    });

    test('ignores lines steeper than 45 degrees', () {
      final skew = estimateSkew(const [
        OcrLine('side', left: 0, top: 0, height: 1, width: 300, angle: 1.5),
        OcrLine('row', left: 0, top: 0, height: 1, width: 100, angle: 0.02),
      ]);
      expect(skew, 0.02);
    });
  });
}
