import 'package:flutter/material.dart';

/// The month layout every CC calendar/heatmap view shares, extracted
/// from Trace Elements: Sunday-first weekday header and aligned rows of
/// square day cells. The app owns everything *inside* a cell (colors,
/// badges, judgement) via [dayBuilder]; the grid owns only alignment
/// math and layout.
class CalendarMonthGrid extends StatelessWidget {
  /// Creates the grid for [year]/[month].
  const CalendarMonthGrid({
    super.key,
    required this.year,
    required this.month,
    required this.dayBuilder,
    this.weekdayLabels = const [
      'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat',
    ],
  }) : assert(weekdayLabels.length == 7, 'Seven weekday labels');

  /// Calendar year.
  final int year;

  /// Calendar month (1-12).
  final int month;

  /// Builds one day's square cell.
  final Widget Function(BuildContext context, DateTime date) dayBuilder;

  /// Header labels, Sunday first.
  final List<String> weekdayLabels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(year, month);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Sunday-first columns: DateTime.weekday is Mon=1..Sun=7.
    final leading = first.weekday % 7;
    final rows = (leading + daysInMonth + 6) ~/ 7;

    return Column(
      children: [
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < rows; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _cell(context, row * 7 + col, leading,
                          daysInMonth),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _cell(
      BuildContext context, int index, int leading, int daysInMonth) {
    if (index < leading || index >= leading + daysInMonth) {
      return const SizedBox.shrink();
    }
    return dayBuilder(context, DateTime(year, month, index - leading + 1));
  }
}

/// Previous/next navigation over a trend window ("June 2026", "Week of
/// Jun 15"), extracted from Trace Elements.
class TrendWindowNav extends StatelessWidget {
  /// Creates the nav row.
  const TrendWindowNav({
    super.key,
    required this.label,
    required this.onPrev,
    required this.onNext,
    this.nextEnabled = true,
    this.prevEnabled = true,
  });

  /// The window's name, centered between the arrows.
  final String label;

  /// Steps one window back.
  final VoidCallback onPrev;

  /// Steps one window forward.
  final VoidCallback onNext;

  /// False greys the forward arrow (the present is the edge).
  final bool nextEnabled;

  /// False greys the back arrow.
  final bool prevEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: prevEnabled ? onPrev : null,
            tooltip: 'Previous',
            icon: const Icon(Icons.keyboard_arrow_left)),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        IconButton(
            onPressed: nextEnabled ? onNext : null,
            tooltip: 'Next',
            icon: const Icon(Icons.keyboard_arrow_right)),
      ],
    );
  }
}
