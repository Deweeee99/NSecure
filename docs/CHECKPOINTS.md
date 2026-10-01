# Aparthub Security Mobile — Checkpoints

## Current

**SEC.16 — Final Production Readiness Revalidation / APH.42 Closure**

Current validation state: `REMEDIATION B IMPLEMENTED / VALIDATION PENDING`

## Locked Green Baseline

SEC.1 through SEC.13 and SEC.15 are `DONE`. SEC.14 production hardening remains cumulative but its final closure was superseded when APH.42 landed before release sign-off.

Preserve:

- Visitor Verification API integration, secure Sanctum session, QR camera + Manual fallback;
- Patrol assigned-session execution, capability-driven checkpoint actions, and APH.42 camera/gallery photo evidence;
- Incident dashboard/list/history/create/detail/timeline and operational mutations;
- Patrol checkpoint → Incident cross-module flow;
- Android readiness baseline (`flutter_secure_storage:^10.3.1`, `mobile_scanner:^7.4.0`, `kotlin.incremental=false`);
- ID/EN localization with `Accept-Language` / `Content-Language` runtime alignment;
- canonical wire values and stable error codes exact;
- cumulative latest-green patch rule.

## SEC.11A Closure

User confirmed the SEC.11A validation hotfix-v1 gate green on 14 Aug 2026. SEC.11A is locked `DONE`.

## SEC.12 Implemented

- new Emergency repository/model/decoder boundary for canonical `Open -> Acknowledged -> Resolved`;
- API endpoints `/emergency-alerts/active`, unresolved list, history, detail, acknowledge and resolve;
- persistent modal overlay driven only by backend `Open` queue;
- active queue refresh on shell creation/login, app resume, post-mutation and 15-second foreground cadence in API mode;
- first-wins acknowledge conflict handling via stable `EMERGENCY_*` codes;
- owner-only resolve UX using backend `taken_by_me` state;
- bilingual Emergency labels aligned to APH.37/APH.38 catalog;
- Emergency module promoted from concept to operational;
- mock repository remains deterministic and does not start foreground polling by default;
- no panic hardware/GPS/CCTV/push/external alarm assumptions.


## SEC.12 Validation Attempt 1

Local gate on 18 Aug 2026:

```text
flutter analyze           ✅ No issues found
flutter test              ❌ 2 stale/lazy-viewport widget assertions
flutter build apk --debug ✅ Built app-debug.apk
```

Hotfix v1 updates only `test/widget_test.dart`: `Emergency Response` → `Emergency SOS`, and the More/catalog active-module assertion now scrolls to the fourth active Emergency card before checking it. Production behavior is unchanged.

## SEC.12 Closure

After validation hotfix v1, the user confirmed the full SEC.12 gate green on 18 Aug 2026. Emergency SOS is locked `DONE`; the current validation focus is SEC.13 below.

## SEC.13 Implemented

- new `SecurityPackageRepository` domain seam with API + deterministic mock implementations;
- APH.38 resident/unit lookup via `/packages/residents/search`;
- list/filter/search package records via `/packages`;
- register packages with client-owned input only; backend owns package number, property/unit, initial status, actors, and timestamps;
- detail and idempotent collect flow via `/packages/{id}` and `/packages/{id}/collect`;
- canonical `Ready for Pickup`, `Collected`, `Expired` wire values remain exact;
- stable `PACKAGE_CENTER_UNAVAILABLE`, `PACKAGE_RESIDENT_NOT_FOUND`, and `PACKAGE_NOT_FOUND` codes map to presentation failures;
- Package Receiving promoted to ACTIVE on Home and More;
- ID/EN labels aligned to APH.38 localization catalog;
- no package-specific persistence, barcode hardware, package photo capture, smart locker, push provider, or proof-of-handover hardware.


## SEC.13 Validation Attempt 1

Local gate on 18 Aug 2026:

```text
flutter analyze           ✅ No issues found
flutter test              ❌ 1 widget-test scrolling helper failure
flutter build apk --debug ✅ Built app-debug.apk
```

The only failure was `Package Receiving registers and collects through Package Center flow`. `scrollUntilVisible()` attempted to resolve `find.byType(Scrollable).last` while the lazy Package form field was not mounted and threw `Bad state: No element`. Validation hotfix v1 is test-only: it uses bounded direct drags on the active Package `ListView` until the lazy target field is mounted. The same robust helper is used for the collection-notes field. Production Package behavior/API/localization is unchanged.

## SEC.13 Closure

The user confirmed the SEC.13 validation hotfix v1 full gate green on 18 Aug 2026. SEC.13 is locked `DONE`.

## SEC.14 Implemented

- production runtime config is now testable through `AppDependencies.fromRuntimeConfig`;
- release mode cannot fall back to mock repositories;
- configured Security API base must end with exact `/api/security`;
- release mode requires HTTPS before API composition;
- final readiness tests verify all five contracted modules resolve to API repositories in release composition;
- `tool/sec14_validate.ps1` runs pub get, l10n generation, analyzer, tests, debug APK and release APK compile;
- `docs/PRODUCTION_READINESS.md` defines the mandatory real-device/backend smoke matrix and closure evidence;
- no new operational module, hardware capability or dependency is introduced.

## SEC.14 Validation

Automated gate:

```powershell
cd E:\aparthub_security
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

`example.invalid` is compile-only. Final `DONE` also requires real Android + real backend smoke using the actual HTTPS host as documented in `docs/PRODUCTION_READINESS.md`.


## SEC.15 Closure — APH.42 Patrol Checkpoint Photo Evidence

The user confirmed the latest cumulative SEC.15 gate green on 19 Aug 2026 after hotfix v5 and SDK-path correction. SEC.15 is locked `DONE`.

Locked APH.42 behavior:

```text
Complete → required photo + optional notes → multipart → refresh Patrol Detail
Skip     → required notes + optional photo → JSON or multipart → refresh Patrol Detail
photo proof → checkpoint.photo_evidence.url only
mutation key → visit_id only
```

No GPS, QR/NFC/RFID/beacon, device registry, scan-token proof, invented endpoint, permanent signed-URL persistence, or automatic mutation retry was added.

## SEC.16 Implemented

SEC.16 is a closure/revalidation checkpoint only. It adds:

- production-readiness regression asserting the shared `IoSecurityApiClient` still supports API localization and the multipart capability required by APH.42;
- a final validation runner that executes APH.42 targeted tests before analyzer/full regression/debug/release builds;
- an updated real-device/backend smoke matrix that includes Patrol Camera/Gallery photo evidence and temporary signed-URL refresh behavior;
- updated PRD/architecture/frontend documentation reflecting APH.42 as an active software capability while hardware proof remains excluded.

## SEC.16 Validation

Analyzer revalidation note: the first SEC.16 runner passed the APH.42 + SEC.16 targeted regression (`27 tests`) and then stopped on one `use_null_aware_elements` info in the optional Complete-checkpoint notes map. Hotfix v1 adopts Dart null-aware map-value syntax without changing the APH.42 wire contract. Full runner revalidation remains required.


Automated:

```powershell
cd E:\aparthub_security
powershell -ExecutionPolicy Bypass -File .\tool\sec16_validate.ps1
```

Or manually:

```powershell
flutter pub get
flutter gen-l10n
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart `
  test/sec16_production_readiness_test.dart
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

`example.invalid` is compile-only. SEC.16 is `DONE` only after real Android + real backend + ID/EN smoke from `docs/PRODUCTION_READINESS.md` is also green.

## SEC.16 Real-Device Smoke Findings / Remediation A

The automated SEC.16 runner was confirmed green, but real Android/backend smoke exposed runtime gaps, so SEC.16 is not `DONE`.

Implemented without changing backend contracts:

- remove Home dashboard values sourced from `SecurityHomeMockData`; KPI section is hidden until a documented backend payload is available;
- remove the non-operational notification button and fake `3` badge;
- Home and More use an explicit production active-module registry and no longer expose Access Control / Vehicle Management / `COMING SOON`;
- remove hard-coded Manual Verify recent-search seeds; only successful searches from the current app session are shown, with Clear support;
- add Android system-Back handling for Home submodules, bottom-navigation areas, Visitor internal stages, and History internal stages; the app can exit only from the actual root Home route;
- keep persistent Open Emergency SOS overlay non-dismissible by Android Back.

Still blocked pending complete backend handoff:

- Package Receiving `unit` response-shape mismatch;
- real Visitor QR verification mismatch.

Do not guess either contract.


## SEC.16 Remediation B — Full API Handoff Alignment

The 20 Aug 2026 current-source Security API handoff is now applied to the remaining real-device blockers.

```text
Security Home KPI       GET /api/security/dashboard — database-backed
Visitor QR validation   POST /visitor-access/validate — decode returned full Visitor payload directly
Package Unit context    top-level object, fallback only to documented resident.unit duplicate
Visitor blacklist       VISITOR_BLACKLISTED mapped explicitly
Inactive modules        remain hidden
Notification control    remains hidden (no endpoint in current contract)
Dummy operational data  prohibited in production
```

Status remains `VALIDATION PENDING`. Re-run `tool/sec16_validate.ps1`, then real-device/backend smoke using `https://airaai.my.id/admin/api/security`.

Validation hotfix v2: Remediation A+B targeted regression passed 45 tests and `flutter analyze` was clean; full regression found only a viewport-sensitive Android Back widget test. The test now scrolls `Package Receiving` into view before tapping it. Production navigation behavior is unchanged.

SEC.16 Runtime Remediation C: Manual Visitor verification is confirmed working,
but real-device QR scanning remains open. The repository contract is already
aligned with the full API handoff; remediation is restricted to MobileScanner
capture lifecycle (`DetectionSpeed.normal`, in-flight duplicate guard, no
stop/start around validation). Real backend QR smoke remains mandatory.

SEC.16 Runtime Remediation D: Visitor action CTA now respects backend `can_check_in` / `can_check_out` rather than inferring actionability from status alone. Real-device Check-In remains pending with a visit valid on the smoke date.

SEC.16 Runtime Remediation E: Visitor Check-In/Check-Out now recover cleanly from ambiguous native HTTP transport failures by normalizing `HttpException`, reconciling authoritative Visitor detail once, and ensuring UI loading state is cleared on unexpected exceptions. No automatic mutation retry is introduced. QR pass rendering remains a separate real-device/upstream investigation.

SEC.16 Runtime Remediation E: fixed shared authenticated JSON POST transport ordering. Bearer/locale headers are now applied before request body bytes are written; GET and multipart behavior are unchanged. Added loopback POST regression coverage.


## SEC.17 — UI & Runtime Corrective Round 1

Status: `IMPLEMENTED — VALIDATION PENDING`

User explicitly keeps production/release decisions outside the automatic
checkpoint flow. SEC.17 is corrective development: Incident Detail CTA layout,
hide ACTIVE badges, and APH.42 multipart/validation corrective work.

See `docs/checkpoints/SEC.17_CONTEXT.md`.


SEC.17 package refinement: Package Collect now distinguishes the physical pickup
recipient (`resident` / `others`) from the authenticated Security processor.
`collected_by` is recipient semantics; `processed_by` is the audit actor.

SEC.17 Package compatibility hotfix v1: historical `collected_by: {id,name}` rows no longer fail the recipient decoder. Legacy actor data is treated as `processed_by` fallback, while physical pickup recipient remains unknown.

SEC.17 Package Collection V2 alignment: canonical `received_by` / `collected_by` / `processed_by` parsing and detail rendering, plus recipient enrichment for already-Collected rows with missing pickup metadata.
