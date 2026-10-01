# Aparthub Security Mobile — Production Readiness

Status: **SEC.16 REMEDIATION B IMPLEMENTED / REVALIDATION + REAL-DEVICE SMOKE PENDING**

Updated: 20 Aug 2026

## 1. Production Software Scope

The final software-only Security Mobile V1 bundle is:

```text
Visitor Verification
Patrol Management — APH.42 photo evidence
Incident Reporting
Emergency SOS
Package Receiving
ID/EN runtime localization
Sanctum Security session
```

Access Control and Vehicle Management remain presentation-only/HOLD. Hardware-dependent capabilities remain outside the production claim.

## 2. Release Runtime Contract

Production/release builds must be started with an explicit Security API base:

```text
SECURITY_API_BASE_URL=https://<host>/<optional-subpath>/api/security
```

Rules:

- release must never silently fall back to mock repositories;
- release API base must be HTTPS;
- configured base must end with exact `/api/security`;
- do not append `/v1`;
- the app owns no production hostname and does not guess one;
- backend remains authoritative for property scope, statuses, actors, timestamps and ownership.

Example compile:

```powershell
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

`example.invalid` is compile-only evidence. Real device/backend smoke must use the actual HTTPS host.

## 3. Automated Gate

Run from the project root:

```powershell
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

SEC.16 cannot close if any automated command is red.

A convenience runner is available at:

```text
tool/sec16_validate.ps1
```

## 4. Real Device + Backend Smoke Gate

Use a real Android device and the real backend URL:

```powershell
flutter run `
  --dart-define=SECURITY_API_BASE_URL=https://airaai.my.id/admin/api/security
```

Validate at least one authorized Security account/property.

### Auth / session

- login succeeds with valid Security credentials;
- invalid credentials stay on login with stable error handling;
- app restart restores the secure session through `/me`;
- logout clears the local bearer token;
- an expired/unauthenticated session returns to authentication without stale operational state.

### Localization

- switch English ↔ Bahasa Indonesia;
- selected locale persists after restart;
- every Security API request sends `Accept-Language: id|en`, including login;
- response `Content-Language` is accepted without changing canonical domain values;
- unsupported locale falls back to `en`;
- machine logic never depends on translated backend `message`.


### Security Home / Dashboard

- Home KPI is loaded only from `GET /api/security/dashboard`;
- verify `total_visitors`, `checked_in`, `checked_out`, and `approved_arrivals` match the backend response for the default accessible Security property;
- `pending_approval` is decoded but is not substituted for the `Pending Arrivals` card;
- network/403 state shows error/retry instead of local numbers;
- notification bell remains absent because the current Security contract has no notification endpoint;
- only Visitor, Patrol, Incident, Emergency SOS, and Package Receiving are visible as active modules.

### Visitor Verification

- Manual Verification works with Visit Code and numeric Visitor ID;
- real opaque Visitor QR can be scanned with camera permission granted; Flutter sends the raw scanner value unchanged as `code`;
- valid `/visitor-access/validate` response is decoded directly from its returned full Visitor payload (no redundant detail GET is required);
- `VISITOR_BLACKLISTED` and other QR lifecycle failures are handled by stable machine code;
- camera denial still leaves Manual Verification available;
- Approved visitor can check in;
- Checked In visitor can check out;
- history reflects server-authoritative mutations;
- network/retry state does not manufacture a successful visit mutation.

### Patrol Management + APH.42 Photo Evidence

- assigned sessions load;
- Scheduled → In Progress start works;
- Complete uses the existing `/patrol/checkpoint-visits/{visit_id}/complete` route and never `checkpoint_id`;
- Complete requires Camera/Gallery photo and accepts optional notes; submit is multipart;
- Skip requires a reason, works as JSON without photo, and switches to multipart only when an optional photo is attached;
- JPG/JPEG, PNG and WEBP up to 5 MB are accepted; missing/invalid/oversized Complete photo surfaces backend/client validation without manufacturing success;
- after successful Complete/Skip, Patrol Detail refreshes and displays canonical backend status, actor/timestamp and `photo_evidence` when present;
- existing Completed/Skipped evidence opens only `checkpoint.photo_evidence.url`; no file path/URL is synthesized;
- if a temporary signed URL expires, refreshing Patrol Detail obtains a new URL instead of persisting/rebuilding the old one;
- a network timeout/ambiguous mutation result is not automatically retried; refresh Patrol Detail before any retry;
- Patrol completes only when backend allows it;
- Patrol history loads terminal sessions;
- Patrol `In Progress` + Pending checkpoint can open linked Incident creation;
- linked Incident creation returns with checkpoint canonical `Issue` from backend state.

### Incident Reporting

- dashboard/list/history load;
- standalone Incident can be created with authorized property context;
- detail/timeline load;
- acknowledge/start/resolve/add-note obey backend `can_*` flags;
- canonical status/severity values remain exact on the wire.

### Emergency SOS

- an Open Resident SOS appears in the persistent Security modal;
- relaunch/resume shows the same durable Open alert again;
- first Security acknowledge removes it from `/active` for all clients;
- competing officer receives stable conflict handling;
- only the taking Security officer can resolve;
- resolved alert moves to history;
- no local modal dismissal is treated as a backend state transition.

### Package Receiving

- Resident/Unit search returns only backend-authorized active context;
- Package payload Unit/Property objects decode from the documented top-level copy, with fallback only to the same documented nested `resident.unit` / `resident.property` copy if the top-level duplicate is not an object;
- package receive sends only documented client-owned fields;
- created record is visible as canonical `Ready for Pickup`;
- the same durable record is visible from existing Package Center/Resident surfaces when tested cross-app;
- collect transitions to canonical `Collected` and remains idempotent;
- Package Center unavailable / not-found states are handled by stable `PACKAGE_*` code.

## 5. Network / Failure Smoke

Verify one controlled failure condition:

- backend unreachable → clear network failure/retry behavior;
- timeout → no false success;
- 401 → session exit/auth recovery;
- 403 → action blocked without leaking another property;
- cross-property resource probing → module-specific not-found behavior where contracted.

## 6. Explicitly Not Claimed

APH.42 **does** make Patrol checkpoint photo evidence operational. The following separate hardware/automation capabilities remain unclaimed:

```text
panic-button hardware
GPS proof-of-presence
CCTV/NVR automation
external siren/alarm panel
Firebase/APNs push provider
ANPR/LPR/barrier
RFID/NFC/BLE proof
Device Registry / device telemetry
dedicated package/QR scanner hardware
package photo evidence
smart lockers
proof-of-handover hardware
```

## 7. Known Non-Blocking Technical Debt

Current Android builds may warn that `mobile_scanner` still applies the Kotlin Gradle Plugin and will need migration for a future Flutter Built-in Kotlin requirement. It is not a current build blocker.

Do not upgrade `mobile_scanner`, `flutter_secure_storage`, AGP, Kotlin, or compile SDK inside SEC.16 solely to remove future warnings. Preserve the validated baseline:

```text
flutter_secure_storage 10.3.1
mobile_scanner 7.4.0
kotlin.incremental=false
```

## 8. Closure Evidence

Record final evidence before marking SEC.16 `DONE`:

```text
APH.42 targeted tests       PASS / FAIL
flutter analyze             PASS / FAIL
flutter test                PASS / FAIL
flutter build apk --debug   PASS / FAIL
flutter build apk --release PASS / FAIL
real Android smoke          PASS / FAIL
real backend smoke          PASS / FAIL
ID/EN smoke                 PASS / FAIL
```

SEC.16 `DONE` means the contracted software scope above, including APH.42 Patrol photo evidence, is green. It does not promote any HOLD/hardware capability to production.

## 9. Real-Device Smoke Remediation Gate

Production UI must never substitute operational mock data for missing backend data. Re-smoke these presentation/navigation rules after applying the SEC.16 remediation patch:

- Home has no mock KPI values; in API mode KPI values come only from the documented `GET /api/security/dashboard` response, while mock/debug composition without a dashboard repository keeps the section absent;
- no fake/non-operational notification bell or notification count is shown;
- Access Control, Vehicle Management, and all `COMING SOON`/inactive module cards are absent from production Home/More;
- Manual Verify has no seeded recent-search examples; successful current-session manual searches may appear as real session history and Clear removes them;
- Android system Back returns Package/Patrol/Incident/Emergency screens to Home, steps Visitor/History internal flows backward, returns bottom tabs to Home, and exits only from root Home;
- an Open Emergency SOS persistent overlay remains non-dismissible by Android Back.

Package Receiving response decoding and real Visitor QR verification are now aligned to the full current-source handoff dated 20 Aug 2026. Do not mark SEC.16 `DONE` until both are re-smoked successfully against the real backend.


## 10. Full API Handoff Alignment — 20 Aug 2026

Canonical frontend handoff stored at:

```text
docs/APARTHUB_SECURITY_API_HANDOFF_FULL_2026-08-20.md
```

Known deployment context:

```text
Application : https://airaai.my.id/admin
API base    : https://airaai.my.id/admin/api
Security    : https://airaai.my.id/admin/api/security
```

Important real-device permission caveat: Incident creation and Package registration require explicit `security-management:create`. A valid Security login can still receive `403 FORBIDDEN` for those create actions. Treat that as backend provisioning state, not a frontend success/failure guess.
