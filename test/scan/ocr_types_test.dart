import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

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
  });
}
