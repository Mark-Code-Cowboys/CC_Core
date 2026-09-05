/// One counted thing in a [countHeadline]: a count, its singular label,
/// and an optional irregular plural.
class CountedSubject {
  /// Creates the entry; [many] defaults to `one` + "s".
  const CountedSubject(this.count, this.one, {String? many})
      : many = many ?? '${one}s';

  /// How many exist.
  final int count;

  /// Singular label ("course").
  final String one;

  /// Plural label ("courses", "countries").
  final String many;

  @override
  String toString() => '$count ${count == 1 ? one : many}';
}

/// "47 courses · 12 states" — the ledger's proudest line, shared by CC
/// app home screens. Subjects with a zero count are dropped after the
/// first (the lead subject always shows, even at zero).
String countHeadline(List<CountedSubject> subjects) {
  final parts = <String>[
    for (final (i, s) in subjects.indexed)
      if (i == 0 || s.count > 0) s.toString(),
  ];
  return parts.join(' · ');
}
