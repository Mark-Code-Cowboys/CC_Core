# CC-Factory Build Prompt (paste into Claude Code)

You are building `cc_core`, the shared Flutter library that powers all Code Cowboys apps. Work ONE PHASE AT A TIME. At the end of each phase, run `flutter analyze` and `flutter test`, summarize what changed, and STOP for my confirmation before starting the next phase. Never skip ahead.

## Context

- Owner: Code Cowboys LLC (solo dev). Goal: stamp out 10–15 privacy-first, local-only journal/log apps from one shared core.
- Existing consumers to extract FROM: Table Encore (restaurant journal, newest/cleanest — primary donor) and Trace Elements (element tracker — second consumer).
- Environment: CachyOS Linux, fish shell (NO bash heredocs — use fish-native or `echo | tee` patterns), Flutter 3.41.2 at /usr/lib/flutter, Android SDK 36.1.0. Git pushes happen via GitKraken; you stage and commit locally, never push.
- GitHub org: Mark-Code-Cowboys. Repo name: `cc_core`, private.
- Design rules: no accounts, no cloud sync, no third-party analytics. All data local (Drift/sqlite). Store-routed payments only.

## Architecture (fixed — do not redesign)

Single Flutter package `cc_core`, consumed by apps as a git dependency pinned to a tag:

```yaml
dependencies:
  cc_core:
    git:
      url: git@github.com:Mark-Code-Cowboys/cc_core.git
      ref: v0.x.0
```

During extraction, apps use `pubspec_overrides.yaml` (git-ignored) with a `path:` override to the local checkout for fast iteration; the tag ref is what ships.

Library layout (folders under `lib/src/`, exported through `lib/cc_core.dart` with one barrel file per module):

- `paywall/` — billing wrapper, entitlement cache, `FreeLimit` quota helper, `EntitlementGate` widget, paywall sheet scaffold
- `io/` — export (CSV/JSON), backup/restore (single-file archive), PDF export
- `journal/` — entry/tag/rating/photo-attachment models, Drift repository, search
- `trends/` — calendar heatmap, time-window queries, basic chart widgets
- `onboarding/` — first-run flow, consent/privacy screen, "your data never leaves your phone" boilerplate
- `theme/` — base theme consuming a per-app token class (colors, type scale, corner radii)
- `scan/` — AI photo-extraction client (menu/receipt/notebook-page → structured fields → user-confirm screen). Per-app extraction schema injected; core owns the pipeline, camera/crop UX, and confirm-before-save screen
- `notebook_import/` — batch flavor of scan/: multi-page capture → queued extraction → review list → bulk insert

## Phase 0 — Repo bootstrap
1. `flutter create --template=package cc_core`
2. Add: analysis_options with strict lints, LICENSE (proprietary), README stub describing the module map above, .gitignore including `pubspec_overrides.yaml`.
3. Set up folder skeleton + empty barrel files for every module.
4. Dev dependencies: drift, drift_dev, build_runner, test, mocktail (verify current versions on pub.dev — do not trust memory).
5. Init git, commit, tag `v0.0.1`. STOP.

## Phase 1 — Paywall module (extract from Table Encore)
1. I will give you the path to the Table Encore checkout. Read its billing implementation (recently merged billing PR) before writing anything.
2. Extract into `paywall/`: billing client wrapper, entitlement state (cached + re-queried on resume), purchase/restore flows, error handling incl. offline tap.
3. Generalize the restaurant cap into `FreeLimit(count, subjectLabel)` + `EntitlementGate` widget that shows child when entitled, paywall sheet when not.
4. Unit tests: quota edge (at limit, over limit, entitled), entitlement cache expiry, restore path. Mock the store client.
5. Wire Table Encore to consume `cc_core` via pubspec_overrides path dep; delete its now-duplicate billing code; its existing paywall tests must still pass.
6. Commit. Tag `v0.1.0` only after I confirm Table Encore runs on-device. STOP.

## Phase 2 — Second consumer proves the API
1. Point Trace Elements at `cc_core` (same overrides pattern).
2. Replace its billing/entitlement code with the shared module. Its gates: element-count limit, scan quota, export, trend window.
3. Any API friction found here gets fixed in cc_core, not worked around in the app.
4. Commit both sides. STOP.

## Phase 3 — io module
1. Extract export/backup/restore from whichever app's implementation is cleaner (inspect both, tell me which and why).
2. Design the backup archive as versioned JSON + media folder in a single zip; include schema-version migration hook.
3. PDF export as a composable report builder (apps supply sections).
4. Tests: round-trip backup→restore equality, forward-migration stub.
5. Wire both apps. Commit, tag `v0.2.0`. STOP.

## Phase 4 — journal + trends
1. Extract entry/tag/rating/photo models and Drift repo from Table Encore; apps keep their domain tables and join to core journal tables.
2. Extract calendar/trends widgets from Trace Elements.
3. Migration plan for both apps' existing on-device databases — write and test the Drift migrations; data loss is unacceptable.
4. Wire both apps. Commit, tag `v0.3.0`. STOP.

## Phase 5 — scan + notebook_import
1. Extract Table Encore's menu/receipt scan pipeline; core owns capture→extract→confirm; extraction schema is injected per app.
2. Build `notebook_import` batch flow on top.
3. Guardrail baked into core: extraction is read-only transcription — the confirm screen never suggests, corrects, or flags values.
4. Wire Table Encore back onto it. Commit, tag `v0.4.0`. STOP.

## Phase 6 — onboarding + theme, then template
1. Extract first-run/consent and theming; define `CcThemeTokens`.
2. Create separate repo `cc_template` (GitHub template): runnable app skeleton consuming cc_core `v0.4.0+` with a placeholder journal type behind a `FreeLimit(5)` gate, plus `tool/scaffold.dart` that takes app name, package id, accent color and rewrites the skeleton.
3. Acceptance test: scaffold a throwaway app and reach a running debug build on the Pixel in one sitting. STOP.

## Standing rules
- Ask before adding any dependency not listed.
- No cloud services, no analytics SDKs, ever.
- Every public API gets a doc comment; every module gets a README section.
- If extraction reveals Table Encore code too entangled to lift cleanly, stop and show me the coupling instead of rewriting app logic silently.
