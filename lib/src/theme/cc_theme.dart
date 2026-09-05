import 'package:flutter/material.dart';

/// One app's visual identity, handed to [ccLightTheme]/[ccDarkTheme].
///
/// Both existing apps vary only color: a seed, and optionally a
/// hand-tuned [ColorScheme] per brightness (Table Encore's cream-paper
/// palette; Course Ledger's fairway green). Type scale and corner radii
/// join here the day an app actually varies them — not before.
class CcThemeTokens {
  /// Creates the tokens. [seed] drives Material's generated palette;
  /// a non-null [lightScheme]/[darkScheme] replaces the generated one
  /// entirely for that brightness.
  const CcThemeTokens({
    required this.seed,
    this.lightScheme,
    this.darkScheme,
  });

  /// The accent everything derives from when no explicit scheme is
  /// given.
  final Color seed;

  /// Hand-tuned light palette, or null to generate from [seed].
  final ColorScheme? lightScheme;

  /// Hand-tuned dark palette, or null to generate from [seed].
  final ColorScheme? darkScheme;
}

/// The light theme every CC app shares, over the app's tokens.
ThemeData ccLightTheme(CcThemeTokens tokens) => _base(
    tokens.lightScheme ?? ColorScheme.fromSeed(seedColor: tokens.seed));

/// The dark theme every CC app shares, over the app's tokens.
ThemeData ccDarkTheme(CcThemeTokens tokens) => _base(tokens.darkScheme ??
    ColorScheme.fromSeed(
        seedColor: tokens.seed, brightness: Brightness.dark));

/// The shared base both apps had hand-copied: surface-colored scaffold
/// and app bar so screens read as one continuous sheet of paper.
ThemeData _base(ColorScheme scheme) {
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
  );
}
