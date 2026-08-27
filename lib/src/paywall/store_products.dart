/// The store products one app sells, injected into
/// [StoreEntitlementService]. Ids must match the products configured in
/// Play Console / App Store Connect exactly.
///
/// The core model every Code Cowboys app shares:
/// - one lifetime unlock (non-consumable) that removes the free-tier cap,
/// - optionally one premium subscription that includes the unlock plus
///   subscriber-only features,
/// - optionally a few consumable tip products.
class StoreProducts {
  /// Creates the product catalog for one app.
  const StoreProducts({
    required this.lifetimeUnlock,
    this.premiumSubscription,
    this.tipLabels = const {},
  });

  /// Product id of the one-time unlock (non-consumable).
  final String lifetimeUnlock;

  /// Product id of the annual premium subscription; null when the app
  /// sells no subscription.
  final String? premiumSubscription;

  /// Tip product id → display label, in display order. Empty when the
  /// app sells no tips.
  final Map<String, String> tipLabels;

  /// Ids of the tip products, in display order.
  List<String> get tipIds => tipLabels.keys.toList();

  /// Every product id this app sells.
  List<String> get all => [
        lifetimeUnlock,
        ?premiumSubscription,
        ...tipLabels.keys,
      ];
}

/// A purchasable tip with its store price, ready for a tip-jar UI.
class TipProduct {
  /// Creates a tip row.
  const TipProduct(
      {required this.id, required this.label, required this.price});

  /// Store product id.
  final String id;

  /// Display label ("Espresso").
  final String label;

  /// Localized store price ("$1.99").
  final String price;
}

/// Thrown by purchase/restore calls when the store can't be reached
/// (emulator without Play, desktop dev, airplane mode at the worst time).
class StoreUnavailableException implements Exception {
  /// Const so call sites can `throw const StoreUnavailableException()`.
  const StoreUnavailableException();
}
