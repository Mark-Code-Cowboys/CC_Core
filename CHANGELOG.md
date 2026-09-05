## 0.12.0

* journal: the module exists — option B of docs/journal-module-design.md,
  chosen for the coming fleet. Shared Drift tables apps register in
  their own database (`JournalEntries` notes/rating, `JournalPhotos`,
  `JournalTags`, all with `@UseRowClass` so every app maps to the same
  row types; domain rows point at entries via a nullable
  journalEntryId — deleting a domain row is the app's cue to call
  `deleteEntries`). `JournalRepository` is generic over the generated
  table classes: create/update/delete with photo-file discard, photo
  and tag management, `watchEntry`, `getEntries` for list joins,
  `searchEntryIds` (notes + tags), and `collectMedia` for backup
  archives. Plus the photo seam extracted from Table Encore:
  `PhotoFileStore`/`PhotoService`/`ImagePickerPhotoService` (file-name
  prefix injected) and the `PhotoAttachmentStrip` composer widget.
  drift moves from dev to a real dependency; image_picker added (both
  apps already ship it). Course Ledger is the proving consumer (schema
  v2 migration); Table Encore adoption is a separate pass — its
  dish-level double ratings and single-photo column need their own
  design read.

## 0.11.0

* theme: the module exists — `CcThemeTokens` (seed color, optional
  hand-tuned scheme per brightness) and `ccLightTheme`/`ccDarkTheme`
  over the base both apps had hand-copied (surface-colored scaffold and
  app bar). Type scale and corner radii join when an app varies them.
* trends: `countHeadline` + `CountedSubject` — the "47 courses ·
  12 states" home-screen line, extracted from Course Ledger; zero
  counts drop after the lead subject, irregular plurals supported.

## 0.10.0

* onboarding: the module exists — `FirstRunFlag` (persisted seen-flag
  over `KeyValueStore`) and `OnboardingScaffold` (hero icon, the app's
  positioning line front and center, supporting copy, the
  `kPrivacyBoilerplate` promise, and the app's fork of starting
  actions). Designed fresh with Course Ledger — Table Encore has no
  first-run flow to extract — so the API may shift when a second
  consumer adopts it.

## 0.9.0

* trends: first real contents, driven by Course Ledger's Phase E —
  `TrendGate` (charts render only past a minimum point count; below it,
  the app's nudge line — ledgers, not dashboards), `YearlyBars` (counts
  per year, gap years shown as zero), `SimpleLineChart` (plain polyline
  over time, range and endpoint labels only), and `RegionTileGrid` +
  `usStateTiles` (offline tile-cartogram coverage map, no map tiles or
  geo data). The Trace Elements calendar-heatmap extraction remains.
* io: single-file backup archive extracted from Table Encore —
  `buildBackupArchive`/`readBackupArchive`/`BackupContents`/
  `InvalidBackupException`, entry names parameterized so Table Encore's
  `journal.json` + `photos/` backups stay readable; traversal-shaped
  media names are dropped on read. New dependency: archive (Table
  Encore's pin).
* io: `buildCsv` — RFC 4180 encoder, the inverse of `parseCsv`.
* io: `ShareLauncher` seam (+ `FakeShareLauncher`) extracted from Table
  Encore; apps keep their share_plus wrapper.

## 0.8.0

* scan: the module exists — on-device photo transcription extracted
  from Table Encore's OCR core for Course Ledger's scorecard import.
  `OcrLine` + `mergeOcrRows` (row re-assembly), `DocumentScanService`
  (now with multi-page `scanAll` for batch flows) with the ML Kit
  implementation, `TextRecognitionService` (Table Encore's
  `ReceiptOcrService`, renamed — nothing in it was receipt-specific)
  with ML Kit implementation and a canned-lines fake. Adds the two
  `google_mlkit_*` dependencies Table Encore already ships. Guardrail
  documented on the barrel: transcription only — parsers and confirm
  UIs never suggest, correct, or flag values.
* notebook_import: the batch flavor — `batchTranscribe` (OCR every
  captured page through an injected parser; unreadable pages counted,
  unparseable ones skipped) and `BatchReviewScreen` (check-off/edit
  review list with one bulk-confirm button).
* io: `parseCsv`/`CsvDocument` — forgiving RFC 4180 parsing for the
  import-mapper flows ("spreadsheet keepers").
* Table Encore adoption (later, no rush): its `core/ocr/` types and
  ML Kit services are now duplicates of the scan module.

## 0.7.0

* paywall: `LifetimeTally` — how many of the gated subject were ever
  created on this device, persisted via `KeyValueStore` under an
  injected key. Extracted from Table Encore's `RestaurantTally` when
  Course Ledger became its second consumer: deleting never lowers it
  (a free slot can't be recycled by delete-and-re-add), `recordCreated`
  floors at the live row count for pre-tally installs, `raiseTo` lets
  backup restores carry the figure between phones. Table Encore can
  adopt it by passing its existing `restaurants_created_lifetime` key.
* paywall: `PaywallSheetScaffold` scrolls when its content is taller
  than the sheet (small screens, long benefit lists) instead of
  overflowing; unchanged when everything fits.

## 0.6.1

* text: `FuzzyMatch.suggest` no longer credits a candidate token that is
  only a fragment of the query token as a near-exact prefix match — the
  "st" of "St. john's wort" scored 0.95 against "strips" and "style",
  so Trace Elements' menu-scan description fallback resolved a fajitas
  description to the herb. A candidate token must now cover at least
  60% of the query token (scaled score), while the query-begins-the-
  candidate direction (typing "st" for "strawberries") is unchanged.

## 0.6.0

* paywall: subscriptions sold as one product per plan. The App Store
  has no base plans — "monthly" and "yearly" are two products in one
  subscription group — so `StoreProducts` gains `premiumPlanProducts`
  (plan id → product id). Owning any mapped product is the premium
  entitlement, `premiumPlans()` queries and prices them in catalog
  order, `buyPremium(planId:)` buys the mapped product, and the
  entitlement refresh treats a restore of any of them as active.
  `premiumSubscription` is now optional when plan products are given;
  the "sells an unlock or a subscription" rule moved from the const
  constructor's assert (a map's emptiness isn't a constant expression)
  to `StoreEntitlementService`'s constructor. Google Play callers are
  unchanged.

## 0.5.2

* io: `GoogleDriveBackupService` tries the silent reattach at most once
  per process. The plugin's lightweight path falls back to an unfiltered
  One Tap sheet, so status reads on every screen open re-prompted the
  user 4–5 times per visit; after one miss, non-interactive callers get
  the remembered account and transfers go straight to the explicit
  sign-in.

## 0.5.1

* io: `GoogleDriveBackupService` remembers the attached account
  (optional `KeyValueStore`, key `accountKey`) and reconnects
  interactively only when a transfer needs it. Google Play services
  refuses One Tap reattach (status 28444) after a button-flow sign-in,
  so `currentAccount()` reported "not signed in" on every cold start.
  `latestBackup()` never pops the account picker; it throws the new
  `CloudSignInRequiredException` (a `CloudUnavailableException`) when
  a silent reattach is not possible, so screens can show a neutral hint.

## 0.5.0

* io: cloud backup, extracted from Table Encore and extended to iCloud.
  `CloudBackupService` (one backup slot in the *user's own* cloud, no
  developer servers) with `providerName`/`requiresSignIn` so screens
  adapt their copy; `GoogleDriveBackupService(GoogleDriveConfig)` —
  Drive app-data folder, client IDs per app; `ICloudBackupService` —
  the app's iCloud container root (hidden from the Files app), device
  Apple ID, polls metadata so tiny uploads that beat the plugin's
  progress query still settle; `InMemoryCloudBackupService` test fake.
  New dependencies: google_sign_in, http, icloud_storage.

## 0.4.0

* io: `LegacyAndroidPrefs`, a pure-Dart reader for native Android
  SharedPreferences XML (KMP/native → Flutter rewrite migrations).
* paywall: `KeyValueStore` gains getString/setString,
  getDouble/setDouble, and `contains` (never-written detection).
* text: new module — `FuzzyMatch` (order-independent matching,
  Levenshtein-backed suggestions, word-order variants) and
  `toDecimalString` (half-to-even fixed-decimal formatting), extracted
  from Trace Elements with their donor test suites.

## 0.3.0

* paywall: `StoreProducts.lifetimeUnlock` is now optional — apps that
  sell subscription + tips only (no one-time unlock) are a supported
  catalog shape. `buyUnlimited` on such an app is a `StateError`;
  `unlimitedPrice` is null. At least one of unlock/subscription must be
  configured (asserted).
* paywall: subscriptions with multiple base plans (monthly/yearly under
  one product id). New `StoreProducts.premiumPlanLabels` catalog map,
  `EntitlementService.premiumPlans()` returning `SubscriptionPlan` rows
  with live per-plan prices (base offers preferred over discounted
  ones), and `buyPremium({planId})` for plan selection via the matching
  Google Play offer token. Single-plan apps keep `premiumPrice()` /
  `buyPremium()` unchanged.

## 0.2.0

* paywall: entitlement refresh is now correct on iOS. StoreKit 2
  delivers restored purchases as one stream event per transaction (and
  zero events when nothing is owned), so the old first-batch completer
  could judge a multi-entitlement restore from its first event alone —
  and could never detect a lapse on iOS. The refresh now collects the
  union of restored ids across events, draining until the stream goes
  quiet, before deciding whether cached premium lapsed.
* paywall: store failures are no longer silent. `EntitlementService`
  gains a `storeErrors` stream (failed purchases, restore/refresh
  errors) for snackbar surfacing; every purchase-stream event and
  swallowed refresh error is also `debugPrint`ed for logcat, and
  `runStoreAction` now reports unexpected store exceptions instead of
  letting them vanish as unhandled async errors.

## 0.1.0

* paywall module, extracted from Table Encore and verified on-device:
  `StoreProducts`, `EntitlementService`/`StoreEntitlementService`
  (cache-first, offline-safe lapse refresh, restore path), `FreeLimit`
  quota helper, `EntitlementGate`, `PaywallSheetScaffold` + helpers,
  `KeyValueStore`, `FakeEntitlementService`.

## 0.0.1

* Repo bootstrap: module skeleton, barrel files, strict lints.
