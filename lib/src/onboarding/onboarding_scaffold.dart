import 'package:flutter/material.dart';

/// The line every CC app without a backend promises on first run. It
/// leads with the strongest true thing: Code Cowboys runs no servers for
/// the app, so it holds none of the user's data (optional backup goes to
/// the user's *own* Drive/iCloud). No account is required, no ads.
///
/// Apps that run a server or have accounts (Kick Rocks Crew) must **not**
/// use this line; they write their own that names what the server holds.
///
/// It deliberately does **not** say "no analytics" or "no cloud": cc_core
/// depends on Google ML Kit (`google_mlkit_text_recognition`, for scan),
/// and ML Kit sends Google usage metrics (device model, OS, app version,
/// latency — never content); some apps offer cloud backup. Apps that use
/// an ML Kit feature should append [kPrivacyMlKitNote] and declare it in
/// Play's Data safety form (see doc/PRIVACY.md).
const kPrivacyBoilerplate = 'We run no servers and hold none of your data — it lives on this phone. No account needed. No ads.';

/// For apps that use an ML Kit feature (scan/OCR, on-device AI):
/// `privacyLine: '$kPrivacyBoilerplate $kPrivacyMlKitNote'`.
const kPrivacyMlKitNote = 'Google’s on-device ML sends Google usage stats — never your content.';

/// The shared first-run layout: hero icon, the app's positioning line
/// front and center, supporting copy, the privacy promise, and the
/// app's fork of starting actions. Apps own every word; the scaffold
/// owns layout so all CC first runs look related.
class OnboardingScaffold extends StatelessWidget {
  /// Creates the first-run page.
  const OnboardingScaffold({
    super.key,
    required this.icon,
    required this.positioning,
    this.subtitle,
    this.privacyLine = kPrivacyBoilerplate,
    required this.actions,
  });

  /// Hero icon, large and primary-tinted.
  final IconData icon;

  /// The app's positioning line — the reason it exists, in one
  /// sentence, biggest text on the page.
  final String positioning;

  /// Supporting copy under the positioning line.
  final String? subtitle;

  /// The privacy promise; defaults to [kPrivacyBoilerplate].
  final String privacyLine;

  /// Starting actions, most encouraged first (stretched full-width).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(icon, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 24),
                  Text(
                    positioning,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          privacyLine,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(height: 8),
                    action,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
