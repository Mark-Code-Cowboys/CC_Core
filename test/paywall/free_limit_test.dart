import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const limit = FreeLimit(5, 'restaurants');

  group('FreeLimit.guard', () {
    test('under the limit passes', () {
      expect(() => limit.guard(used: 4, entitled: false), returnsNormally);
    });

    test('at the limit throws for free users', () {
      expect(
        () => limit.guard(used: 5, entitled: false),
        throwsA(isA<FreeLimitReachedException>()
            .having((e) => e.limit, 'limit', 5)),
      );
    });

    test('over the limit throws for free users', () {
      expect(
        () => limit.guard(used: 7, entitled: false),
        throwsA(isA<FreeLimitReachedException>()),
      );
    });

    test('entitled users are never gated', () {
      expect(() => limit.guard(used: 5, entitled: true), returnsNormally);
      expect(() => limit.guard(used: 99, entitled: true), returnsNormally);
    });
  });

  group('FreeLimitUsage', () {
    test('label and counts', () {
      final usage = limit.usage(2);
      expect(usage.label, '2 of 5 free restaurants used');
      expect(usage.remaining, 3);
      expect(usage.atLimit, isFalse);
    });

    test('at and over the limit', () {
      expect(limit.usage(5).atLimit, isTrue);
      expect(limit.usage(5).remaining, 0);
      expect(limit.usage(9).remaining, 0, reason: 'never negative');
    });

    test('generic detail wording', () {
      expect(limit.usage(2).detail, '3 more free — then the unlock.');
      expect(limit.usage(4).detail, '1 more free — then the unlock.');
      expect(limit.usage(5).detail,
          'Free restaurants all used — unlock to add more.');
    });

    test('detailBuilder overrides the wording', () {
      final custom = FreeLimit(5, 'restaurants',
          detailBuilder: (remaining) => switch (remaining) {
                0 => 'Free places all used — unlock Unlimited to add more.',
                1 => '1 more new place free — then the Unlimited unlock.',
                final n => '$n more new places free — then the Unlimited '
                    'unlock.',
              });
      expect(custom.usage(2).detail,
          '3 more new places free — then the Unlimited unlock.');
      expect(custom.usage(4).detail,
          '1 more new place free — then the Unlimited unlock.');
      expect(custom.usage(5).detail,
          'Free places all used — unlock Unlimited to add more.');
    });
  });
}
