import 'package:flutter/material.dart';

/// One value over time as a plain polyline with dots — no grid, no
/// legend, no axes to pretend at precision. First/last dates and the
/// value range label the corners.
class SimpleLineChart extends StatelessWidget {
  /// Creates the chart from time-ordered points.
  const SimpleLineChart({
    super.key,
    required this.points,
    this.height = 120,
    this.dateLabel = _defaultDateLabel,
  });

  /// The series; fewer than two points renders nothing (gate upstream
  /// with `TrendGate`).
  final List<(DateTime, num)> points;

  /// Drawn height of the chart area.
  final double height;

  /// Formats the corner date labels.
  final String Function(DateTime) dateLabel;

  static String _defaultDateLabel(DateTime d) =>
      '${d.month}/${d.year % 100}';

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final sorted = [...points]..sort((a, b) => a.$1.compareTo(b.$1));
    final values = sorted.map((p) => p.$2);
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$max', style: theme.textTheme.bodySmall),
            Text('$min', style: theme.textTheme.bodySmall),
          ],
        ),
        SizedBox(
          height: height,
          child: CustomPaint(
            painter: _LinePainter(
              sorted,
              color: theme.colorScheme.primary,
              min: min.toDouble(),
              max: max.toDouble(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(dateLabel(sorted.first.$1), style: theme.textTheme.bodySmall),
            Text(dateLabel(sorted.last.$1), style: theme.textTheme.bodySmall),
          ],
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points,
      {required this.color, required this.min, required this.max});

  final List<(DateTime, num)> points;
  final Color color;
  final double min;
  final double max;

  @override
  void paint(Canvas canvas, Size size) {
    final t0 = points.first.$1.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.$1.millisecondsSinceEpoch.toDouble();
    final spanT = (t1 - t0) == 0 ? 1.0 : t1 - t0;
    final spanV = (max - min) == 0 ? 1.0 : max - min;
    const inset = 4.0;

    Offset at((DateTime, num) p) => Offset(
          inset +
              (p.$1.millisecondsSinceEpoch - t0) /
                  spanT *
                  (size.width - inset * 2),
          inset + (max - p.$2) / spanV * (size.height - inset * 2),
        );

    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(at(points.first).dx, at(points.first).dy);
    for (final p in points.skip(1)) {
      final o = at(p);
      path.lineTo(o.dx, o.dy);
    }
    canvas.drawPath(path, line);

    final dot = Paint()..color = color;
    for (final p in points) {
      canvas.drawCircle(at(p), 3, dot);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.points != points || old.color != color;
}
