import 'package:flutter/material.dart';

import 'free_limit.dart';

/// "2 of 5 free campgrounds used" — the counter card every CC home
/// screen shows free users, with a progress bar that fills as the
/// quota is spent. Riverpod-free like the rest of the paywall module:
/// the app computes [usage] (and hides the widget entirely for
/// entitled users) and handles [onGoPro]. Extracted from Course
/// Ledger's copy when Hitch Post became the third app to want one.
class FreeTierCounter extends StatelessWidget {
  /// Creates the counter.
  const FreeTierCounter({
    super.key,
    required this.usage,
    required this.onGoPro,
    this.goProLabel = 'Go Pro',
    this.margin = const EdgeInsets.fromLTRB(16, 8, 16, 0),
  });

  /// Where the user stands against the free tier.
  final FreeLimitUsage usage;

  /// Opens the app's paywall (whole card and the button both tap).
  final VoidCallback onGoPro;

  /// The action button's label.
  final String goProLabel;

  /// Outer spacing.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final radius = BorderRadius.circular(12);

    return Padding(
      padding: margin,
      child: Material(
        color: usage.atLimit
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onGoPro,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Icon(
                  usage.atLimit
                      ? Icons.star_rounded
                      : Icons.star_outline_rounded,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(usage.label, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: usage.used / usage.limit,
                          minHeight: 6,
                          backgroundColor: scheme.surface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(usage.detail, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                TextButton(onPressed: onGoPro, child: Text(goProLabel)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
