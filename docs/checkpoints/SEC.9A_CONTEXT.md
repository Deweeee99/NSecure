# SEC.9A Context — Localization Foundation (Bahasa Indonesia + English)

## Current Status

`DONE`

## Previous Locked State

```text
SEC.1–SEC.9 DONE
Visitor Verification operational + API-integrated
Patrol Management operational + API-integrated
SEC.9 final gate: analyze clean, 61 tests passed, debug APK built
```

SEC.9A is built from the latest cumulative green SEC.9 state.

## Final Validation

User confirmed the SEC.9A post-hotfix gate green before SEC.10 started:

```text
flutter analyze           ✅ green
flutter test              ✅ green
flutter build apk --debug ✅ green
```

The exact final test count was not re-pasted; do not invent it. SEC.9A is nevertheless locked `DONE` by explicit user confirmation.

## Objective

Establish one reusable Flutter localization boundary for Bahasa Indonesia and English before Incident Reporting becomes operational. Retrofit current Visitor + Patrol surfaces without changing canonical backend contracts.

## Scope

### In Scope

- generated Flutter localizations using ARB resources;
- `en` and `id` locale resources;
- language selector on Login and More;
- locally persisted language preference;
- authentication, bottom navigation, Home, Visitor, Patrol, and concept-screen presentation copy;
- localized presentation labels for canonical statuses/errors;
- locale-aware UI date/time formatting where applicable;
- regression-test updates required by localized presentation.

### Deliberate Deferrals

- Incident API integration remains SEC.10;
- backend localization / translated API messages;
- translating stable machine error codes;
- translating canonical wire statuses;
- hardware-dependent Security integrations.

## Localization Boundary

```text
API wire values / machine codes          EXACT / untranslated
Repository + domain model values         EXACT / untranslated
Presentation labels and human UI copy    localized ID / EN
```

Examples:

```text
Wire: Checked In     → UI EN: Checked-In       → UI ID: Sudah Check-In
Wire: In Progress    → UI EN: IN PROGRESS      → UI ID: SEDANG BERJALAN
Code: UNAUTHENTICATED                       stays UNAUTHENTICATED internally
```

Opaque QR/access payloads, IDs, property authorization selectors, actors, and backend-owned timestamps are never transformed by localization.

## Implemented Architecture

```text
lib/l10n/app_en.arb
lib/l10n/app_id.arb
        ↓ flutter gen-l10n
lib/l10n/app_localizations.dart (generated locally)
        ↓
SecurityLocaleController
        ↓
SecurityLocaleScope + MaterialApp locale
        ↓
Presentation widgets via context.l10n
```

Locale persistence key:

```text
security.locale.language_code
```

Supported values:

```text
en
id
```

Preference-storage failure is non-fatal and must not block login or operational flows.

## Preparation

The patch intentionally does not overwrite the user's real `pubspec.yaml`. Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\sec9a_prepare_localization.ps1
```

The script adds Flutter localization dependencies, enables generated localization in the actual pubspec, resolves packages, runs `flutter gen-l10n`, and verifies `lib/l10n/app_localizations.dart`.

## Files Added / Modified

Core additions:

```text
l10n.yaml
lib/l10n/app_en.arb
lib/l10n/app_id.arb
lib/core/localization/app_localizations_x.dart
lib/core/localization/security_locale_controller.dart
lib/core/localization/security_language_button.dart
tool/sec9a_prepare_localization.ps1
```

Presentation updates cover `lib/app.dart`, Security auth/shell/home/catalog/concepts, Visitor operational screens/flows/formatters, and Patrol Management. Tests/docs are updated to reflect the bilingual presentation boundary.

## Known Limitations

- Backend-provided free-form `message` content may still arrive in the backend's configured language; stable known frontend failure families use localized presentation messages.
- Proper names and persisted user/business data are intentionally not translated.
- SEC.10 Incident operational screens are not implemented by this checkpoint.

## Backend Dependency

None for localization mechanics. Existing Visitor + Patrol APIs remain unchanged.

## Validation Gate

Run after preparation:

```powershell
cd E:\aparthub_security
powershell -ExecutionPolicy Bypass -File .\tool\sec9a_prepare_localization.ps1
flutter analyze
flutter test
flutter build apk --debug
```

Status:

```text
flutter analyze           ⏳
flutter test              ⏳
flutter build apk --debug ⏳
```

Do not lock SEC.9A `DONE` until all three are green.

## Validation Attempt 1 — 12 Aug 2026

User-confirmed local result after SEC.9A v2:

```text
flutter analyze           RED — 6 use_build_context_synchronously infos
flutter test              RED — 1 widget expectation (02:35 PM)
flutter build apk --debug still running when log was shared; build result is not used to close the gate
```

Additional tooling warning:

```text
l10n.yaml: synthetic-package no longer has any effect and should be removed
```

Root causes and hotfix:

- error handlers awaited `_handleSessionExpired(...)` and then reused `context` without a second `mounted` guard; hotfix adds `if (!mounted) return;` after that async gap;
- Visitor time presentation became locale-aware via `MaterialLocalizations`, so the regression test must derive its expected value from the active locale instead of hard-coding `02:35 PM`;
- obsolete `synthetic-package: false` was removed from `l10n.yaml` for current Flutter tooling.

Dependency freshness notices and the existing `mobile_scanner` KGP future-compatibility warning remain non-blocking unless they become actual build failures.

## Next Checkpoint

`SEC.10 — Incident Reporting API Integration`

Incident must use the localization foundation from its first operational implementation.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile (Flutter frontend only).
Current checkpoint: SEC.9A — Localization Foundation — Bahasa Indonesia + English.
Status: HOTFIX V1 APPLIED — REVALIDATION REQUIRED.
Last completed: SEC.9 DONE; SEC.1–SEC.9 are locked green.

Read first:
1. docs/checkpoints/SEC.9A_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/ARCHITECTURE.md
5. docs/FRONTEND_SPEC.md
6. docs/DESIGN_SYSTEM.md
7. docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
8. docs/API_CONTRACT_SECURITY_PATROL_V1.md

Locked rules:
- Build from latest cumulative green SEC.9 source.
- UI supports Bahasa Indonesia and English.
- Backend/API wire values and stable error codes remain exact and untranslated.
- Localization is presentation-only; do not mutate repository/domain contracts.
- Preserve SEC.4 Visitor footer behavior, SEC.8 Android/session/scanner fixes, and SEC.9 Patrol operational flow.
- Visitor + Patrol are ACTIVE; Incident becomes operational in SEC.10.
- Hardware-dependent modules remain HOLD/concept.

SEC.9A implementation:
- ARB files: lib/l10n/app_en.arb + app_id.arb.
- generated AppLocalizations via flutter gen-l10n.
- SecurityLocaleController persists security.locale.language_code.
- language selector on Login and More.
- presentation strings localized across auth/shell/home/Visitor/Patrol/concept screens.

Next action:
Re-run flutter analyze, flutter test, and flutter build apk --debug after SEC.9A validation hotfix v1. If all green, lock SEC.9A DONE and proceed SEC.10 Incident Reporting API Integration.
```
