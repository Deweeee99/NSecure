# SEC.16 Context — Final Production Readiness Revalidation / APH.42 Closure

Status: **REAL-DEVICE SMOKE REMEDIATION B IMPLEMENTED / VALIDATION PENDING**

Date opened: 19 Aug 2026

## Objective

Re-run the final production-readiness closure against the latest cumulative green Security Mobile baseline after APH.42 Patrol Checkpoint Photo Evidence landed. SEC.16 adds **no product scope** and invents no backend endpoint.

## Locked Input Baseline

```text
SEC.1–SEC.13  DONE
SEC.14        production runtime hardening remains cumulative
SEC.15        DONE — APH.42 automated integration gate green
```

Operational software scope:

```text
Auth / Sanctum session
Visitor Verification
Patrol Management + checkpoint photo evidence
Incident Reporting
Emergency SOS
Package Receiving
Bahasa Indonesia + English
```

## Production Contract Revalidated

Release configuration remains unchanged:

```text
SECURITY_API_BASE_URL=https://<host>/api/security
```

Release must fail closed when the base is empty, non-HTTPS, or does not end with exact `/api/security`. Mock fallback remains debug/test only.

APH.42 does not change Patrol routes. Final readiness assumes exactly:

```text
GET  /api/security/patrol/sessions/{patrol_session_id}
POST /api/security/patrol/checkpoint-visits/{visit_id}/complete
POST /api/security/patrol/checkpoint-visits/{visit_id}/skip
```

Complete/Skip mutations use `visit_id`, never `checkpoint_id`.

## SEC.16 Implementation

### Production-readiness regression

`test/sec16_production_readiness_test.dart` verifies:

- valid release composition still wires Auth, Visitor, Patrol, Incident, Emergency SOS, and Package Receiving API repositories;
- device QR scanning and Emergency foreground polling remain enabled only in API composition;
- `IoSecurityApiClient` remains the shared API localization client and now also satisfies the narrow `SecurityMultipartApiClient` capability required by APH.42;
- locale normalization still resolves regional ID/EN variants to `id` / `en`;
- APH.42 photo input contract remains exact JPG/JPEG MIME, PNG, WEBP and 5 MB maximum.

### Validation runner

`tool/sec16_validate.ps1` executes in this order:

```text
flutter pub get
flutter gen-l10n
APH.42 targeted regression
SEC.16 readiness regression
flutter analyze
full flutter test
debug APK
release APK compile
```

Default release URL is `https://example.invalid/api/security` and is compile-only.

### Production smoke matrix

`docs/PRODUCTION_READINESS.md` now includes APH.42 real-device/backend evidence:

```text
Complete via Camera
Complete via Gallery
Complete photo validation
Skip reason-only
Skip reason + optional photo
Completed/Skipped evidence rendering
expired signed URL → refresh Patrol Detail
network ambiguity → refresh before retry
ID/EN
```

## Files Changed / Added

```text
test/sec16_production_readiness_test.dart
tool/sec16_validate.ps1
docs/PRODUCTION_READINESS.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/SECURITY_MOBILE_PRD.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/checkpoints/SEC.15_CONTEXT.md
docs/checkpoints/SEC.16_CONTEXT.md
```

## Deliberate Deferrals / Non-Goals

SEC.16 does not introduce:

```text
new Patrol endpoint
GPS proof
checkpoint QR/NFC/RFID/beacon proof
device registry
scan-token exposure
public evidence storage
permanent signed-URL persistence
automatic mutation retry
package photo evidence
new push/hardware integration
```

## Validation Gate

Run:

```powershell
cd E:\aparthub_security

powershell -ExecutionPolicy Bypass `
  -File .\tool\sec16_validate.ps1
```

Equivalent manual gate:

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

Then use a real Android device with the actual HTTPS backend and complete every relevant item in `docs/PRODUCTION_READINESS.md`.

## Validation Attempt 1 — Analyzer Hotfix

Automated runner evidence on 19 Aug 2026:

```text
APH.42 + SEC.16 targeted regression  PASS — 27 tests
flutter analyze                      BLOCKED — 1 info lint
```

The sole analyzer blocker was `use_null_aware_elements` in `ApiPatrolRepository.completeCheckpoint()` for the optional `notes` multipart field. The collection entry was updated from an explicit null-check element to Dart null-aware map-value syntax:

```dart
fields: <String, String>{'notes': ?note},
```

This is presentation/serialization cleanup only. It does not change the APH.42 endpoint, mutation identity, multipart requirement, optional-note semantics, or backend ownership. Re-run the complete `tool/sec16_validate.ps1` gate after applying the hotfix.

## Closure Rule

Only mark SEC.16 `DONE` when:

```text
APH.42 targeted tests       PASS
SEC.16 readiness test       PASS
flutter analyze             PASS
full flutter test           PASS
debug APK                   PASS
release APK compile         PASS
real Android smoke          PASS
real backend smoke          PASS
ID/EN smoke                 PASS
APH.42 Camera/Gallery smoke PASS
```

## Next

There is no automatic SEC.17 product checkpoint after closure. Any new Security capability requires an explicit product/backend/hardware contract.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile Flutter
Current checkpoint: SEC.16 — Final Production Readiness Revalidation / APH.42 Closure
Status: REAL-DEVICE SMOKE REMEDIATION B IMPLEMENTED / VALIDATION PENDING

Locked baseline:
- SEC.1–SEC.13 DONE.
- SEC.14 production runtime hardening remains cumulative.
- SEC.15 APH.42 Patrol Checkpoint Photo Evidence DONE after automated gate green.
- Active: Visitor, Patrol + photo evidence, Incident, Emergency SOS, Package Receiving, ID/EN.
- Production UI rule: no dummy operational data. Missing/undocumented data is hidden or empty, never seeded.
- Remediation A removed non-operational notification UI, hid inactive/Coming Soon modules, removed seeded Manual Verify recents, and fixed Android system Back for shell/internal Visitor/History stages.
- Remediation B applies the full current-source Security API handoff dated 20 Aug 2026: Home KPI now comes only from GET /dashboard, valid Visitor QR decodes the full /visitor-access/validate response directly, and Package Unit/Property decoding can fall back only between the two object copies documented by the handoff.
- Known real backend smoke base is https://airaai.my.id/admin/api/security; runtime composition remains configurable and does not hard-code the host.
- Incident create and Package receive can legitimately return 403 when the Security account lacks explicit security-management:create; Flutter must surface this state rather than fake success.
- Release cannot fall back to mock and requires HTTPS SECURITY_API_BASE_URL ending exact /api/security.
- APH.42 uses existing Patrol routes only; Complete/Skip mutation key is visit_id.
- Complete requires multipart photo; notes optional.
- Skip requires notes; photo optional; JSON without photo, multipart with photo.
- photo_evidence.url is temporary signed backend URL; never reconstruct/persist permanent path.
- No automatic mutation retry after ambiguous timeout; refresh Patrol Detail first.
- No GPS/QR/NFC/RFID/beacon/device-registry proof.

Run:
powershell -ExecutionPolicy Bypass -File .\tool\sec16_validate.ps1

If automated gate is green, run real Android + real backend smoke from docs/PRODUCTION_READINESS.md using the full 20 Aug handoff. Do not lock SEC.16 DONE until Home KPI, real Visitor QR, Package decoding/create permissions, Android Back, no-dummy UI, ID/EN, APH.42 Camera/Gallery, and the broader active-module smoke are all green.
```

## Real-Device Smoke Finding — Remediation A

Automated SEC.16 validation completed successfully. Real-device/backend smoke then exposed production presentation/navigation defects, so final closure is intentionally reopened.

This remediation changes only frontend behavior that is contract-independent:

1. removes all Home KPI mock values and hides the KPI section until a documented backend dashboard payload is available;
2. removes the non-operational notification control and fake badge;
3. hides inactive/Coming Soon modules from Home and More;
4. removes seeded Manual Verify recent-search values and keeps only successful current-session search history;
5. adds Android system-Back semantics across shell-controlled screens and Visitor/History internal stages; root Home remains the only app-exit point.

Production release composition still cannot fall back to mock repositories. Development mock mode remains available only when explicitly running without the release API composition.

Deliberately untouched by Remediation A pending the full backend handoff (resolved by Remediation B below):

```text
Package Receiving: Package field unit must be an object
Visitor QR: real-backend verification mismatch
```

No decoder shape, QR endpoint, QR payload mutation, or compatibility fallback is invented.

### Remediation A files changed / added

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/features/security/data/mock/security_home_mock_data.dart
lib/features/security/domain/models/security_module_registry.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/visitor/presentation/history/verification_history_flow.dart
lib/features/visitor/presentation/verification/manual_visitor_search_screen.dart
lib/features/visitor/presentation/verification/visitor_verification_flow.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/sec16_runtime_remediation_test.dart
test/widget_test.dart
tool/sec16_validate.ps1
docs/CHECKPOINTS.md
docs/PRODUCTION_READINESS.md
docs/ROADMAP.md
docs/checkpoints/SEC.16_CONTEXT.md
```

Recent Manual Verify searches are deliberately **current-session only** in Remediation A. They are created only by real successful search requests, are de-duplicated, capped at five entries, can be cleared by the user, and are not persisted across an app restart.

### Revalidation

```powershell
cd E:\aparthub_security

powershell -ExecutionPolicy Bypass `
  -File .\tool\sec16_validate.ps1
```

After automated green, repeat real-device smoke for the presentation/navigation items above. Final SEC.16 closure still waits for the complete Package + Visitor QR backend handoff and their real-backend smoke.


## Real-Device Smoke Finding — Remediation B / Full API Handoff 20 Aug 2026

The complete current-source Security API handoff dated 20 Aug 2026 is now the frontend contract authority for the remaining runtime blockers. The handoff is stored in:

```text
docs/APARTHUB_SECURITY_API_HANDOFF_FULL_2026-08-20.md
```

Known deployment base from the handoff:

```text
https://airaai.my.id/admin/api/security
```

The app remains runtime-configurable; this hostname is not hard-coded into production composition.

### Database-backed Home KPI

`GET /api/security/dashboard` is now wired through `SecurityDashboardRepository`. Home renders KPI values only from the documented response:

```text
total_visitors
approved_arrivals
checked_in
checked_out
```

`pending_approval` is decoded and retained in the dashboard model for contract completeness, but the existing four-card layout maps `Pending Arrivals` to backend `approved_arrivals`. No local KPI fallback or mock number is used in API mode. Network/authorization failure renders a retry/error state instead of fabricated values. Mock/debug composition continues to hide the KPI section because it has no database-backed dashboard repository.

### Visitor QR contract closure

`POST /api/security/visitor-access/validate` is authoritative and returns the full Visitor payload on valid QR. `ApiVisitorRepository.verifyQrPayload()` now decodes that response directly instead of issuing an unnecessary second `GET /visitors/{visit_id}` after a successful scan. The raw scanner payload is still sent unchanged as:

```json
{"code":"<raw QR access code>"}
```

Check-In remains:

```text
verification_method = qr
code = original QR access code
```

Optional `access_card_number` is no longer sent as a JSON null when it is not used. Stable `VISITOR_BLACKLISTED` is now mapped explicitly and localized for presentation.

### Package payload closure

The full contract documents the same Property/Unit context in both the top-level Package payload and the nested Resident payload. The decoder now uses the top-level object when valid and may fall back only to the documented nested `resident.property` / `resident.unit` object copy when the top-level duplicate is not an object. No new field or endpoint is invented.

The decoder also accepts a numeric-string Unit `floor`, matching the current handoff examples.

This remediation is intentionally fail-closed when neither documented object copy exists.

### Permission caveat

The handoff confirms that Incident create and Package receive require explicit `security-management:create`. A Security account may have login/read/update capability while these create actions return `403 FORBIDDEN`. Flutter must surface that backend state and must not work around it client-side.

### Remediation B changed/additional areas

```text
lib/core/bootstrap/app_dependencies.dart
lib/app.dart
lib/features/security/domain/models/security_dashboard.dart
lib/features/security/domain/repositories/security_dashboard_repository.dart
lib/features/security/data/api/api_security_dashboard_repository.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/package/data/api/security_package_api_decoder.dart
lib/features/visitor/data/api/api_visitor_repository.dart
lib/features/visitor/domain/repositories/visitor_repository.dart
lib/features/visitor/presentation/widgets/visitor_repository_failure_message.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/api_security_dashboard_repository_test.dart
test/api_security_package_repository_test.dart
test/api_visitor_repository_test.dart
test/app_dependencies_test.dart
test/sec14_production_readiness_test.dart
test/sec16_production_readiness_test.dart
tool/sec16_validate.ps1
docs/APARTHUB_SECURITY_API_HANDOFF_FULL_2026-08-20.md
docs/PRODUCTION_READINESS.md
docs/CHECKPOINTS.md
docs/ROADMAP.md
docs/checkpoints/SEC.16_CONTEXT.md
```

### Revalidation after Remediation B

Run the complete runner again:

```powershell
cd E:\aparthub_security

powershell -ExecutionPolicy Bypass `
  -File .\tool\sec16_validate.ps1
```

Then real backend/device smoke should use the currently known deployment base:

```powershell
flutter run `
  --dart-define=SECURITY_API_BASE_URL=https://airaai.my.id/admin/api/security
```

Required re-smoke focus:

```text
Home KPI matches GET /security/dashboard
Visitor QR valid code resolves directly from validate response
Visitor QR invalid/blacklisted/state failures map by stable code
Package list/detail loads without unit decoder failure when documented nested copy is present
Package receive handles explicit 403 create-permission denial without fake success
Android Back / hidden inactive modules / no dummy operational data remain green
```

SEC.16 remains open until automated regression and the real-device/backend smoke are green.


## Validation Hotfix v2 — Android Back Widget Viewport

Runtime Remediation A+B targeted regression passed (`45 tests`) and `flutter analyze`
reported no issues. Full regression then stopped on the widget test:

```text
Android system Back returns through app screens
```

This was a test-viewport issue, not a production navigation failure. In Flutter's
default 800x600 widget-test viewport, the fifth Home module (`Package Receiving`)
was mounted below the visible area. `tester.tap(find.text('Package Receiving'))`
therefore missed the widget and the test never entered Package Receiving.

Validation hotfix v2 changes only the test interaction:

```text
ensureVisible(Package Receiving)
→ settle scroll
→ tap Package Receiving
```

No production navigation, API, repository, localization, package decoder, QR
contract, or Android Back implementation is changed.

Re-run:

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\tool\sec16_validate.ps1
```

SEC.16 remains `REMEDIATION B IMPLEMENTED / VALIDATION PENDING` until the full
automated runner and real-device/backend smoke are green.


## Runtime Remediation C — Visitor QR Scanner Capture Lifecycle

Real-device smoke confirmed Manual Visitor verification works while device QR
scanning remains unreliable. The full 20 Aug 2026 API handoff confirms that the
scanner must submit the raw QR access code unchanged to:

```text
POST /api/security/visitor-access/validate
{"code":"<raw-access-code>"}
```

The API repository already follows that contract. The remaining remediation is
therefore limited to the device capture lifecycle:

- `MobileScanner` detection changes from `noDuplicates` to `normal`;
- an in-flight capture coordinator suppresses duplicate backend requests;
- the camera is no longer explicitly stopped before validation and restarted
  afterwards;
- the same QR can be scanned again after a rejected/failed validation;
- raw QR data is not normalized, wrapped, logged, or mutated.

No endpoint, request field, QR content format, or backend behavior is invented.

SEC.16 remains `REAL-DEVICE SMOKE / REMEDIATION PENDING` until a real Visitor QR
generated by the backend is successfully validated and check-in is smoke-tested.


## Runtime Remediation D — Visitor Check-In Capability Alignment

Real-device smoke showed Visitor manual lookup working, while Check-In appeared
available for an Approved visit that was not yet valid for action. The full
20 Aug 2026 Security API handoff documents backend-owned Visitor capability
fields:

```text
can_check_in
can_check_out
```

Flutter previously inferred these actions from canonical status only
(`Approved => Check-In`, `Checked In => Check-Out`). That can expose a Check-In
CTA before the backend considers the visit actionable, for example a future
Approved visit.

Remediation D decodes the backend capability flags and makes them authoritative
when present. Status remains canonical display/domain state; action availability
comes from the backend payload. No client-side visit-date rule is invented.

For deterministic mock/legacy fixtures that omit the additive capability fields,
status-derived fallback is retained outside the production current-source
contract.

The device pass used during smoke is dated 21 Aug 2026 while the smoke occurred
on 20 Aug 2026. Under the current backend contract, such a visit is expected to
be non-actionable today and QR validation/check-in may return
`VISITOR_NOT_VALID_TODAY`.

SEC.16 remains open until a Visitor valid on the actual smoke date succeeds via
real QR validation and Check-In, and manual Check-In/Check-Out are also re-smoked.

## Runtime Remediation E — Visitor Check-In Transport Recovery

Real-device smoke on 20 Aug 2026 confirmed that Manual Visitor lookup reaches a
real Approved visit, but the Check-In CTA can remain in `Checking In...` while
the POST transport does not complete cleanly on-device.

The current backend contract remains unchanged:

```text
POST /api/security/visitors/{visitor}/check-in
verification_method = manual | qr
code = required only for qr
```

Remediation E does not invent a new mutation or retry Check-In automatically.
It adds three resilience rules:

1. native `HttpException` is normalized to `NETWORK_ERROR`, the same as socket /
   TLS transport failures;
2. after ambiguous `NETWORK_ERROR` / `NETWORK_TIMEOUT`, Flutter performs one
   read-only `GET /visitors/{visit_id}` reconciliation; if backend already moved
   the Visitor to `Checked In` / `Checked Out`, that authoritative state is
   accepted;
3. presentation flows have a final exception safety net so a non-domain runtime
   exception cannot leave the CTA permanently stuck in loading state.

Mutation retry remains manual. The frontend never sends the Check-In POST twice
just because the first response was ambiguous.

The QR screenshot supplied during the same smoke was independently detectable as
a QR-shaped symbol but could not be decoded from the rendered screenshot by a
standard QR decoder. Because Manual access-code lookup works, QR generation /
rendering in the Resident pass must be checked separately from the Security API
contract before adding more scanner-side assumptions.


## Runtime Remediation E — Authenticated JSON POST Transport Ordering

Real-device smoke established a decisive pattern:

```text
GET Visitor manual search/detail  -> works
POST Visitor QR validate          -> NETWORK_ERROR
POST Visitor Check-In             -> NETWORK_ERROR / previously stuck
```

Audit found the shared transport defect in `IoSecurityApiClient._send()`.
For JSON POST requests the client wrote the body before applying the Bearer
Authorization header:

```text
request.write(json body)
-> _applyAuthorization(...)
```

`dart:io` `HttpClientRequest` headers become immutable once request body data is
written. On device this can throw `HttpException`, which the remediation layer
correctly mapped to `NETWORK_ERROR`. This explains why authenticated GET requests
worked while authenticated JSON POST flows failed together.

Remediation E changes the ordering only:

```text
Accept / Accept-Language
-> Authorization: Bearer <token>
-> Content-Type
-> write JSON body
-> close request
```

No endpoint, request payload, token format, or backend contract changes.
A loopback regression test verifies authenticated POST preserves Bearer,
Accept-Language, JSON body, and Content-Language handling.

This transport fix applies to all JSON POST Security actions, including Visitor
QR validation, Visitor Check-In/Check-Out, Patrol start/complete, Incident
mutations, Emergency acknowledge/resolve, and Package collect/receive JSON paths.
Multipart Patrol photo requests already applied authorization before writing
multipart body and were not affected by this ordering bug.
