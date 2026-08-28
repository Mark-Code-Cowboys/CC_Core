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
