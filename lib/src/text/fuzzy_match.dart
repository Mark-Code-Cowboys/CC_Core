/// Token-similarity fuzzy matching for autocomplete over a modest
/// candidate set (a food database, ingredient names, journal tags).
/// Extracted from Trace Elements; nothing in here is domain-specific.
library;

const _tokenSeparators = [' ', ',', '-', '/', '(', ')'];

List<String> _tokens(String s) =>
    s.split(RegExp('[${RegExp.escape(_tokenSeparators.join())}]'))
      ..removeWhere((t) => t.isEmpty);

/// Fuzzy matching helpers for autocomplete dropdowns and lookups.
class FuzzyMatch {
  FuzzyMatch._();

  /// Order-independent substring test for autocomplete dropdowns. A
  /// [candidate] qualifies if it contains the whole [query] as a
  /// contiguous substring, or contains every token of the query
  /// somewhere (in any order) — "scrambled eggs" surfaces a stored
  /// "eggs, scrambled" and vice-versa. A blank query matches nothing.
  static bool matchesQuery(String query, String candidate) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    final c = candidate.toLowerCase();
    if (c.contains(q)) return true;
    final qTokens = _tokens(q);
    if (qTokens.isEmpty) return false;
    return qTokens.every(c.contains);
  }

  /// Word-order variants of [query], original first, for retrying an
  /// online lookup that's sensitive to word order ("scrambled eggs" vs
  /// "eggs scrambled"). Single-word queries yield just themselves.
  /// Bounded to [max] variants (reversal first, then rotations) so a
  /// caller firing one network load per variant stays cheap.
  static List<String> wordOrderVariants(String query, {int max = 3}) {
    final tokens = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final original = tokens.join(' ');
    if (tokens.length < 2 || max < 1) return [original];
    final variants = <String>{original, tokens.reversed.join(' ')};
    var i = 1;
    while (variants.length < max && i < tokens.length) {
      variants.add([...tokens.sublist(i), ...tokens.take(i)].join(' '));
      i++;
    }
    return variants.take(max).toList();
  }

  /// The best-scoring [candidates] for [query], most similar first.
  /// Exact matches are excluded (the caller already has those); queries
  /// under two characters yield nothing.
  static List<String> suggest(
    String query,
    Iterable<String> candidates, {
    int max = 3,
  }) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    final qTokens = _tokens(q);
    if (qTokens.isEmpty) return const [];

    final scored = <(String, double)>[];
    for (final candidate in candidates) {
      final cl = candidate.toLowerCase();
      if (cl == q) continue;
      final s = _score(q, qTokens, cl);
      if (s > 0.0) scored.add((candidate, s));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final (c, _) in scored.take(max)) c];
  }

  static double _score(
    String query,
    List<String> queryTokens,
    String candidate,
  ) {
    if (candidate.contains(query)) {
      final len = candidate.isEmpty ? 1 : candidate.length;
      return 1.0 + query.length / len;
    }
    final cTokens = _tokens(candidate);
    if (cTokens.isEmpty) return 0.0;

    var sum = 0.0;
    for (final qt in queryTokens) {
      var best = 0.0;
      for (final ct in cTokens) {
        final s = _tokenSimilarity(qt, ct);
        if (s > best) best = s;
      }
      sum += best;
    }
    final avg = sum / queryTokens.length;
    return avg >= 0.55 ? avg : 0.0;
  }

  static double _tokenSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.length < 2 || b.length < 2) return 0.0;
    if (b.startsWith(a) || a.startsWith(b)) return 0.95;
    if (b.contains(a) || a.contains(b)) return 0.8;
    final dist = _levenshtein(a, b);
    final maxLen = a.length > b.length ? a.length : b.length;
    final sim = 1.0 - dist / maxLen;
    return sim >= 0.6 ? sim : 0.0;
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    var prev = List<int>.generate(b.length + 1, (i) => i);
    var curr = List<int>.filled(b.length + 1, 0);
    for (var i = 1; i <= a.length; i++) {
      curr[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        var min = curr[j - 1] + 1;
        if (prev[j] + 1 < min) min = prev[j] + 1;
        if (prev[j - 1] + cost < min) min = prev[j - 1] + cost;
        curr[j] = min;
      }
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[b.length];
  }
}
