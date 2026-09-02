import 'package:flutter/material.dart';

/// Shows [child] when entitled; otherwise intercepts interaction and
/// opens the app's paywall instead.
///
/// [entitled] is typically `EntitlementService.watchUnlimited()` (or
/// `watchPremium()` for subscriber-only features). While the first
/// value is loading the gate stays closed, so gating is conservative
/// and paying users never see a locked flash resolve the other way.
///
/// The default locked presentation renders [child] untouchable behind a
/// transparent tap target; pass [lockedBuilder] for a bespoke locked
/// look (grayed out, lock badge, upsell row).
class EntitlementGate extends StatelessWidget {
  /// Creates the gate.
  const EntitlementGate({
    required this.entitled,
    required this.child,
    required this.showPaywall,
    this.lockedBuilder,
    super.key,
  });

  /// Emits the entitlement state; current value first.
  final Stream<bool> entitled;

  /// What entitled users see and use.
  final Widget child;

  /// Opens the app's paywall/upsell sheet. Called when a non-entitled
  /// user tries to interact.
  final Future<void> Function(BuildContext context) showPaywall;

  /// Optional locked presentation; [openPaywall] is pre-wired to
  /// [showPaywall] for the tap handler.
  final Widget Function(BuildContext context, VoidCallback openPaywall)?
  lockedBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: entitled,
      builder: (context, snapshot) {
        if (snapshot.data ?? false) return child;
        void openPaywall() => showPaywall(context);
        final locked = lockedBuilder;
        if (locked != null) return locked(context, openPaywall);
        return GestureDetector(
          onTap: openPaywall,
          behavior: HitTestBehavior.opaque,
          child: AbsorbPointer(child: child),
        );
      },
    );
  }
}
