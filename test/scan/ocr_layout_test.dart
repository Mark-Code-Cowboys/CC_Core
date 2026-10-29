import 'dart:math' as math;

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// A line of [text] at ([left], [top]) whose words are laid out with
/// ordinary spacing, except that the word after [gapBefore] starts
/// [gapWidth] pixels further on. [boxHeight] stands in for the upright
/// box of a long line on a tilted or curved page, taller than its words.
OcrLine _line(
  String text, {
  required double left,
  required double top,
  double height = 20,
  double? boxHeight,
  int? gapBefore,
  double gapWidth = 0,
  double? angle,
}) {
  final words = <OcrWord>[];
  var x = left;
  final parts = text.split(' ');
  for (var i = 0; i < parts.length; i++) {
    if (i == gapBefore) x += gapWidth;
    final w = parts[i].length * 10.0;
    words.add(OcrWord(parts[i], left: x, top: top, width: w, height: height));
    x += w + 8;
  }
  return OcrLine(
    text,
    left: left,
    top: top,
    height: boxHeight ?? height,
    width: words.last.right - left,
    angle: angle,
    words: words,
  );
}

/// ML Kit's lines for a typed recipe card (Grandma's Molasses Cookies),
/// recorded on the Pixel 7 emulator, October 2026: a duplicated "2"
/// beside "2 eggs", and an italic "1 tsp. cinnamon" set in from the
/// "2 tsp soda" above it.
const _molassesCard = [
  OcrLine(
    'Grandma\'s Molasses Cookies',
    left: 31.0,
    top: 41.0,
    width: 932.0,
    height: 60.0,
    angle: 0.0086,
    words: [
      OcrWord('Grandma\'s', left: 31.0, top: 41.0, width: 348.0, height: 55.0),
      OcrWord('Molasses', left: 401.0, top: 45.0, width: 293.0, height: 53.0),
      OcrWord('Cookies', left: 720.0, top: 48.0, width: 243.0, height: 53.0),
    ],
  ),
  OcrLine(
    '1 c. oleo',
    left: 69.0,
    top: 182.0,
    width: 205.0,
    height: 48.0,
    angle: 0.0000,
    words: [
      OcrWord('1', left: 69.0, top: 182.0, width: 14.0, height: 48.0),
      OcrWord('c.', left: 92.0, top: 182.0, width: 42.0, height: 48.0),
      OcrWord('oleo', left: 160.0, top: 182.0, width: 114.0, height: 48.0),
    ],
  ),
  OcrLine(
    '1c. Sugar',
    left: 51.0,
    top: 270.0,
    width: 265.0,
    height: 57.0,
    angle: 0.0342,
    words: [
      OcrWord('1c.', left: 51.0, top: 270.0, width: 89.0, height: 51.0),
      OcrWord('Sugar', left: 167.0, top: 274.0, width: 149.0, height: 53.0),
    ],
  ),
  OcrLine(
    '1/2 c. molasses',
    left: 46.0,
    top: 366.0,
    width: 422.0,
    height: 48.0,
    angle: 0.0000,
    words: [
      OcrWord('1/2', left: 46.0, top: 366.0, width: 84.0, height: 48.0),
      OcrWord('c.', left: 152.0, top: 366.0, width: 42.0, height: 48.0),
      OcrWord('molasses', left: 222.0, top: 366.0, width: 246.0, height: 48.0),
    ],
  ),
  OcrLine(
    '2',
    left: 45.0,
    top: 453.0,
    width: 31.0,
    height: 42.0,
    angle: 0.0000,
    words: [OcrWord('2', left: 45.0, top: 453.0, width: 31.0, height: 42.0)],
  ),
  OcrLine(
    '2 eggs',
    left: 74.0,
    top: 451.0,
    width: 154.0,
    height: 63.0,
    angle: 0.0732,
    words: [
      OcrWord('2', left: 74.0, top: 452.0, width: 18.0, height: 52.0),
      OcrWord('eggs', left: 97.0, top: 453.0, width: 131.0, height: 61.0),
    ],
  ),
  OcrLine(
    '4 c. flour',
    left: 42.0,
    top: 539.0,
    width: 254.0,
    height: 56.0,
    angle: 0.0079,
    words: [
      OcrWord('4', left: 42.0, top: 540.0, width: 31.0, height: 53.0),
      OcrWord('c.', left: 98.0, top: 540.0, width: 42.0, height: 54.0),
      OcrWord('flour', left: 158.0, top: 541.0, width: 138.0, height: 54.0),
    ],
  ),
  OcrLine(
    '2 tsp soda',
    left: 40.0,
    top: 632.0,
    width: 281.0,
    height: 58.0,
    angle: -0.0213,
    words: [
      OcrWord('2', left: 40.0, top: 638.0, width: 32.0, height: 52.0),
      OcrWord('tsp', left: 96.0, top: 635.0, width: 81.0, height: 54.0),
      OcrWord('soda', left: 197.0, top: 633.0, width: 124.0, height: 54.0),
    ],
  ),
  OcrLine(
    '1 tsp. cinnamon',
    left: 74.0,
    top: 726.0,
    width: 408.0,
    height: 52.0,
    angle: 0.0000,
    words: [
      OcrWord('1', left: 74.0, top: 726.0, width: 15.0, height: 52.0),
      OcrWord('tsp.', left: 114.0, top: 726.0, width: 96.0, height: 52.0),
      OcrWord('cinnamon', left: 218.0, top: 726.0, width: 264.0, height: 52.0),
    ],
  ),
  OcrLine(
    'butter the size of an egg',
    left: 40.0,
    top: 818.0,
    width: 668.0,
    height: 50.0,
    angle: 0.0000,
    words: [
      OcrWord('butter', left: 40.0, top: 818.0, width: 174.0, height: 50.0),
      OcrWord('the', left: 232.0, top: 818.0, width: 84.0, height: 50.0),
      OcrWord('size', left: 336.0, top: 818.0, width: 104.0, height: 50.0),
      OcrWord('of', left: 460.0, top: 818.0, width: 58.0, height: 50.0),
      OcrWord('an', left: 528.0, top: 818.0, width: 62.0, height: 50.0),
      OcrWord('egg', left: 614.0, top: 818.0, width: 94.0, height: 50.0),
    ],
  ),
  OcrLine(
    'Mix all together. Roll in balls,',
    left: 41.0,
    top: 899.0,
    width: 801.0,
    height: 64.0,
    angle: -0.0137,
    words: [
      OcrWord('Mix', left: 41.0, top: 908.0, width: 103.0, height: 55.0),
      OcrWord('all', left: 164.0, top: 907.0, width: 64.0, height: 54.0),
      OcrWord('together.', left: 251.0, top: 903.0, width: 238.0, height: 57.0),
      OcrWord('Roll', left: 544.0, top: 901.0, width: 90.0, height: 55.0),
      OcrWord('in', left: 637.0, top: 901.0, width: 46.0, height: 54.0),
      OcrWord('balls,', left: 706.0, top: 899.0, width: 136.0, height: 55.0),
    ],
  ),
  OcrLine(
    'dip in sugar. Bake 350 - 10 min.',
    left: 69.0,
    top: 982.0,
    width: 833.0,
    height: 71.0,
    angle: -0.0228,
    words: [
      OcrWord('dip', left: 69.0, top: 999.0, width: 80.0, height: 54.0),
      OcrWord('in', left: 148.0, top: 997.0, width: 46.0, height: 54.0),
      OcrWord('sugar.', left: 215.0, top: 994.0, width: 163.0, height: 56.0),
      OcrWord('Bake', left: 397.0, top: 990.0, width: 136.0, height: 55.0),
      OcrWord('350', left: 552.0, top: 987.0, width: 100.0, height: 55.0),
      OcrWord('-', left: 687.0, top: 986.0, width: 15.0, height: 52.0),
      OcrWord('10', left: 719.0, top: 985.0, width: 72.0, height: 53.0),
      OcrWord('min.', left: 793.0, top: 982.0, width: 109.0, height: 54.0),
    ],
  ),
  OcrLine(
    'from Aunt Ruth 1974',
    left: 40.0,
    top: 1070.0,
    width: 579.0,
    height: 69.0,
    angle: -0.0259,
    words: [
      OcrWord('from', left: 40.0, top: 1082.0, width: 130.0, height: 57.0),
      OcrWord('Aunt', left: 185.0, top: 1078.0, width: 136.0, height: 57.0),
      OcrWord('Ruth', left: 337.0, top: 1074.0, width: 128.0, height: 58.0),
      OcrWord('1974', left: 491.0, top: 1070.0, width: 128.0, height: 57.0),
    ],
  ),
];

void main() {
  group('splitOcrLinesAtGaps', () {
    test('splits at a gap wider than twice the page line height', () {
      final out = splitOcrLinesAtGaps([
        _line(
          '2 qt water Cook over medium',
          left: 0,
          top: 0,
          gapBefore: 3,
          gapWidth: 60,
        ),
        _line('1 tablespoon garlic powder', left: 0, top: 30),
      ]);
      expect(out.map((l) => l.text), [
        '2 qt water',
        'Cook over medium',
        '1 tablespoon garlic powder',
      ]);
      expect(out[1].left, greaterThan(out[0].right + 60));
      expect(out[1].words, hasLength(3));
    });

    test('ordinary word spacing and wordless lines pass through', () {
      final plain = const OcrLine('no words', left: 0, top: 0, height: 20);
      final out = splitOcrLinesAtGaps([
        _line('a few words here', left: 0, top: 0),
        plain,
      ]);
      expect(out.map((l) => l.text), ['a few words here', 'no words']);
      expect(out[1], same(plain));
    });
  });

  group('layoutOcrLines', () {
    test('a single column comes back as its rows, pieces joined', () {
      final out = layoutOcrLines(const [
        OcrLine('BANANA', left: 10, top: 0, height: 20, width: 80),
        OcrLine('BREAD', left: 100, top: 1, height: 20, width: 60),
        OcrLine('1 cup sugar', left: 10, top: 30, height: 20, width: 100),
        OcrLine('2 eggs', left: 10, top: 60, height: 20, width: 60),
      ]);
      expect(out, ['BANANA BREAD', '1 cup sugar', '2 eggs']);
    });

    test('empty input yields nothing', () {
      expect(layoutOcrLines(const []), isEmpty);
    });

    test('headnote, then each column top to bottom, then the footer', () {
      // Full-width prose above a narrow ingredient column beside a wide
      // instruction column, with a full-width line under both. The
      // recognizer glued one row across the gutter.
      final lines = [
        _line('Turkey Legs', left: 300, top: 0, height: 40),
        _line(
          'We ate these every Monday growing up and still do today',
          left: 20,
          top: 60,
        ),
        _line('INGREDIENTS', left: 20, top: 120),
        _line('INSTRUCTIONS', left: 400, top: 120),
        _line(
          '2 qt water Combine the water and salt in a pan',
          left: 20,
          top: 150,
          gapBefore: 3,
          gapWidth: 180,
        ),
        _line('1 cup salt', left: 20, top: 180),
        _line('and bring to a boil over medium heat', left: 400, top: 180),
        _line('6 turkey legs', left: 20, top: 210),
        _line('Add the legs and refrigerate for a day', left: 400, top: 215),
        _line('continued on page 88', left: 20, top: 300),
        _line(
          'Serve with cornbread and a cold drink on the porch',
          left: 20,
          top: 360,
        ),
      ];
      expect(layoutOcrLines(lines), [
        'Turkey Legs',
        'We ate these every Monday growing up and still do today',
        '',
        'INGREDIENTS',
        '2 qt water',
        '1 cup salt',
        '6 turkey legs',
        '',
        'continued on page 88',
        '',
        'INSTRUCTIONS',
        'Combine the water and salt in a pan',
        'and bring to a boil over medium heat',
        'Add the legs and refrigerate for a day',
        '',
        'Serve with cornbread and a cold drink on the porch',
      ]);
    });

    test('label/value rows read as a table, row by row', () {
      final card = [
        _line('Flour', left: 20, top: 0),
        _line('2 cups', left: 300, top: 0),
        _line('Sugar', left: 20, top: 30),
        _line('1 cup', left: 300, top: 30),
        _line('Baking powder', left: 20, top: 60),
        _line('1 tsp', left: 300, top: 60),
      ];
      expect(layoutOcrLines(card), [
        'Flour 2 cups',
        'Sugar 1 cup',
        'Baking powder 1 tsp',
      ]);

      final receipt = [
        _line('BRISKET PLATE', left: 10, top: 0),
        _line('18.50', left: 500, top: 0),
        _line('QUESO', left: 10, top: 30),
        _line('9.00', left: 500, top: 30),
      ];
      expect(layoutOcrLines(receipt), ['BRISKET PLATE 18.50', 'QUESO 9.00']);
    });

    test('two ingredient columns both starting numeric read as columns', () {
      final card = [
        _line('2 cups flour', left: 20, top: 0),
        _line('1 tsp salt', left: 300, top: 0),
        _line('1 cup sugar', left: 20, top: 30),
        _line('2 eggs', left: 300, top: 30),
      ];
      expect(layoutOcrLines(card), [
        '2 cups flour',
        '1 cup sugar',
        '',
        '1 tsp salt',
        '2 eggs',
      ]);
    });

    test('an indented line under its neighbour is a wrapped continuation', () {
      final out = layoutOcrLines([
        _line('1/4 cup firmly packed', left: 20, top: 0),
        _line('light brown sugar', left: 36, top: 26),
        _line('1 cup grated', left: 20, top: 52),
        _line('Parmesan cheese', left: 36, top: 78),
        _line('Mix well. Chill.', left: 20, top: 104),
        _line('Serve cold.', left: 36, top: 130),
        _line('6 eggs', left: 20, top: 156),
      ]);
      expect(out, [
        '1/4 cup firmly packed light brown sugar',
        '1 cup grated Parmesan cheese',
        'Mix well. Chill.',
        'Serve cold.',
        '6 eggs',
      ]);
    });

    test('a column edge drifting on a curved page is not an indent', () {
      // Each line starts 6 px further left than the one above, as the
      // ingredient column of a page bowing into the spine does.
      final out = layoutOcrLines([
        _line('2 cups flour,', left: 60, top: 0),
        _line('plus flour for dusting', left: 84, top: 26),
        _line('2 tablespoons baking powder', left: 48, top: 52),
        _line('1/4 teaspoon baking soda', left: 42, top: 78),
        _line('1 teaspoon kosher salt', left: 36, top: 104),
        _line('1/2 cup very cold', left: 30, top: 130),
        _line('unsalted butter, diced', left: 54, top: 156),
        _line('1 cup buttermilk', left: 18, top: 182),
      ]);
      expect(out, [
        '2 cups flour, plus flour for dusting',
        '2 tablespoons baking powder',
        '1/4 teaspoon baking soda',
        '1 teaspoon kosher salt',
        '1/2 cup very cold unsalted butter, diced',
        '1 cup buttermilk',
      ]);
    });

    test('an indented line set as far down as a new entry is not a wrap', () {
      // Ingredients 66 apart, wraps 48 apart; the recognizer lost the
      // "1" of "1 cup buttermilk", leaving it indented like a wrap.
      final out = layoutOcrLines([
        _line('2 cups flour,', left: 20, top: 0),
        _line('plus flour for dusting', left: 60, top: 48),
        _line('2 tablespoons baking powder', left: 20, top: 114),
        _line('1/2 cup very cold', left: 20, top: 180),
        _line('unsalted butter, melted', left: 60, top: 228),
        _line('cup buttermilk', left: 54, top: 294),
        _line('1 teaspoon salt', left: 20, top: 360),
      ]);
      expect(out, [
        '2 cups flour, plus flour for dusting',
        '2 tablespoons baking powder',
        '1/2 cup very cold unsalted butter, melted',
        'cup buttermilk',
        '1 teaspoon salt',
      ]);
    });

    test('a line opening with a quantity is a new entry, not a wrap', () {
      final out = layoutOcrLines([
        _line('2 tsp soda', left: 20, top: 0),
        _line('1 tsp. cinnamon', left: 36, top: 26),
        _line('1/2 cup very cold', left: 20, top: 52),
        _line('unsalted butter', left: 36, top: 78),
      ]);
      expect(out, [
        '2 tsp soda',
        '1 tsp. cinnamon',
        '1/2 cup very cold unsalted butter',
      ]);
    });

    test('a glyph the recognizer read twice on one row is kept once', () {
      final out = layoutOcrLines(const [
        OcrLine('2', left: 45, top: 453, width: 31, height: 42),
        OcrLine('2 eggs', left: 74, top: 451, width: 154, height: 63),
        OcrLine('2', left: 45, top: 520, width: 31, height: 42),
        OcrLine('2 cups', left: 120, top: 520, width: 154, height: 42),
      ]);
      expect(out, ['2 eggs', '2 2 cups']);
    });

    test('a typed recipe card reads one ingredient per line', () {
      expect(layoutOcrLines(_molassesCard), [
        "Grandma's Molasses Cookies",
        '1 c. oleo',
        '1c. Sugar',
        '1/2 c. molasses',
        '2 eggs',
        '4 c. flour',
        '2 tsp soda',
        '1 tsp. cinnamon',
        'butter the size of an egg',
        'Mix all together. Roll in balls, dip in sugar. Bake 350 - 10 min.',
        'from Aunt Ruth 1974',
      ]);
    });

    test('a clear vertical gap in a column is a paragraph break', () {
      final out = layoutOcrLines([
        _line('Mix the flour and sugar', left: 20, top: 0),
        _line('until smooth', left: 20, top: 26),
        _line('Bake for an hour', left: 20, top: 90),
      ]);
      expect(out, [
        'Mix the flour and sugar',
        'until smooth',
        '',
        'Bake for an hour',
      ]);
    });

    test(
      'a split inside one column of a two-column block reads as one line',
      () {
        final out = layoutOcrLines([
          _line('1 cup salt', left: 20, top: 0),
          _line('Combine the water and salt in a large pan', left: 400, top: 0),
          _line('2 bay leaves', left: 20, top: 30),
          _line('and bring', left: 400, top: 30),
          _line('to a boil over medium heat', left: 560, top: 30),
          _line('6 legs', left: 20, top: 60),
          _line('Add the legs and chill them for a day', left: 400, top: 60),
        ]);
        expect(out, [
          '1 cup salt',
          '2 bay leaves',
          '6 legs',
          '',
          'Combine the water and salt in a large pan',
          'and bring to a boil over medium heat',
          'Add the legs and chill them for a day',
        ]);
      },
    );

    test('a tilted page still separates its columns', () {
      final skew = 2 * math.pi / 180;
      OcrLine tilted(String text, {required double left, required double top}) {
        final l = _line(text, left: left, top: top, angle: skew);
        final cx = l.left + l.width / 2;
        return OcrLine(
          l.text,
          left: l.left,
          top: top + cx * math.tan(skew),
          height: l.height,
          width: l.width,
          angle: skew,
          words: l.words,
        );
      }

      final out = layoutOcrLines([
        tilted('1 cup salt', left: 20, top: 0),
        tilted('Combine the water and salt in a pan', left: 400, top: 0),
        tilted('2 bay leaves', left: 20, top: 30),
        tilted('and bring to a boil over medium heat', left: 400, top: 30),
        tilted('6 legs', left: 20, top: 60),
        tilted('Add the legs and chill them for a day', left: 400, top: 60),
      ]);
      expect(out, [
        '1 cup salt',
        '2 bay leaves',
        '6 legs',
        '',
        'Combine the water and salt in a pan',
        'and bring to a boil over medium heat',
        'Add the legs and chill them for a day',
      ]);
    });
    test('a narrow gutter shows through tall boxes on a curved page', () {
      // Long headnote and instruction lines on a bowed page get upright
      // boxes four times their lettering; the 50 px gutter is 2.5 words
      // high but well under twice those boxes.
      final out = layoutOcrLines([
        _line(
          'Biscuits play a big role in the show and in the kitchen',
          left: 20,
          top: 0,
          boxHeight: 80,
        ),
        _line(
          'and these are the ones the family asks for every time',
          left: 20,
          top: 30,
          boxHeight: 80,
        ),
        _line(
          '2 cups flour Preheat the oven to 450 degrees',
          left: 20,
          top: 100,
          gapBefore: 3,
          gapWidth: 90, // the instruction column starts at x = 226
          boxHeight: 80,
        ),
        _line(
          '1 cup buttermilk Sift the flour and the salt together',
          left: 20,
          top: 130,
          gapBefore: 3,
          gapWidth: 50,
          boxHeight: 80,
        ),
        _line(
          '1 teaspoon salt Add the butter and pulse until fine',
          left: 20,
          top: 160,
          gapBefore: 3,
          gapWidth: 60,
          boxHeight: 80,
        ),
      ]);
      expect(out, [
        'Biscuits play a big role in the show and in the kitchen',
        'and these are the ones the family asks for every time',
        '',
        '2 cups flour',
        '1 cup buttermilk',
        '1 teaspoon salt',
        '',
        'Preheat the oven to 450 degrees',
        'Sift the flour and the salt together',
        'Add the butter and pulse until fine',
      ]);
    });
  });

  group('textHeight', () {
    test("is the words' median height, else the line box", () {
      expect(
        textHeight(_line('a long tilted line', left: 0, top: 0, boxHeight: 90)),
        20,
      );
      expect(
        textHeight(const OcrLine('no words', left: 0, top: 0, height: 33)),
        33,
      );
    });
  });

  test('a line opening with a spelled-out ½ ("V2 C.") is a quantity '
      'line, so the next quantity line is not its wrap', () {
    // A typed family cookbook page, Pixel 9 Pro XL, 2026-10-29: "2
    // eggs, beaten" sat a little in from "V2 C. dry bread crumbs".
    final lines = [
      _line('1/3 c. chopped onions', left: 100, top: 100),
      _line('V2 C. dry bread crumbs', left: 100, top: 125),
      _line('2 eggs, beaten', left: 112, top: 150),
      _line('2 tsp. salt', left: 100, top: 175),
    ];
    expect(layoutOcrLines(lines), [
      '1/3 c. chopped onions',
      'V2 C. dry bread crumbs',
      '2 eggs, beaten',
      '2 tsp. salt',
    ]);
  });
}
