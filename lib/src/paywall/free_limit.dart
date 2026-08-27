/// Thrown when an action would exceed a [FreeLimit] without the unlock.
/// Never thrown for actions on existing data — only *adding* past the
/// cap is ever gated.
class FreeLimitReachedException implements Exception {
  /// Creates the exception with the limit that was hit.
  const FreeLimitReachedException(this.limit);

  /// The free-tier cap that blocked the action.
  final int limit;
}

/// One app's free-tier quota: this many of the gated subject, forever.
/// Existing data is never gated — the limit only blocks *adding* a new
/// one. An app's limit must only ever move UP across releases.
///
/// `FreeLimit(5, 'restaurants')` renders "2 of 5 free restaurants used";
/// apps with bespoke wording pass [detailBuilder].
class FreeLimit {
  /// Creates a quota of [count] with the plural [subjectLabel]
  /// ("restaurants", "elements") used in the standard usage strings.
  const FreeLimit(this.count, this.subjectLabel, {this.detailBuilder});

  /// The cap. Free users keep this many forever.
  final int count;

  /// Plural label for the gated subject, as it should read in
  /// "2 of 5 free {subjectLabel} used".
  final String subjectLabel;

  /// Optional app wording for the one-line "what happens next" detail,
  /// given how many free slots remain; null uses generic wording.
  final String Function(int remaining)? detailBuilder;

  /// True when [used] has consumed the whole quota.
  bool isReached(int used) => used >= count;

  /// The single gate check: throws [FreeLimitReachedException] when a
  /// non-entitled user is at the cap. Call it right before creating a
  /// new gated item; never call it for edits or reads.
  void guard({required int used, required bool entitled}) {
    if (!entitled && isReached(used)) {
      throw FreeLimitReachedException(count);
    }
  }

  /// Snapshot of how much of the quota [used] consumes, for counter UI.
  FreeLimitUsage usage(int used) => FreeLimitUsage._(this, used);
}

/// How much of a [FreeLimit] is used — "2 of 5", plus ready-made copy
/// for counter and paywall UI.
class FreeLimitUsage {
  const FreeLimitUsage._(this._freeLimit, this.used);

  final FreeLimit _freeLimit;

  /// How many of the gated subject exist.
  final int used;

  /// The cap, echoed from the [FreeLimit].
  int get limit => _freeLimit.count;

  /// Free slots left, never negative.
  int get remaining => (limit - used).clamp(0, limit);

  /// True when the whole quota is consumed.
  bool get atLimit => used >= limit;

  /// Headline for counter UI: "2 of 5 free restaurants used".
  String get label => '$used of $limit free ${_freeLimit.subjectLabel} used';

  /// One line on what happens next; app wording via
  /// [FreeLimit.detailBuilder], else generic.
  String get detail =>
      _freeLimit.detailBuilder?.call(remaining) ??
      switch (remaining) {
        0 => 'Free ${_freeLimit.subjectLabel} all used — '
            'unlock to add more.',
        1 => '1 more free — then the unlock.',
        final n => '$n more free — then the unlock.',
      };
}
