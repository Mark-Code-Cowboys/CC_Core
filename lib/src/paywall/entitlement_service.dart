import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
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
  /// unavailable (emulator without Play, desktop dev).
  Future<String?> unlimitedPrice();

  /// Store display price for the subscription, null when the store is
  /// unavailable or the app sells no subscription.
  Future<String?> premiumPrice();

  /// The app's tip products with live store prices; empty when the
  /// store is unavailable or no tips are configured.
  Future<List<TipProduct>> tipProducts();

  /// Launches the unlock purchase flow. Entitlement lands asynchronously
  /// via the purchase stream; watch [watchUnlimited] for the outcome.
  Future<void> buyUnlimited();

  /// Launches the subscription purchase flow; watch [watchPremium].
  Future<void> buyPremium();

  /// Launches a consumable tip purchase.
  Future<void> buyTip(String productId);

  /// Asks the store to replay owned purchases onto the purchase stream.
  Future<void> restorePurchases();

  /// Called once on app start: re-checks ownership with the store and
  /// clears the cached premium entitlement if the subscription lapsed.
  /// Only downgrades on a definitive store answer — offline or store
  /// errors keep the cache, preserving the offline-first promise.
  Future<void> refreshEntitlements();

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

  /// Set while [refreshEntitlements] waits for the restore batch that
  /// restorePurchases() pushes onto the purchase stream.
  Completer<Set<String>>? _pendingRefresh;

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
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
    // A restore batch (possibly empty — nothing owned) is the store's
    // definitive ownership answer; hand it to a waiting refresh.
    final restoredIds = <String>{
      for (final p in purchases)
        if (p.status == PurchaseStatus.restored) p.productID,
    };
    final isRestoreBatch =
        purchases.isEmpty || restoredIds.length == purchases.length;
    final refresh = _pendingRefresh;
    if (isRestoreBatch && refresh != null && !refresh.isCompleted) {
      refresh.complete(restoredIds);
    }
  }

  @override
  Future<void> refreshEntitlements() async {
    // No subscription product means nothing can lapse.
    final premiumId = _products.premiumSubscription;
    if (premiumId == null) return;
    try {
      if (!await _iap.isAvailable()) return;
      final refresh = _pendingRefresh = Completer<Set<String>>();
      await _iap.restorePurchases();
      final owned = await refresh.future.timeout(const Duration(seconds: 15));
      if (!owned.contains(premiumId) &&
          (await _kv.getBool(_premiumCacheKey) ?? false)) {
        await _kv.setBool(_premiumCacheKey, false);
        // watchUnlimited merges this stream, so a lapse also re-gates
        // the free-tier cap unless the lifetime unlock is owned.
        _premiumChanges.add(false);
      }
    } on Exception {
      // Store unreachable or no restore response: keep the cache.
    } finally {
      _pendingRefresh = null;
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

  Future<ProductDetails?> _product(String id) async {
    if (!await _iap.isAvailable()) return null;
    final response = await _iap.queryProductDetails({id});
    return response.productDetails.firstOrNull;
  }

  @override
  Future<String?> unlimitedPrice() async =>
      (await _product(_products.lifetimeUnlock))?.price;

  @override
  Future<String?> premiumPrice() async {
    final premiumId = _products.premiumSubscription;
    if (premiumId == null) return null;
    return (await _product(premiumId))?.price;
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
    final product = await _product(_products.lifetimeUnlock);
    if (product == null) throw const StoreUnavailableException();
    await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product));
  }

  @override
  Future<void> buyPremium() async {
    final premiumId = _products.premiumSubscription;
    if (premiumId == null) {
      throw StateError('This app has no premium subscription product.');
    }
    final product = await _product(premiumId);
    if (product == null) throw const StoreUnavailableException();
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
  }
}
