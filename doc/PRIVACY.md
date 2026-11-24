# Privacy line and store disclosures (all CC apps)

## The first-run line
`kPrivacyBoilerplate`: "We run no servers and hold none of your data — it lives
on this phone. No account needed. No ads."

Lead with "no servers": it's the real promise, and the ML Kit note is a
footnote to it. It has to be true for every app that uses the default, so it
doesn't promise "no analytics" or "no cloud" (backup goes to the user's own
Drive/iCloud, which we can't see).

**Apps with a server or accounts can't use it.** Kick Rocks (Crew: sign-in,
shared trips, media, comments, push tokens) writes its own line and policy
naming what the server holds, and answers Data safety for that data too.

Apps that **use** an ML Kit feature (cc_core scan/OCR, on-device AI) append
`kPrivacyMlKitNote` ("Google's on-device ML sends Google usage stats — never
your content."). Any Settings → Privacy copy has to match: no "no analytics".

## Why: Google ML Kit
cc_core depends on `google_mlkit_text_recognition`, so ML Kit ships in every
CC Android app. When an ML Kit API runs, it sends Google:
- device info: manufacturer, model, OS version and build, ML accelerators
- app info: package name, app version
- performance metrics, such as latency

It never sends the input: images and text are processed on the device. Google
uses the metrics for diagnostics, usage analytics and misuse detection, and
ML Kit doesn't share them with third parties. Under ML Kit's terms, *we* must
tell users.

Sources: https://developers.google.com/ml-kit/android-data-disclosure and
https://developers.google.com/ml-kit/terms. Re-check on every ML Kit upgrade.

## Play Data safety (apps that call an ML Kit API)
| Field | Answer |
|---|---|
| Data type | App info and performance → Diagnostics (and Other app performance data) |
| Collected | Yes |
| Shared | No |
| Processed ephemerally | No |
| Required or optional | Required (no in-app opt-out) |
| Purpose | Analytics |
| Encrypted in transit | Yes |

Apps that never call an ML Kit API: verify on a device before answering
"no data collected". Check `databases/com.google.android.datatransport.events`
via `run-as`, then watch for `firebaselogging.googleapis.com` traffic.

## App Store
Not applicable on iOS unless the app ships ML Kit's iOS pods. Kick Rocks uses
Apple Foundation Models instead.
