import 'package:cc_core/cc_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const seed = Color(0xFF1E5631);

  test('seed-only tokens generate both brightnesses over the shared base',
      () {
    const tokens = CcThemeTokens(seed: seed);
    final light = ccLightTheme(tokens);
    final dark = ccDarkTheme(tokens);

    expect(light.colorScheme.brightness, Brightness.light);
    expect(dark.colorScheme.brightness, Brightness.dark);
    // The shared base: scaffold and app bar sit on the surface color.
    expect(light.scaffoldBackgroundColor, light.colorScheme.surface);
    expect(light.appBarTheme.backgroundColor, light.colorScheme.surface);
    expect(dark.scaffoldBackgroundColor, dark.colorScheme.surface);
  });

  test('a hand-tuned scheme replaces the generated one wholesale', () {
    final tuned = ColorScheme.fromSeed(seedColor: seed)
        .copyWith(primary: seed, onPrimary: Colors.white);
    final theme =
        ccLightTheme(CcThemeTokens(seed: seed, lightScheme: tuned));
    expect(theme.colorScheme.primary, seed);
    expect(theme.colorScheme.onPrimary, Colors.white);
  });

  group('countHeadline', () {
    test('joins counts with proper singulars and plurals', () {
      expect(
        countHeadline(const [
          CountedSubject(47, 'course'),
          CountedSubject(12, 'state'),
        ]),
        '47 courses · 12 states',
      );
      expect(
        countHeadline(const [
          CountedSubject(1, 'course'),
          CountedSubject(1, 'country', many: 'countries'),
        ]),
        '1 course · 1 country',
      );
    });

    test('drops zero counts after the lead subject', () {
      expect(
        countHeadline(const [
          CountedSubject(0, 'course'),
          CountedSubject(0, 'state'),
        ]),
        '0 courses',
      );
    });
  });
}
