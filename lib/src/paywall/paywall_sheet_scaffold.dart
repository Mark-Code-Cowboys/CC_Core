import 'package:flutter/material.dart';

import 'store_products.dart';

/// Opens a modal bottom sheet sized to its content — the standard way
/// Code Cowboys apps present a paywall built on [PaywallSheetScaffold].
Future<T?> showPaywallModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    builder: builder,
  );
}

/// Runs a store action (buy, restore) and turns
/// [StoreUnavailableException] into a snackbar instead of a crash.
Future<void> runStoreAction(
  BuildContext context,
  Future<void> Function() action, {
  String unavailableMessage = 'Store not available on this device right now.',
}) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    await action();
  } on StoreUnavailableException {
    messenger.showSnackBar(SnackBar(content: Text(unavailableMessage)));
  } on Exception catch (e) {
    // Restore/purchase failures otherwise vanish into an unhandled
    // async error — show the real reason so store problems are
    // diagnosable from the device.
    messenger.showSnackBar(SnackBar(content: Text('Store error: $e')));
  }
}

/// One benefit row on a paywall sheet: leading icon, bold title, detail.
class PaywallBenefit extends StatelessWidget {
  /// Creates a benefit row.
  const PaywallBenefit({
    required this.icon,
    required this.title,
    required this.detail,
    super.key,
  });

  /// Leading icon, tinted with the primary color.
  final IconData icon;

  /// One-line benefit ("Scan menus and receipts").
  final String title;

  /// Supporting sentence under the title.
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(detail, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The shared skeleton of every Code Cowboys paywall sheet: hero icon,
/// title, an optional primary-colored highlight line, body copy,
/// benefit rows, the primary buy button, an optional footnote, restore,
/// arbitrary extra actions, and "Maybe later".
///
/// Apps own all copy and the purchase callbacks; the scaffold owns only
/// layout, so every app's sheets look related without sharing wording.
class PaywallSheetScaffold extends StatelessWidget {
  /// Creates the sheet body. Present it with [showPaywallModal].
  const PaywallSheetScaffold({
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    this.highlight,
    this.body,
    this.benefits = const [],
    this.footnote,
    this.restoreLabel,
    this.onRestore,
    this.extraActions = const [],
    this.laterLabel = 'Maybe later',
    this.onLater,
    super.key,
  });

  /// Hero icon at the top, large and primary-tinted.
  final IconData icon;

  /// Sheet headline (the product name).
  final String title;

  /// Optional primary-colored line under the title — the reason the
  /// sheet opened ("2 of 5 free restaurants used").
  final String? highlight;

  /// Optional body paragraph under the highlight.
  final String? body;

  /// Benefit rows ([PaywallBenefit]) between body and buy button.
  final List<Widget> benefits;

  /// Label on the primary (buy) button.
  final String primaryLabel;

  /// Starts the purchase; wrap store calls in [runStoreAction].
  final VoidCallback onPrimary;

  /// Small print directly under the buy button.
  final String? footnote;

  /// Label for the restore button; null hides it.
  final String? restoreLabel;

  /// Restore handler; wrap store calls in [runStoreAction].
  final VoidCallback? onRestore;

  /// Extra widgets between restore and "Maybe later" (cross-sell rows,
  /// dividers, secondary buttons).
  final List<Widget> extraActions;

  /// Label on the dismiss button.
  final String laterLabel;

  /// Dismiss handler; null pops the enclosing route.
  final VoidCallback? onLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Scrollable so long copy or many benefits never overflow the sheet
    // on small screens; sized to content when everything fits.
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            if (highlight != null) ...[
              const SizedBox(height: 4),
              Text(
                highlight!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (body != null) ...[
              const SizedBox(height: 8),
              Text(
                body!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (benefits.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...benefits,
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: onPrimary, child: Text(primaryLabel)),
            if (footnote != null) ...[
              const SizedBox(height: 4),
              Text(
                footnote!,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (restoreLabel != null)
              TextButton(onPressed: onRestore, child: Text(restoreLabel!)),
            ...extraActions,
            TextButton(
              onPressed: onLater ?? () => Navigator.of(context).pop(),
              child: Text(laterLabel),
            ),
          ],
        ),
      ),
    );
  }
}
