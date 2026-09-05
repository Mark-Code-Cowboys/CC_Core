import 'package:flutter/material.dart';

/// Anti-stats-cosplay guard: a chart earns its place only once there is
/// enough data to mean something. Below [minPoints] this renders the
/// app's [nudge] line instead of a junk chart — CC apps are ledgers and
/// journals first, not analytics dashboards.
class TrendGate extends StatelessWidget {
  /// Creates the gate.
  const TrendGate({
    super.key,
    required this.points,
    required this.minPoints,
    required this.nudge,
    required this.builder,
  });

  /// How many data points exist.
  final int points;

  /// How many the chart needs before it renders.
  final int minPoints;

  /// One friendly line shown until then ("Log five scored rounds and
  /// the trend line appears.").
  final String nudge;

  /// Builds the chart once [points] >= [minPoints].
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (points >= minPoints) return builder(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.hourglass_empty,
              size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nudge,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
