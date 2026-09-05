# journal/ module — design proposal (decision needed)

The last empty module. Factory Phase 4 said "extract entry/tag/rating/
photo models and Drift repo from Table Encore; apps keep their domain
tables and join to core journal tables." Reality found during Course
Ledger's build: **there is nothing to extract.** Table Encore keeps
notes/photos/ratings as columns on its own domain tables (visits,
dishes), and Course Ledger shipped the same shape (rounds.notes +
round_photos) deliberately mirroring it. Two apps have now proven that
shape works.

So the question isn't "how do we extract it" — it's "what shared value
would core journal tables actually add, at what migration cost?"

## What the apps actually share

| Concern | Table Encore | Course Ledger | Shared? |
| --- | --- | --- | --- |
| Free-text story/notes | visits.notes, dishes.notes | rounds.notes | Shape only — one nullable text column |
| 1–5 rating | dishes.satisfaction/enjoyment (two!) | courses.rating, rounds.rating | Shape only — apps disagree on how many and on what |
| Photos on an entry | dishes.photoPath (single) | round_photos table (many) | Divergent already |
| Photo *files* on disk | PhotoFileStore (discard on row delete) | needed for Phase-later capture UI | **Yes — real logic** |
| Attachment UI | app-built | not built yet | **Yes — would be** |
| Search across notes | history search SQL | not built yet | Maybe later |

The columns are trivial; the *file lifecycle* (photos directory,
discard-on-delete, backup collection) and the *attachment UI* (picker,
thumbnail strip, viewer) are the parts with actual weight — and they're
exactly what both apps duplicate or are about to.

## Options

**A. Minimal journal/ — the photo seam + widgets (recommended).**
Extract Table Encore's `PhotoFileStore` (file naming, transient
acquire, discard) into core; add a `PhotoAttachments` Drift table
definition apps can include (`entryTable`/`entryId` naming theirs), an
attachment-strip widget (thumbnails + add/remove, picker injected), and
a photo-collection helper for the backup archive. Notes and ratings
stay domain columns — two apps say that's the right home. No schema
migration in either shipped app; Course Ledger adopts wholesale for its
round-photo capture UI, Table Encore adopts the store and keeps its
single-photo column until it wants multi-photo dishes.

**B. Full core journal tables (the original factory plan).**
`journal_entries` + `journal_photos` in core; apps add an FK from their
domain rows. Buys shared search/repo at the cost of Drift migrations in
two shipped apps ("data loss is unacceptable"), a join on every
notes read, and forcing the two-ratings/one-rating disagreement into
one schema. High cost, thin gain — not recommended until a third app
demands shared search.

**C. Do nothing until app #3.**
Cheapest today; but Course Ledger's photo capture UI is next on its
backlog and would duplicate PhotoFileStore a second time, which is the
exact signal that triggered every other extraction.

## Recommendation

Option A, as cc_core 0.12.0: `journal/` = photo file store + attachment
table definition + attachment UI, documented as "the journal is the
app's own tables; core owns what golfers and diners attach to it."
Close the factory Phase 4 line item with that scope; revisit B only if
a future app needs cross-domain search.

**Waiting on a call before any code.**
