import 'package:flutter/material.dart';

/// Counts per year as horizontal bars — the simplest honest shape for
/// "how much of X each year". Years render ascending; missing years in
/// between show as zero so gaps are visible.
class YearlyBars extends StatelessWidget {
  /// Creates the chart from year -> count.
  const YearlyBars({super.key, required this.countsByYear});

  /// The data; empty renders nothing.
  final Map<int, int> countsByYear;

  @override
  Widget build(BuildContext context) {
    if (countsByYear.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final years = countsByYear.keys.toList()..sort();
    final allYears = [
      for (var y = years.first; y <= years.last; y++) y,
    ];
    final max = countsByYear.values.reduce((a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final year in allYears)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text('$year', style: theme.textTheme.bodySmall),
                ),
                Expanded(
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: max == 0
                        ? 0
                        : (countsByYear[year] ?? 0) / max,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text(
                    '${countsByYear[year] ?? 0}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
