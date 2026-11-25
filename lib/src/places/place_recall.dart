/// One past visit and what was had there, for [recallAtPlace].
class VisitWithItems<I> {
  /// Creates the visit.
  const VisitWithItems({required this.visitedAt, required this.items});

  /// When the visit happened.
  final DateTime visitedAt;

  /// What was had (dishes, drinks...), in the app's own type.
  final List<I> items;
}

/// "What did I have here last time?" — the answer at the door of a
/// place visited before.
class PlaceRecall<I> {
  /// Creates the recall.
  const PlaceRecall({
    required this.lastVisitAt,
    required this.lastItems,
    required this.usual,
    required this.visitCount,
  });

  /// The most recent visit that recorded anything; null when none did.
  final DateTime? lastVisitAt;

  /// What was had on that visit, in recorded order.
  final List<I> lastItems;

  /// Items had on more than one visit, most visits first (ties: most
  /// recent first) — one representative item each, the latest.
  final List<I> usual;

  /// Visits to this place, including ones that recorded nothing.
  final int visitCount;

  /// True when there is nothing to recall.
  bool get isEmpty => lastItems.isEmpty;
}

/// Builds the recall for one place from its [visits] (any order).
/// [keyOf] says when two items are "the same thing" across visits —
/// typically the name, trimmed and lowercased. Pure: the app loads the
/// visits however its schema stores them.
PlaceRecall<I> recallAtPlace<I>(
  List<VisitWithItems<I>> visits, {
  required String Function(I item) keyOf,
}) {
  final newestFirst = [...visits]
    ..sort((a, b) => b.visitedAt.compareTo(a.visitedAt));
  final last = newestFirst.where((v) => v.items.isNotEmpty).firstOrNull;

  final visitsByKey = <String, int>{};
  final latest = <String, (I, DateTime)>{};
  for (final visit in newestFirst) {
    final seenThisVisit = <String>{};
    for (final item in visit.items) {
      final key = keyOf(item);
      if (key.isEmpty || !seenThisVisit.add(key)) continue;
      visitsByKey[key] = (visitsByKey[key] ?? 0) + 1;
      latest.putIfAbsent(key, () => (item, visit.visitedAt));
    }
  }
  final usualKeys =
      [
        for (final e in visitsByKey.entries)
          if (e.value > 1) e.key,
      ]..sort((a, b) {
        final byCount = visitsByKey[b]!.compareTo(visitsByKey[a]!);
        return byCount != 0 ? byCount : latest[b]!.$2.compareTo(latest[a]!.$2);
      });

  return PlaceRecall(
    lastVisitAt: last?.visitedAt,
    lastItems: last?.items ?? const [],
    usual: [for (final k in usualKeys) latest[k]!.$1],
    visitCount: visits.length,
  );
}
