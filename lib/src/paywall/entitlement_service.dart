import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:stream_transform/stream_transform.dart';

import 'kv_store.dart';
import 'store_products.dart';

/// Owns the "has the lifetime unlock / active subscription" questions.
/// Local-cache-first so the answer works offline; the store's purchase
/// stream keeps it honest. App-specific product ids are injected via
/// [StoreProducts] — nothing in here belongs to any one app.
abstract class EntitlementService {
  /// True with the lifetime unlock OR an active premium subscription —
  /// premium includes the unlock.
  Future<bool> isUnlimited();

  /// Emits the current value immediately, then again on changes.
  Stream<bool> watchUnlimited();

  /// True while the premium subscription is active. Cache-first like the
  /// unlock; "Restore purchases" refreshes it from the store. Always
  /// false for apps without a subscription product.
  Future<bool> isPremium();

  /// Emits the current premium state immediately, then again on changes.
  Stream<bool> watchPremium();

  /// Store display price for the unlock, null when the store is
  /// unavailable (emulator without Play, desktop dev) or the app sells
  /// no lifetime unlock.
  Future<String?> unlimitedPrice();

  /// Store display price for the subscription's first base plan, null
  /// when the store is unavailable or the app sells no subscription.
  /// Multi-plan apps should show [premiumPlans] instead.
  Future<String?> premiumPrice();

  /// The subscription's purchasable base plans with live store prices,
  /// in [StoreProducts.premiumPlanLabels] order; empty when the store
  /// is unavailable or the app sells no subscription.
  Future<List<SubscriptionPlan>> premiumPlans();

  /// The app's tip products with live store prices; empty when the
  /// store is unavailable or no tips are configured.
  Future<List<TipProduct>> tipProducts();

  /// Launches the unlock purchase flow. Entitlement lands asynchronously
  /// via the purchase stream; watch [watchUnlimited] for the outcome.
  /// Throws [StateError] when the app sells no lifetime unlock.
  Future<void> buyUnlimited();

  /// Launches the subscription purchase flow; watch [watchPremium].
  /// [planId] selects a base plan from [premiumPlans] (required for a
  /// multi-plan subscription to be deterministic; omitted, the store's
  /// first offer is bought).
  Future<void> buyPremium({String? planId});

  /// Launches a consumable tip purchase.
  Future<void> buyTip(String productId);

  /// Asks the store to replay owned purchases onto the purchase stream.
  Future<void> restorePurchases();

  /// Called once on app start: re-checks ownership with the store and
  /// clears the cached premium entitlement if the subscription lapsed.
  /// Only downgrades on a definitive store answer — offline or store
  /// errors keep the cache, preserving the offline-first promise.
  Future<void> refreshEntitlements();

  /// Human-readable store failures (failed purchases, restore errors)
  /// as they happen, for surfacing in whatever paywall UI is open.
  /// Without a listener the failures still go to the debug log.
  Stream<String> get storeErrors;

  /// Cancels the purchase-stream subscription and closes change streams.
  void dispose();
}

/// [EntitlementService] backed by the real store via the
/// in_app_purchase plugin, with a [KeyValueStore] entitlement cache.
///
/// Cache keys are `entitlement.unlimited` / `entitlement.premium` —
/// stable across cc_core versions so existing installs keep their
/// entitlements when an app migrates onto this class.
class StoreEntitlementService implements EntitlementService {
  /// Creates the service and starts listening to the purchase stream.
  /// [iap] is injectable for tests; defaults to the real plugin.
  StoreEntitlementService(this._kv, this._products, {InAppPurchase? iap})
      : _iap = iap ?? InAppPurchase.instance {
    _subscription = _iap.purchaseStream.listen(_onPurchases);
  }

  static const _cacheKey = 'entitlement.unlimited';
  static const _premiumCacheKey = 'entitlement.premium';

  final KeyValueStore _kv;
  final StoreProducts _products;
  final InAppPurchase _iap;
  late final StreamSubscription<List<PurchaseDetails>> _subscription;
  final _changes = StreamController<bool>.broadcast();
  final _premiumChanges = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();

  /// Set while [refreshEntitlements] runs: collects every restored
  /// product id the purchase stream delivers, across however many
  /// events the platform spreads them over (Android sends one batch;
  /// iOS StoreKit 2 sends one event per transaction — and none at all
  /// when nothing is owned).
  Set<String>? _restoredDuringRefresh;

  @override
  Stream<String> get storeErrors => _errors.stream;

  void _reportError(String message) {
    debugPrint('[cc_core.paywall] $message');
    _errors.add(message);
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      debugPrint(
          '[cc_core.paywall] ${purchase.productID}: ${purchase.status.name}');
      if (purchase.status == PurchaseStatus.error) {
        _reportError('Purchase failed for ${purchase.productID}: '
            '${purchase.error?.message ?? 'unknown store error'}');
      }
      final owned = purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored;
      if (owned && purchase.productID == _products.lifetimeUnlock) {
        await _kv.setBool(_cacheKey, true);
        _changes.add(true);
      }
      if (owned && purchase.productID == _products.premiumSubscription) {
        await _kv.setBool(_premiumCacheKey, true);
        _premiumChanges.add(true);
      }
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    _restoredDuringRefresh?.addAll([
      for (final p in purchases)
        if (p.status == PurchaseStatus.restored) p.productID,
    ]);
  }

  @override
  Future<void> refreshEntitlements() async {
    // No subscription product means nothing can lapse.
    final premiumId = _products.premiumSubscription;
    if (premiumId == null) return;
    try {
      if (!await _iap.isAvailable()) return;
      final restored = _restoredDuringRefresh = <String>{};
      // Both platform plugins dispatch every owned purchase onto the
      // purchase stream before this future completes, so once it
      // returns without throwing the store has given its definitive
      // ownership answer — the drain below just waits out the stream
      // delivery, stopping once no new ids arrive for a beat.
      await _iap.restorePurchases();
      var lastCount = -1;
      for (var i = 0; i < 10 && restored.length != lastCount; i++) {
        lastCount = restored.length;
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      if (!restored.contains(premiumId) &&
          (await _kv.getBool(_premiumCacheKey) ?? false)) {
        await _kv.setBool(_premiumCacheKey, false);
        // watchUnlimited merges this stream, so a lapse also re-gates
        // the free-tier cap unless the lifetime unlock is owned.
        _premiumChanges.add(false);
      }
    } on Exception catch (e) {
      // Store unreachable or restore failed: keep the cache, but say
      // so — a silent failure here looks like a lost entitlement.
      _reportError('Entitlement refresh failed: $e');
    } finally {
      _restoredDuringRefresh = null;
    }
  }

  @override
  Future<bool> isUnlimited() async =>
      (await _kv.getBool(_cacheKey) ?? false) || await isPremium();

  @override
  Stream<bool> watchUnlimited() async* {
    yield await isUnlimited();
    // Premium includes the unlock, so either purchase can flip this.
    yield* _changes.stream
        .merge(_premiumChanges.stream)
        .asyncMap((_) => isUnlimited());
  }

  @override
  Future<bool> isPremium() async =>
      _products.premiumSubscription != null &&
      (await _kv.getBool(_premiumCacheKey) ?? false);

  @override
  Stream<bool> watchPremium() async* {
    yield await isPremium();
    yield* _premiumChanges.stream;
  }

  Future<ProductDetails?> _product(String? id) async {
    if (id == null) return null;
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({id});
    return response.productDetails.firstOrNull;
  }

  /// Every store offer for the subscription. Google Play returns one
  /// [ProductDetails] per base-plan offer under the same product id.
  Future<List<ProductDetails>> _premiumOffers() async {
    final premiumId = _products.premiumSubscription;
    if (premiumId == null) return const [];
    if (!await _iap.isAvailable()) return const [];
    final response = await _iap.queryProductDetails({premiumId});
    return response.productDetails;
  }

  /// The Play base plan id behind [details], null on platforms that
  /// don't expose base plans (a StoreKit subscription is one plan).
  static String? _basePlanIdOf(ProductDetails details) =>
      details is GooglePlayProductDetails && details.subscriptionIndex != null
          ? details.productDetails
              .subscriptionOfferDetails![details.subscriptionIndex!].basePlanId
          : null;

  /// True for a base plan's standard offer (no offerId) as opposed to a
  /// promotional/intro offer layered on it — the one to show and buy by
  /// default.
  static bool _isBaseOffer(ProductDetails details) =>
      details is! GooglePlayProductDetails ||
      details.subscriptionIndex == null ||
      details.productDetails
              .subscriptionOfferDetails![details.subscriptionIndex!].offerId ==
          null;

  ProductDetails? _offerForPlan(List<ProductDetails> offers, String planId) {
    final ofPlan = [
      for (final o in offers)
        if (_basePlanIdOf(o) == planId || o.id == planId) o
    ];
    if (ofPlan.isEmpty) return null;
    return ofPlan.firstWhere(_isBaseOffer, orElse: () => ofPlan.first);
  }

  @override
  Future<String?> unlimitedPrice() async =>
      (await _product(_products.lifetimeUnlock))?.price;

  @override
  Future<String?> premiumPrice() async =>
      (await _product(_products.premiumSubscription))?.price;

  @override
  Future<List<SubscriptionPlan>> premiumPlans() async {
    final offers = await _premiumOffers();
    if (offers.isEmpty) return const [];
    final labels = _products.premiumPlanLabels;
    if (labels.isEmpty) {
      // Single-plan app: derive plans from the store's base offers.
      return [
        for (final o in offers)
          if (_isBaseOffer(o))
            SubscriptionPlan(
                id: _basePlanIdOf(o) ?? o.id,
                label: _basePlanIdOf(o) ?? o.id,
                price: o.price),
      ];
    }
    return [
      for (final MapEntry(key: planId, value: label) in labels.entries)
        if (offers.any((o) => _basePlanIdOf(o) == planId || o.id == planId))
          SubscriptionPlan(
              id: planId,
              label: label,
              price: _offerForPlan(offers, planId)!.price),
    ];
  }

  @override
  Future<List<TipProduct>> tipProducts() async {
    if (_products.tipLabels.isEmpty) return const [];
    if (!await _iap.isAvailable()) return const [];
    final response =
        await _iap.queryProductDetails(_products.tipLabels.keys.toSet());
    final byId = {for (final p in response.productDetails) p.id: p};
    return [
      for (final MapEntry(key: id, value: label)
          in _products.tipLabels.entries)
        if (byId[id] != null)
          TipProduct(id: id, label: label, price: byId[id]!.price),
    ];
  }

  @override
  Future<void> buyUnlimited() async {
    if (_products.lifetimeUnlock == null) {
      throw StateError('This app has no lifetime unlock product.');
    }
    final product = await _product(_products.lifetimeUnlock);
    if (product == null) throw const StoreUnavailableException();
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> buyPremium({String? planId}) async {
    if (_products.premiumSubscription == null) {
      throw StateError('This app has no premium subscription product.');
    }
    final offers = await _premiumOffers();
    if (offers.isEmpty) throw const StoreUnavailableException();
    // A GooglePlayProductDetails carries its offer token, so picking
    // the right ProductDetails is what selects the base plan.
    final product =
        planId == null ? offers.first : _offerForPlan(offers, planId);
    if (product == null) {
      throw ArgumentError.value(
          planId, 'planId', 'not among the store\'s offers');
    }
    // Subscriptions go through buyNonConsumable in in_app_purchase.
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> buyTip(String productId) async {
    final product = await _product(productId);
    if (product == null) throw const StoreUnavailableException();
    await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> restorePurchases() async {
    if (!await _iap.isAvailable()) throw const StoreUnavailableException();
    await _iap.restorePurchases();
  }

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    unawaited(_changes.close());
    unawaited(_premiumChanges.close());
    unawaited(_errors.close());
  }
}
