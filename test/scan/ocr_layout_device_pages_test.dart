import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixtures/gumbo_page.dart';
import 'fixtures/tenders_page.dart';
import 'fixtures/tenders_rescan_page.dart';

/// Two Yellowstone cookbook pages as ML Kit read them on a Pixel 9 Pro
/// XL (Trace Elements, 2026-10-29), laid out end to end.
void main() {
  group('Kickin\' Chicken Tenders (curved page, two sections)', () {
    final out = layoutOcrLines(tendersPage);

    test('a headnote gap with no column beyond it stays in the sentence', () {
      expect(out, isNot(contains('spectacular')));
      expect(
        out.any((l) => l.contains('Kickin\' Chicken is spectacular and it')),
        isTrue,
      );
    });

    test('a long ingredient heading beside the instructions splits', () {
      expect(out, contains('For the Pickled Jalapeño Sauce'));
      expect(
        out.where((l) => l.startsWith('To prepare the sauce')),
        hasLength(1),
      );
    });

    test('small hanging indents wrap; a lower-case word on less', () {
      expect(
        out,
        contains(
          'l cup (240 g) jarred sliced jalapeño chiles in vinegar '
          '(hot or mild), drained and chopped',
        ),
      );
      expect(out, contains('I tablespoon hot-pepper Sauce, or to taste'));
    });

    test('the ingredient column reads whole before the instructions', () {
      final eggs = out.indexOf('2 large eggs');
      final instructions = out.indexOf('INSTRUCTIONS');
      expect(eggs, greaterThan(0));
      expect(instructions, greaterThan(eggs));
      expect(
        out.last,
        startsWith('rack over a baking sheet'),
        reason: 'the curved page\'s instructions stay one column',
      );
    });
  });

  group('Chicken and Sausage Gumbo (narrow column, hanging indents)', () {
    final out = layoutOcrLines(gumboPage);

    test('each wrapped entry is one line', () {
      expect(
        out,
        contains(
          '6 boneless, skinless chicken thighs, cut into 2-inch (5-cm) '
          'pieces (about 2 lb/l kgl',
        ),
      );
      expect(out, contains('l green bell pepper, seeded and chopped'));
      expect(out, contains('l tablespoon Cajun hot- pepper sauce'));
    });

    test('yield and instructions stay apart', () {
      expect(out, contains('MAKES 6-8 SERVINGS'));
      expect(
        out.firstWhere((l) => l.startsWith('In a large Dutch oven')),
        isNot(contains('SERVINGS')),
      );
    });
  });

  group('Kickin\' Chicken Tenders rescanned (a headnote word on its own)', () {
    final out = layoutOcrLines(tendersRescanPage);

    test('a word set apart in its row with nothing beyond it to align '
        'with stays in the row', () {
      expect(out, isNot(contains('spectacular')));
      expect(
        out,
        contains(
          'spectacular and it\'s a spectacle to behold. The secret to '
          'making the best',
        ),
      );
    });

    test('the columns still read whole', () {
      expect(out, contains('For the Pickled Jalapeño Sauce'));
      expect(
        out.indexOf('INSTRUCTIONS'),
        greaterThan(out.indexOf('2 large eggs')),
      );
    });
  });
}
