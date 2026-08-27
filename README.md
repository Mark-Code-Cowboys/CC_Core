# cc_core

Shared Flutter library powering all Code Cowboys apps — privacy-first,
local-only journal/log apps stamped from one core.

**Design rules:** no accounts, no cloud sync, no third-party analytics.
All data stays on-device (Drift/sqlite). Store-routed payments only.

## Consuming

Apps depend on `cc_core` as a git dependency pinned to a tag:

```yaml
dependencies:
  cc_core:
    git:
      url: git@github.com:Mark-Code-Cowboys/cc_core.git
      ref: v0.x.0
```

For local iteration, use a git-ignored `pubspec_overrides.yaml` with a
`path:` override to your local checkout. The tag ref is what ships.

## Modules

Each module lives under `lib/src/<module>/` and is exported through its
own barrel file, re-exported by `lib/cc_core.dart`.

| Module | Purpose |
| --- | --- |
| `paywall/` | Billing wrapper, entitlement cache, `FreeLimit` quota helper, `EntitlementGate` widget, paywall sheet scaffold |
| `io/` | Export (CSV/JSON), backup/restore (single-file archive), PDF export |
| `journal/` | Entry/tag/rating/photo-attachment models, Drift repository, search |
| `trends/` | Calendar heatmap, time-window queries, basic chart widgets |
| `onboarding/` | First-run flow, consent/privacy screen, "your data never leaves your phone" boilerplate |
| `theme/` | Base theme consuming a per-app token class (colors, type scale, corner radii) |
| `scan/` | AI photo-extraction client (menu/receipt/notebook-page → structured fields → user-confirm screen). Per-app extraction schema injected; core owns the pipeline, camera/crop UX, and confirm-before-save screen |
| `notebook_import/` | Batch flavor of `scan/`: multi-page capture → queued extraction → review list → bulk insert |

## Module guides

### paywall

Extracted from Table Encore's billing implementation; riverpod-free so
apps keep their own state wiring.

- `StoreProducts` — the app's catalog: one lifetime unlock, optional
  premium subscription, optional tip products with labels.
- `EntitlementService` / `StoreEntitlementService` — cache-first
  entitlements over `in_app_purchase`; works offline, the purchase
  stream keeps it honest, `refreshEntitlements()` (call once on app
  start) downgrades a lapsed subscription only on a definitive store
  answer. Cache keys `entitlement.unlimited` / `entitlement.premium`
  are stable across versions.
- `FreeLimit(count, subjectLabel)` — the free-tier quota.
  `guard(used:, entitled:)` throws `FreeLimitReachedException` at the
  cap; `usage(used)` yields counter/paywall copy (`label`, `detail`,
  overridable via `detailBuilder`).
- `EntitlementGate` — shows its child when entitled, otherwise
  intercepts interaction and opens the app's paywall. Closed while
  entitlements load.
- `PaywallSheetScaffold` + `PaywallBenefit` + `showPaywallModal` +
  `runStoreAction` — shared sheet layout and store-error handling;
  apps own all copy and callbacks.
- `KeyValueStore` (`SharedPrefsStore`, `InMemoryKeyValueStore`) and
  `FakeEntitlementService` — persistence seam and test fake.

```dart
const products = StoreProducts(
  lifetimeUnlock: 'myapp_unlimited',
  premiumSubscription: 'myapp_premium_annual',
);
const freeLimit = FreeLimit(5, 'entries');

final service = StoreEntitlementService(SharedPrefsStore(), products);
unawaited(service.refreshEntitlements());

// Gating a create action:
freeLimit.guard(used: await repo.count(), entitled: await service.isUnlimited());
```

## Status

Bootstrap only — module folders and barrel files are in place; extraction
from Table Encore and Trace Elements happens phase by phase.
