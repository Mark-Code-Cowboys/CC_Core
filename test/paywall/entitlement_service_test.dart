import 'dart:async';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mocktail/mocktail.dart';

class _MockIap extends Mock implements InAppPurchase {}

class _FakePurchaseParam extends Fake implements PurchaseParam {}

class _FakePurchaseDetails extends Fake implements PurchaseDetails {}

const _products = StoreProducts(
  lifetimeUnlock: 'app_unlimited',
  premiumSubscription: 'app_premium_annual',
  tipLabels: {
    'app_tip_small': 'Espresso',
    'app_tip_large': 'The whole pot',
  },
);

PurchaseDetails _purchase(String id, PurchaseStatus status,
    {bool pendingComplete = false}) {
  final details = PurchaseDetails(
    productID: id,
    verificationData: PurchaseVerificationData(
        localVerificationData: 'test',
        serverVerificationData: 'test',
        source: 'test'),
    transactionDate: null,
    status: status,
  );
  details.pendingCompletePurchase = pendingComplete;
  return details;
}

ProductDetails _productDetails(String id, String price) => ProductDetails(
    id: id,
    title: id,
    description: id,
    price: price,
    rawPrice: 1.0,
    currencyCode: 'USD');

void main() {
  setUpAll(() {
    registerFallbackValue(_FakePurchaseParam());
    registerFallbackValue(_FakePurchaseDetails());
  });

  late _MockIap iap;
  late StreamController<List<PurchaseDetails>> purchases;
  late InMemoryKeyValueStore kv;

  setUp(() {
    iap = _MockIap();
    purchases = StreamController<List<PurchaseDetails>>.broadcast();
    kv = InMemoryKeyValueStore();
    when(() => iap.purchaseStream).thenAnswer((_) => purchases.stream);
    when(() => iap.isAvailable()).thenAnswer((_) async => true);
    when(() => iap.completePurchase(any())).thenAnswer((_) async {});
  });

  tearDown(() => purchases.close());

  StoreEntitlementService makeService({StoreProducts products = _products}) =>
      StoreEntitlementService(kv, products, iap: iap);

  /// Wires restorePurchases to push [ids] as a restored batch, the way
  /// the Android plugin answers (empty batch = nothing owned).
  void restoreReturns(List<String> ids) {
    when(() => iap.restorePurchases()).thenAnswer((_) async {
      purchases.add(
          [for (final id in ids) _purchase(id, PurchaseStatus.restored)]);
    });
  }

  /// Wires restorePurchases the way iOS StoreKit 2 answers: one stream
  /// event per owned transaction, and no events at all when nothing is
  /// owned.
  void restoreReturnsPerTransaction(List<String> ids) {
    when(() => iap.restorePurchases()).thenAnswer((_) async {
      for (final id in ids) {
        purchases.add([_purchase(id, PurchaseStatus.restored)]);
      }
    });
  }

  group('purchase stream', () {
    test('a completed unlock purchase entitles and caches', () async {
      final service = makeService();
      expect(await service.isUnlimited(), isFalse);

      purchases.add(
          [_purchase(_products.lifetimeUnlock, PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(await service.isUnlimited(), isTrue);
      expect(await kv.getBool('entitlement.unlimited'), isTrue);
      expect(await service.isPremium(), isFalse);
      service.dispose();
    });

    test('a premium purchase entitles both premium and unlimited',
        () async {
      final service = makeService();

      purchases.add([
        _purchase(_products.premiumSubscription!, PurchaseStatus.purchased)
      ]);
      await pumpEventQueue();

      expect(await service.isPremium(), isTrue);
      expect(await service.isUnlimited(), isTrue,
          reason: 'premium includes the unlock');
      service.dispose();
    });

    test('watchUnlimited emits when the purchase lands', () async {
      final service = makeService();
      final seen = <bool>[];
      final sub = service.watchUnlimited().listen(seen.add);
      await pumpEventQueue();

      purchases.add(
          [_purchase(_products.lifetimeUnlock, PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(seen.first, isFalse);
      expect(seen.last, isTrue);
      await sub.cancel();
      service.dispose();
    });

    test('failed or canceled purchases entitle nothing', () async {
      final service = makeService();

      purchases.add([
        _purchase(_products.lifetimeUnlock, PurchaseStatus.error),
        _purchase(_products.lifetimeUnlock, PurchaseStatus.canceled),
      ]);
      await pumpEventQueue();

      expect(await service.isUnlimited(), isFalse);
      service.dispose();
    });

    test('pending purchases are completed with the store', () async {
      final service = makeService();

      final purchase = _purchase(
          _products.lifetimeUnlock, PurchaseStatus.purchased,
          pendingComplete: true);
      purchases.add([purchase]);
      await pumpEventQueue();

      verify(() => iap.completePurchase(purchase)).called(1);
      service.dispose();
    });
  });

  group('restore path', () {
    test('restorePurchases re-entitles from a restored batch', () async {
      restoreReturns([_products.lifetimeUnlock]);
      final service = makeService();

      await service.restorePurchases();
      await pumpEventQueue();

      expect(await service.isUnlimited(), isTrue);
      expect(await kv.getBool('entitlement.unlimited'), isTrue);
      service.dispose();
    });

    test('restore with the store unavailable throws', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      final service = makeService();

      expect(service.restorePurchases,
          throwsA(isA<StoreUnavailableException>()));
      service.dispose();
    });
  });

  group('refreshEntitlements (cache expiry)', () {
    test('a lapsed subscription clears cached premium and re-gates',
        () async {
      await kv.setBool('entitlement.premium', true);
      restoreReturns([]);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isFalse);
      expect(await service.isUnlimited(), isFalse);
      service.dispose();
    });

    test('a lapse keeps the lifetime unlock', () async {
      await kv.setBool('entitlement.premium', true);
      await kv.setBool('entitlement.unlimited', true);
      restoreReturns([_products.lifetimeUnlock]);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isFalse);
      expect(await service.isUnlimited(), isTrue);
      service.dispose();
    });

    test('an active subscription survives the refresh', () async {
      await kv.setBool('entitlement.premium', true);
      restoreReturns([_products.premiumSubscription!]);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isTrue);
      expect(await service.isUnlimited(), isTrue);
      service.dispose();
    });

    test('store unavailable keeps the cached entitlement', () async {
      await kv.setBool('entitlement.premium', true);
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isTrue);
      service.dispose();
    });

    test('iOS per-transaction restore keeps an active subscription',
        () async {
      // StoreKit 2 spreads a multi-entitlement restore over separate
      // events; the refresh must judge the union, not the first event.
      await kv.setBool('entitlement.premium', true);
      restoreReturnsPerTransaction(
          [_products.lifetimeUnlock, _products.premiumSubscription!]);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isTrue);
      service.dispose();
    });

    test('iOS restore with nothing owned (zero events) clears premium',
        () async {
      await kv.setBool('entitlement.premium', true);
      restoreReturnsPerTransaction([]);
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isFalse);
      service.dispose();
    });

    test('a billing error keeps the cached entitlement', () async {
      await kv.setBool('entitlement.premium', true);
      when(() => iap.restorePurchases())
          .thenAnswer((_) async => throw Exception('billing error'));
      final service = makeService();

      await service.refreshEntitlements();

      expect(await service.isPremium(), isTrue);
      service.dispose();
    });
  });

  group('prices and tips', () {
    void productQueryReturns(List<ProductDetails> details) {
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async =>
          ProductDetailsResponse(productDetails: details, notFoundIDs: []));
    }

    test('unlimitedPrice comes from the store', () async {
      productQueryReturns(
          [_productDetails(_products.lifetimeUnlock, r'$6.99')]);
      final service = makeService();

      expect(await service.unlimitedPrice(), r'$6.99');
      service.dispose();
    });

    test('prices are null when the store is unavailable', () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      final service = makeService();

      expect(await service.unlimitedPrice(), isNull);
      expect(await service.premiumPrice(), isNull);
      expect(await service.tipProducts(), isEmpty);
      service.dispose();
    });

    test('tipProducts keeps catalog order and skips unsold ids', () async {
      // Store answers out of order and is missing the small tip.
      productQueryReturns([_productDetails('app_tip_large', r'$9.99')]);
      final service = makeService();

      final tips = await service.tipProducts();
      expect(tips, hasLength(1));
      expect(tips.single.label, 'The whole pot');
      expect(tips.single.price, r'$9.99');
      service.dispose();
    });
  });

  group('an app without a premium product', () {
    const unlockOnly = StoreProducts(lifetimeUnlock: 'app_unlimited');

    test('isPremium is always false and refresh is a no-op', () async {
      final service = makeService(products: unlockOnly);

      expect(await service.isPremium(), isFalse);
      await service.refreshEntitlements();
      verifyNever(() => iap.restorePurchases());
      service.dispose();
    });

    test('buyPremium is a configuration error', () async {
      final service = makeService(products: unlockOnly);

      expect(service.buyPremium, throwsStateError);
      service.dispose();
    });
  });

  group('store errors surface', () {
    test('a failed purchase reports on storeErrors', () async {
      final service = makeService();
      final errors = <String>[];
      final sub = service.storeErrors.listen(errors.add);

      purchases
          .add([_purchase(_products.lifetimeUnlock, PurchaseStatus.error)]);
      await pumpEventQueue();

      expect(errors, hasLength(1));
      expect(errors.single, contains(_products.lifetimeUnlock));
      await sub.cancel();
      service.dispose();
    });

    test('a swallowed refresh failure reports on storeErrors', () async {
      when(() => iap.restorePurchases())
          .thenAnswer((_) async => throw Exception('billing error'));
      final service = makeService();
      final errors = <String>[];
      final sub = service.storeErrors.listen(errors.add);

      await service.refreshEntitlements();
      await pumpEventQueue();

      expect(errors, hasLength(1));
      expect(errors.single, contains('billing error'));
      await sub.cancel();
      service.dispose();
    });

    test('successful purchases report nothing', () async {
      final service = makeService();
      final errors = <String>[];
      final sub = service.storeErrors.listen(errors.add);

      purchases.add(
          [_purchase(_products.lifetimeUnlock, PurchaseStatus.purchased)]);
      await pumpEventQueue();

      expect(errors, isEmpty);
      await sub.cancel();
      service.dispose();
    });
  });

  group('buy flows', () {
    test('buyUnlimited launches a non-consumable purchase', () async {
      when(() => iap.queryProductDetails(any())).thenAnswer((_) async =>
          ProductDetailsResponse(
              productDetails: [
                _productDetails(_products.lifetimeUnlock, r'$6.99')
              ],
              notFoundIDs: []));
      when(() => iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .thenAnswer((_) async => true);
      final service = makeService();

      await service.buyUnlimited();

      verify(() =>
              iap.buyNonConsumable(purchaseParam: any(named: 'purchaseParam')))
          .called(1);
      service.dispose();
    });

    test('buyUnlimited without the store throws StoreUnavailable',
        () async {
      when(() => iap.isAvailable()).thenAnswer((_) async => false);
      final service = makeService();

      expect(service.buyUnlimited, throwsA(isA<StoreUnavailableException>()));
      service.dispose();
    });
  });
}
