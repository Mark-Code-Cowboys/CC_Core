import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ported from the Trace Elements donor's FuzzyMatchTest.kt — the
/// behavior is pinned so autocomplete matches the shipped KMP app.
void main() {
  group('suggest', () {
    test('degenerate queries return empty', () {
      expect(FuzzyMatch.suggest('', ['apple', 'banana']), isEmpty);
      expect(FuzzyMatch.suggest('a', ['apple', 'banana']), isEmpty,
          reason: 'single chars are too noisy to be useful suggestions');
      expect(FuzzyMatch.suggest('   ', ['apple']), isEmpty);
      expect(FuzzyMatch.suggest('apple', const <String>[]), isEmpty);
    });

    test('substring match surfaces, case-insensitively', () {
      expect(
          FuzzyMatch.suggest('apple', ['apple, raw', 'carrot']), ['apple, raw']);
      expect(FuzzyMatch.suggest('APPLE', ['Apple, Raw']), ['Apple, Raw']);
    });

    test('exact (case-insensitive) matches are excluded', () {
      // Exact hits are already resolved by direct lookup; suggest only
      // surfaces near-misses.
      expect(FuzzyMatch.suggest('apple', ['Apple', 'apple, raw']),
          ['apple, raw']);
    });

    test('typos tolerated via Levenshtein', () {
      expect(FuzzyMatch.suggest('aple', ['apple', 'banana']), ['apple']);
    });

    test('token reordering matches', () {
      expect(FuzzyMatch.suggest('raw apple', ['Apples, raw', 'Bread, rye']),
          ['Apples, raw']);
    });

    test('shorter candidate outranks longer for a substring query', () {
      expect(
          FuzzyMatch.suggest(
              'apple', ['apples, raw, with skin', 'apple, raw']).first,
          'apple, raw');
      expect(FuzzyMatch.suggest('apple', ['apple, gala', 'apple, raw']),
          ['apple, raw', 'apple, gala']);
    });

    test('max limit respected', () {
      final candidates = [
        'apple, raw',
        'apples, gala',
        'apples, fuji',
        'applesauce',
        'apple juice'
      ];
      expect(FuzzyMatch.suggest('apple', candidates, max: 2), hasLength(2));
    });

    test('unrelated candidates filtered out', () {
      expect(FuzzyMatch.suggest('apple', ['zucchini', 'tofu', 'haggis']),
          isEmpty);
      expect(FuzzyMatch.suggest('xy', ['antidisestablishmentarianism']),
          isEmpty);
    });

    test('punctuation in candidate does not block token match', () {
      expect(
          FuzzyMatch.suggest('granny apple', ['Apples (Granny Smith)', 'Pears']),
          contains('Apples (Granny Smith)'));
    });

    test('realistic food-db scenario', () {
      final db = [
        'apple, raw, with skin',
        'apple juice, canned or bottled',
        'apricot, raw',
        'asparagus, cooked',
        'almonds, raw',
        'avocado, raw'
      ];
      final result = FuzzyMatch.suggest('apple', db, max: 3);
      expect(result.any((r) => r.startsWith('apple')), isTrue);
      expect(result, isNot(contains('apricot, raw')));
    });
  });

  group('matchesQuery', () {
    test('is word-order independent', () {
      expect(FuzzyMatch.matchesQuery('scrambled eggs', 'eggs scrambled'),
          isTrue);
      expect(FuzzyMatch.matchesQuery('eggs scrambled', 'scrambled eggs'),
          isTrue);
      expect(FuzzyMatch.matchesQuery('scrambled eggs', 'eggs, scrambled'),
          isTrue);
    });

    test('still honors contiguous substrings', () {
      expect(FuzzyMatch.matchesQuery('apple', 'apple, raw'), isTrue);
      expect(FuzzyMatch.matchesQuery('APPLE', 'Apple, Raw'), isTrue);
    });

    test('rejects a missing token', () {
      expect(FuzzyMatch.matchesQuery('eggs benedict', 'eggs, scrambled'),
          isFalse);
    });

    test('blank matches nothing', () {
      expect(FuzzyMatch.matchesQuery('', 'eggs, scrambled'), isFalse);
      expect(FuzzyMatch.matchesQuery('   ', 'eggs, scrambled'), isFalse);
    });
  });

  group('wordOrderVariants', () {
    test('reverses a two-word query', () {
      expect(FuzzyMatch.wordOrderVariants('scrambled eggs'),
          ['scrambled eggs', 'eggs scrambled']);
    });

    test('single word is itself', () {
      expect(FuzzyMatch.wordOrderVariants('eggs'), ['eggs']);
    });

    test('always starts with the original and respects the cap', () {
      final variants =
          FuzzyMatch.wordOrderVariants('cream of mushroom soup', max: 3);
      expect(variants.first, 'cream of mushroom soup');
      expect(variants.length, lessThanOrEqualTo(3));
      expect(variants.toSet().length, variants.length);
    });

    test('normalizes whitespace', () {
      expect(FuzzyMatch.wordOrderVariants('  scrambled   eggs  '),
          ['scrambled eggs', 'eggs scrambled']);
    });
  });
}
