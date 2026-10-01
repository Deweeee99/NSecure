# SEC.11A Context — APH.35C / APH.37 Localization Runtime Alignment

Status: **DONE**

Date opened: 14 Aug 2026

## Objective

Align the already-green Bahasa Indonesia + English UI foundation with the backend runtime localization contract from APH.35C, while carrying forward the APH.37 catalog extension for the upcoming Emergency SOS checkpoint.

The transport rule is now explicit:

```text
selected/effective mobile locale
        ↓
Accept-Language: id | en
        ↓
Security API
        ↓
Content-Language: id | en
```

Localization remains display-only. Canonical API/database values and stable error codes remain exact.

## Locked Input Baseline

SEC.1 through SEC.11 are green/DONE. Preserve:

- Visitor Verification API integration;
- Patrol Management API integration;
- Incident Reporting API integration;
- Patrol checkpoint → Incident cross-module flow;
- secure Sanctum session and Android SEC.8 readiness baseline;
- QR camera + Manual Verification fallback;
- existing ID/EN ARB architecture and persisted language choice;
- exact canonical Visitor/Patrol/Incident wire values;
- stable Security error-code branching;
- latest cumulative green source rule.

## Backend Localization Contract

Supported request locales:

```text
id
en
```

Regional inputs are normalized to the primary supported language. Unsupported locale input falls back to `en` before transport.

Every Security API request made by `IoSecurityApiClient` sends:

```http
Accept-Language: <id|en>
```

The client reads the response:

```http
Content-Language: <id|en>
```

and exposes the normalized most-recent response language as diagnostic/runtime metadata.

Backend-owned `message`, validation text, validation field errors and QR validation reason may be localized. Flutter business logic must never branch on those strings.

## Canonical Wire Guardrail

Never translate/mutate in transport or domain logic:

```text
IDs / tokens
route and field names
permission/module slugs
canonical statuses
canonical severities/priorities
stable Security error codes
```

Examples that remain exact:

```text
Checked In
In Progress
Issue
Resolved
Critical
VISITOR_ALREADY_CHECKED_IN
PATROL_NOT_FOUND
INCIDENT_INVALID_STATE
UNAUTHENTICATED
VALIDATION_ERROR
```

## Implementation

### Locale → API synchronization

`SecurityLocaleController` now provides an effective language code:

- explicit persisted/selected `id` or `en` wins;
- otherwise the supported platform language is used;
- unsupported platform language falls back to `en`.

`AparthubSecurityApp` synchronizes that effective locale into the shared API client at startup and whenever the user changes language.

### Security API transport

`IoSecurityApiClient` implements a localization seam that:

- defaults request language to `en`;
- normalizes `id-ID` → `id`, `en-US` → `en`;
- normalizes unsupported locale → `en`;
- sends `Accept-Language` for authenticated and unauthenticated Security requests, including login;
- reads/normalizes `Content-Language` on both success and error responses;
- leaves envelope `code`, status fields and domain payload untouched.

### Catalog alignment

Existing Security UI status labels were audited against the APH.35C/APH.37 machine-readable catalog.

Adjusted presentation labels include:

```text
Visitor Pending       id: Menunggu Persetujuan
Visitor Checked In    en: Checked In
Visitor Checked Out   en: Checked Out
Patrol Scheduled      id/en: Terjadwal / Scheduled
Patrol In Progress    id/en: Sedang Berjalan / In Progress
Checkpoint Issue      id/en: Bermasalah / Issue
Incident Acknowledged id/en: Diketahui / Acknowledged
```

These are presentation mappings only; enum decoding still originates from exact canonical wire strings.

## Files Changed / Added

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/core/localization/security_locale_controller.dart
lib/core/network/security_api_client.dart
lib/features/visitor/presentation/detail/visitor_detail_screen.dart
lib/features/visitor/presentation/history/verification_history_screen.dart
lib/features/visitor/presentation/widgets/visitor_status_chip.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/app_dependencies_test.dart
test/security_api_localization_test.dart
test/security_locale_controller_test.dart
docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json
docs/MOBILE_LOCALIZATION_HANDOFF.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/SECURITY_MOBILE_PRD.md
docs/DESIGN_SYSTEM.md
docs/CHECKPOINTS.md
docs/ROADMAP.md
docs/checkpoints/SEC.11_CONTEXT.md
docs/checkpoints/SEC.11A_CONTEXT.md
```

## Deliberate Deferrals

SEC.11A does not implement the Emergency SOS screens/API flow. APH.37 is used here only to keep the localization catalog/transport rules current.

Emergency SOS integration is SEC.12.

Still outside software scope until separate contracts/devices exist:

- panic-button hardware;
- GPS proof/location capture;
- CCTV/NVR automation;
- external siren/alarm panel;
- Firebase/APNs push provider;
- ANPR/LPR/barrier;
- RFID/NFC/BLE/device registry/telemetry.

## Validation Gate

Run:

```powershell
cd E:\aparthub_security
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

Expected:

```text
flutter analyze           ✅ No issues found
flutter test              ✅ All tests passed
flutter build apk --debug ✅ Built app-debug.apk
```

Do not mark SEC.11A `DONE` if any gate is red.

## Validation Attempt 1 — 14 Aug 2026

Local gate after the initial SEC.11A patch produced:

```text
flutter analyze  ✅ No issues found
flutter test     ❌ 4 stale widget expectations
flutter build    ⏳ result not relied on; rerun full gate after hotfix
```

The failures were test-only presentation expectations left from the pre-APH.35C label styling:

```text
Checked-In   -> Checked In
Checked-Out  -> Checked Out
CHECKED-IN   -> CHECKED IN
ISSUE        -> Issue
```

Patrol History also renders `Completed` (and potentially `Cancelled`) in both the filter chip and activity/status content, so exact-one assertions were too strict after catalog alignment.

Validation Hotfix V1 updates `test/widget_test.dart` only for these presentation expectations. No production API, domain, localization resource, repository, or navigation behavior changes.

## Required Regression Evidence

SEC.11A tests specifically cover:

- `Accept-Language` is normalized and sent;
- `Content-Language` is read on success/error responses;
- unsupported request locale falls back to `en`;
- stable backend `VALIDATION_ERROR` remains canonical regardless of localized message;
- API dependencies expose one shared locale seam;
- existing locale preference behavior remains green;
- cumulative Visitor + Patrol + Incident regression remains green.


## Final Validation Closure — 14 Aug 2026

User confirmed the SEC.11A hotfix-v1 revalidation gate green:

```text
flutter analyze           ✅ No issues found
flutter test              ✅ All tests passed
flutter build apk --debug ✅
```

SEC.11A is locked `DONE`. The cumulative green baseline now includes runtime `Accept-Language` / `Content-Language` alignment.

## Next Checkpoint

After SEC.11A is green:

```text
SEC.12 — Emergency SOS Resident → Security
```

SEC.12 will implement the APH.37 software-only Security side: persistent `/emergency-alerts/active` modal queue, foreground/resume refresh, first-wins acknowledge, unresolved/detail/history, and owner-only resolve. No panic hardware, GPS, CCTV or push provider is implied.

## New Chat Bootstrap

```text
Continue Aparthub Security Flutter from SEC.11A.

Locked cumulative baseline:
- SEC.1 through SEC.11 are DONE.
- Visitor Verification + Patrol Management + Incident Reporting are API-integrated and cross-module regression is green.
- Bahasa Indonesia + English UI localization is already established.
- Android readiness baseline remains flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, kotlin.incremental=false.

Current checkpoint:
SEC.11A — APH.35C / APH.37 Localization Runtime Alignment.

SEC.11A implementation:
- IoSecurityApiClient sends Accept-Language id|en on every request, including login.
- It reads normalized Content-Language from success/error responses.
- SecurityLocaleController effective locale is synchronized to the shared API client and unsupported language falls back to en.
- Canonical statuses/severities/error codes remain exact and are never translated in transport/business logic.
- UI status labels are audited against docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json.

Run:
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug

If all green, lock SEC.11A DONE and proceed to SEC.12 Emergency SOS Resident → Security using APH.37.

For SEC.12, GET /api/security/emergency-alerts/active is the durable modal source of truth. Refresh on launch/login/resume and practical foreground cadence. Open -> Acknowledged -> Resolved is canonical. First acknowledge wins atomically; only the owner resolves. Branch on EMERGENCY_* code, never localized message. No panic hardware/GPS/CCTV/push provider/automatic Incident creation.
```
