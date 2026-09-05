import 'package:flutter/material.dart';

/// 1-5 stars for journal-entry (and domain) ratings. Read-only when
/// [onChanged] is null. Tapping the current rating's star clears it —
/// ratings are optional everywhere in CC apps. Extracted from Course
/// Ledger when Hitch Post became its second consumer.
class RatingStars extends StatelessWidget {
  /// Creates the stars.
  const RatingStars({super.key, this.rating, this.onChanged, this.size = 24});

  /// Current rating 1-5, or null for unrated.

  final int? rating;

  /// Called with the new rating (null = cleared); null makes the stars
  /// read-only.
  final ValueChanged<int?>? onChanged;

  /// Icon size.
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          GestureDetector(
            onTap: onChanged == null
                ? null
                : () => onChanged!(star == rating ? null : star),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Icon(
                (rating ?? 0) >= star ? Icons.star : Icons.star_border,
                size: size,
                color: color,
                semanticLabel: onChanged != null && star == 1
                    ? 'Rating: ${rating ?? 0} of 5'
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
