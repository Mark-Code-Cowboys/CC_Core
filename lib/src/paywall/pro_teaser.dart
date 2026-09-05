import 'package:flutter/material.dart';

/// The free-tier face of a Pro-gated screen: hero icon, the pitch, one
/// "see Pro" button — and, below the divider, an action that is never
/// gated (in the fleet, restoring your own backup). Extracted when
/// Course Ledger's and Hitch Post's trends teasers came out
/// near-verbatim identical. Riverpod-free: the app supplies the copy
/// and the two callbacks.
class ProTeaser extends StatelessWidget {
  /// Creates the teaser.
  const ProTeaser({
    super.key,
    required this.icon,
    required this.headline,
    required this.body,
    required this.ctaLabel,
    required this.onSeePro,
    this.ungatedIcon = Icons.settings_backup_restore,
    this.ungatedLabel,
    this.onUngated,
  });

  /// Hero icon, large and primary-tinted.
  final IconData icon;

  /// The screen's pitch line ("The long arc of the road.").
  final String headline;

  /// What Pro buys, in one short paragraph.
  final String body;

  /// The button label ("See Hitch Post Pro").
  final String ctaLabel;

  /// Opens the paywall.
  final VoidCallback onSeePro;

  /// Icon for the never-gated action.
  final IconData ungatedIcon;

  /// The never-gated action's label; null hides the whole row.
  final String? ungatedLabel;

  /// The never-gated action.
  final VoidCallback? onUngated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(headline,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onSeePro, child: Text(ctaLabel)),
            if (ungatedLabel != null) ...[
              const SizedBox(height: 24),
              const Divider(),
              TextButton.icon(
                icon: Icon(ungatedIcon),
                label: Text(ungatedLabel!),
                onPressed: onUngated,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
