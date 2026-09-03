/// The store products one app sells, injected into
/// [StoreEntitlementService]. Ids must match the products configured in
/// Play Console / App Store Connect exactly.
///
/// The core model Code Cowboys apps share — each piece optional, at
/// least one present:
/// - optionally one lifetime unlock (non-consumable) that removes the
///   free-tier cap,
/// - optionally one premium subscription that includes the unlock plus
///   subscriber-only features, with one or more plans (monthly/yearly):
///   Google Play base plans under one product id, or — on the App
///   Store, which has no base plans — one product per plan inside a
///   subscription group,
/// - optionally a few consumable tip products.
class StoreProducts {
  /// Creates the product catalog for one app.
  const StoreProducts({
    this.lifetimeUnlock,
    this.premiumSubscription,
    this.premiumPlanLabels = const {},
    this.premiumPlanProducts = const {},
    this.tipLabels = const {},
  });

  /// True when the catalog sells an unlock or a subscription (or both);
  /// [StoreEntitlementService] asserts this — checked there because a
  /// map's emptiness is not a constant expression for a const
  /// constructor's assert.
  bool get sellsAnyEntitlement => lifetimeUnlock != null || sellsPremium;

  /// Product id of the one-time unlock (non-consumable); null when the
  /// app sells no lifetime unlock (subscription-only apps).
  final String? lifetimeUnlock;

  /// Product id of the premium subscription; null when the app sells
  /// no subscription, or sells it only as per-plan products
  /// ([premiumPlanProducts]).
  final String? premiumSubscription;

  /// Base plan id → display label ("monthly" → "Monthly"), in display
  /// order, for subscriptions sold with more than one base plan. Empty
  /// for single-plan apps: `premiumPlans()` then derives plans from
  /// what the store returns.
  final Map<String, String> premiumPlanLabels;

  /// Plan id → store product id, for stores that sell each plan of the
  /// subscription as its own product: the App Store puts "monthly" and
  /// "yearly" in one subscription group as two products. Owning any of
  /// them is the premium entitlement, and `buyPremium(planId:)` buys
  /// the mapped product. Keys match [premiumPlanLabels]. Empty on
  /// Google Play, where the plans are base plans of
  /// [premiumSubscription].
  final Map<String, String> premiumPlanProducts;

  /// True when the app sells a subscription in either form.
  bool get sellsPremium =>
      premiumSubscription != null || premiumPlanProducts.isNotEmpty;

  /// Every product id whose ownership means "premium".
  Set<String> get premiumProductIds => {
    ?premiumSubscription,
    ...premiumPlanProducts.values,
  };

  /// Tip product id → display label, in display order. Empty when the
  /// app sells no tips.
  final Map<String, String> tipLabels;

  /// Ids of the tip products, in display order.
  List<String> get tipIds => tipLabels.keys.toList();

  /// Every product id this app sells.
  List<String> get all => [
    ?lifetimeUnlock,
    ...premiumProductIds,
    ...tipLabels.keys,
  ];
}

/// One purchasable base plan of the premium subscription, with its live
/// store price, ready for a plan-picker UI.
class SubscriptionPlan {
  /// Creates a plan row.
  const SubscriptionPlan({
    required this.id,
    required this.label,
    required this.price,
  });

  /// Plan id: the Play base plan id ("monthly"), or the
  /// [StoreProducts.premiumPlanProducts] key that maps to the plan's
  /// own product on stores without base plans. For a single-plan app
  /// with no configured labels, the store product id.
  final String id;

  /// Display label ("Monthly"), from [StoreProducts.premiumPlanLabels]
  /// when configured, otherwise [id].
  final String label;

  /// Localized store price ("$1.99").
  final String price;
}

/// A purchasable tip with its store price, ready for a tip-jar UI.
class TipProduct {
  /// Creates a tip row.
  const TipProduct({
    required this.id,
    required this.label,
    required this.price,
  });

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
