import 'dart:async';

import 'entitlement_service.dart';
import 'store_products.dart';

/// In-memory [EntitlementService] for tests and previews:
/// `buyUnlimited`/`buyPremium` succeed instantly so paywall flows are
/// testable end to end without the store plugin.
class FakeEntitlementService implements EntitlementService {
  /// Creates the fake, optionally already entitled.
  FakeEntitlementService({
    bool unlimited = false,
    bool premium = false,
    this.fakeUnlimitedPrice = r'$6.99',
    this.fakePremiumPrice = r'$12.99',
    this.fakeTipProducts = const [],
    // ignore: prefer_initializing_formals
  })  : _unlimited = unlimited,
        // ignore: prefer_initializing_formals
        _premium = premium;

  bool _unlimited;
  bool _premium;

  /// Price returned by [unlimitedPrice].
  final String? fakeUnlimitedPrice;

  /// Price returned by [premiumPrice].
  final String? fakePremiumPrice;

  /// Rows returned by [tipProducts].
  final List<TipProduct> fakeTipProducts;

  final _changes = StreamController<bool>.broadcast();
  final _premiumChanges = StreamController<bool>.broadcast();

  @override
  Future<bool> isUnlimited() async => _unlimited || _premium;

  @override
  Stream<bool> watchUnlimited() async* {
    yield await isUnlimited();
    yield* _changes.stream;
  }

  @override
  Future<bool> isPremium() async => _premium;

  @override
  Stream<bool> watchPremium() async* {
    yield _premium;
    yield* _premiumChanges.stream;
  }

  @override
  Future<String?> unlimitedPrice() async => fakeUnlimitedPrice;

  @override
  Future<String?> premiumPrice() async => fakePremiumPrice;

  @override
  Future<List<TipProduct>> tipProducts() async => fakeTipProducts;

  @override
  Future<void> buyUnlimited() async {
    _unlimited = true;
    _changes.add(true);
  }

  @override
  Future<void> buyPremium() async {
    _premium = true;
    _premiumChanges.add(true);
    _changes.add(true); // Premium includes the unlock.
  }

  @override
  Future<void> buyTip(String productId) async {}

  @override
  Future<void> restorePurchases() async {}

  @override
  Future<void> refreshEntitlements() async {}

  @override
  Stream<String> get storeErrors => const Stream.empty();

  @override
  void dispose() {
    unawaited(_changes.close());
    unawaited(_premiumChanges.close());
  }
}
