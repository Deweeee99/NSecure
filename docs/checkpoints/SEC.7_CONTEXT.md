# SEC.7 Context — Security API Integration

## Current Status

`DONE`

Backend handoff was integrated and SEC.7 is locked DONE after full local revalidation.

Normative sources:

```text
docs/API_CONTRACT_SECURITY_MOBILE_V1.md
docs/postman/Aparthub_Security_Visitor_V1.postman_collection.json
```

The former `docs/API_HANDOFF_DRAFT.md` is superseded for SEC.7 and retained only as historical frontend-proposal context.

## Backend Contract Audit

Confirmed from final handoff:

- prefix `/api/security`; no URL `/v1` segment;
- Laravel Sanctum Bearer token from `data.token`;
- login, me, logout;
- visitor search with one `q` parameter;
- exact opaque QR credential via `POST /visitor-access/validate` body `code`;
- QR validation is read-only and does not Check-In;
- Visitor Detail uses numeric `visit_id`;
- V1 `visitor_id == visit_id` compatibility alias;
- manual vs QR Check-In request differs by `verification_method` and QR `code`;
- backend owns actor identity and Check-In/Check-Out timestamps;
- exact wire statuses: `Pending`, `Approved`, `Rejected`, `Checked In`, `Checked Out`, `Cancelled`, `Expired`;
- ISO-8601 timestamps with backend timezone offset;
- stable machine-readable error codes;
- History is paginated with `has_more` and default `updated_at DESC, id DESC`;
- property authorization is backend-derived; Flutter must not send property/tower authorization selectors;
- QR/access credential is never returned in Visitor detail/search payloads.

Important contract correction versus early frontend mock:

```text
visit_id     numeric backend ID
visitor_id   same numeric ID in V1
visit_code   VST-* manual reference
QR credential opaque and separate from visit_code
```

## Implemented

### Transport

Added `IoSecurityApiClient` using `dart:io` with:

- configurable `SECURITY_API_BASE_URL`;
- JSON Accept/Content-Type headers;
- Bearer token header;
- canonical JSON error decoding;
- no hardcoded production host.

### Authentication

Added:

```text
SecurityAuthRepository
ApiSecurityAuthRepository
SecurityAuthGate
SecurityLoginScreen
```

Login reads Sanctum token from `data.token`. Logout revokes the current token and clears the in-memory mobile session.

SEC.7 token persistence is intentionally in-memory only. Secure persisted token storage is deferred to SEC.8 Android readiness.

### Visitor API

Added `ApiVisitorRepository` for:

```text
search
verifyQrPayload
findByVisitId
checkIn
checkOut
history
```

QR validation sends the raw credential unchanged and then loads canonical Visitor Detail because the validation success payload is intentionally compact.

History transparently follows backend pagination using `per_page=100` until `has_more=false`, preserving the existing UI contract without exposing pagination mechanics to widgets.

### Domain Alignment

- Check-In repository method now carries `VisitorVerificationMethod.manual|qr` and optional QR payload because the final backend contract proves that capability difference.
- Visitor ID / Visit ID mock values now mirror the backend numeric alias model.
- nullable tower/unit/schedule/validity fields are tolerated by the domain/UI.
- `qrPayload` is optional and mock-only on `VisitorVisit` because backend never returns the credential.
- added failure codes for Pending, not-valid-today, and validation failures.

### UI Composition

Runtime selection:

```text
No SECURITY_API_BASE_URL
→ deterministic mock mode

SECURITY_API_BASE_URL supplied
→ API mode
→ Security login
→ Bearer-authenticated Visitor flow
```

The authenticated Security user is shown on Home in API mode. Dashboard counters remain mock/presentation values because the delivered handoff contains the Dashboard request route but no Dashboard response schema.

### Deliberate Deferrals

Not implemented in SEC.7:

- native camera QR capture;
- persisted secure token storage;
- dashboard remote counters because response schema was not supplied;
- protected identity-photo rendering;
- Patrol/Incident/Emergency/Access/Vehicle API calls;
- hardware integrations.

These must not be inferred from the Visitor V1 contract.

## Files Created / Modified

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/core/network/security_api_client.dart
lib/features/security/data/api/api_security_auth_repository.dart
lib/features/security/domain/repositories/security_auth_repository.dart
lib/features/security/presentation/auth/security_auth_gate.dart
lib/features/security/presentation/auth/security_login_screen.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/visitor/data/api/api_visitor_repository.dart
lib/features/visitor/data/api/visitor_api_decoder.dart
lib/features/visitor/data/mock/mock_visitor_repository.dart
lib/features/visitor/domain/models/visitor_visit.dart
lib/features/visitor/domain/repositories/visitor_repository.dart
lib/features/visitor/presentation/detail/visitor_action_confirmation_screen.dart
lib/features/visitor/presentation/detail/visitor_detail_screen.dart
lib/features/visitor/presentation/history/verification_history_screen.dart
lib/features/visitor/presentation/verification/manual_visitor_search_screen.dart
lib/features/visitor/presentation/verification/qr_visitor_verification_screen.dart
lib/features/visitor/presentation/verification/visitor_search_results_screen.dart
lib/features/visitor/presentation/verification/visitor_verification_flow.dart
lib/features/visitor/presentation/widgets/visitor_formatters.dart
lib/features/visitor/presentation/widgets/visitor_repository_failure_message.dart
test/api_security_auth_repository_test.dart
test/api_visitor_repository_test.dart
test/app_dependencies_test.dart
test/mock_visitor_repository_test.dart
docs/API_CONTRACT_SECURITY_MOBILE_V1.md
docs/postman/Aparthub_Security_Visitor_V1.postman_collection.json
docs/API_HANDOFF_DRAFT.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/SEC.7_CONTEXT.md
```

## Validation Attempt 1

Local validation on 12 Aug 2026 produced:

```text
flutter analyze           ❌ 2 info (`unnecessary_underscores`)
flutter test              ❌ 4 widget tests
flutter build apk --debug ✅
```

The four widget failures were:

- Approved Visitor Detail could not find `checkInVisitorButton`;
- Checked-In Visitor Detail could not find `checkOutVisitorButton`;
- Expired Visitor Detail could not find its read-only blocked message;
- the new Check-In History test failed while trying to `ensureVisible` an unmounted action.

### Root Cause

SEC.7 was based on an older Visitor presentation copy and accidentally overwrote the already-green SEC.4 persistent-footer hotfix. Actions were moved back into a lazy `ListView`, so they were not mounted in the default widget-test viewport. The history file also regressed to `(_, __)` callbacks.

This is a presentation-baseline regression, not a change to the final backend contract or API repository semantics.

### Hotfix V1

- restore `visitorDetailScroll` plus persistent `_DetailActionFooter`;
- retain SEC.7 nullable Tower/Unit formatting;
- restore persistent `Done` / `Continue Verifying` confirmation footer;
- retain SEC.7 `unitAndTower(...)` formatting in confirmation content;
- restore single-wildcard analyzer-safe `separatorBuilder: (_, _)`;
- no API transport/repository/auth behavior changed.

## Validation Gate

Revalidation required after hotfix v1:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Do not lock SEC.7 `DONE` until all gates are green.

## Final Revalidation

Local revalidation after hotfix v1 passed on 12 Aug 2026:

```text
flutter analyze           ✅ No issues found
flutter test              ✅ 37 tests passed
flutter build apk --debug ✅
```

SEC.7 is locked `DONE`. SEC.8 owns native QR camera capture, secure token persistence, and final Android hardening.

## API Runtime Smoke Test

When a reachable backend host is available, launch API mode with:

```powershell
flutter run --dart-define=SECURITY_API_BASE_URL=https://<host>/api/security
```

Do not add `/v1` to the route.

## Known Limitation

The backend handoff status says `FINAL FOR SEC.7 INTEGRATION — runtime patch pending local regression`. Frontend integration is based on the supplied final contract, but end-to-end runtime should still be smoke-tested against the backend instance after both sides are locally green.

## Next Checkpoint

After SEC.7 is green and locked:

`SEC.8 — Final Mobile Regression + Android Readiness`

Expected SEC.8 focus includes native QR camera capture, secure token persistence, Android network/runtime readiness, and final full regression without activating future modules.

## New Chat Bootstrap

> Historical SEC.7 bootstrap. For current work, use `docs/checkpoints/SEC.8_CONTEXT.md`.


```text
Project: Aparthub Security Mobile (Flutter frontend only).
Current checkpoint: SEC.7 — Security API Integration.
Status: HOTFIX V1 APPLIED — REVALIDATION REQUIRED.
Last completed: SEC.6 DONE; SEC.1–SEC.6 gates are green.

Read first:
1. docs/checkpoints/SEC.7_CONTEXT.md
2. docs/API_CONTRACT_SECURITY_MOBILE_V1.md
3. docs/CHECKPOINTS.md
4. docs/ROADMAP.md
5. docs/ARCHITECTURE.md
6. docs/FRONTEND_SPEC.md
7. docs/DESIGN_SYSTEM.md

Backend handoff is final for SEC.7 Visitor Verification. Do not use API_HANDOFF_DRAFT.md as the normative contract anymore.

Locked contract highlights:
- /api/security prefix, no /v1 URL segment.
- Sanctum Bearer token is data.token.
- visit_id is numeric; visitor_id is the same numeric compatibility alias in V1.
- visit_code is a VST-* manual reference and is NOT the QR credential.
- QR credential is opaque, exact/case-sensitive, sent as code, and never returned by Visitor payloads.
- Check-In must send verification_method manual or qr; QR mode also sends code.
- backend owns actor/timestamps.
- statuses are exact wire strings: Pending, Approved, Rejected, Checked In, Checked Out, Cancelled, Expired.
- property scope is derived backend-side; never send property_id/tower_id as auth selectors.

SEC.7 implementation:
- IoSecurityApiClient via dart:io.
- ApiSecurityAuthRepository + login gate.
- ApiVisitorRepository for search/QR/detail/check-in/check-out/history.
- environment switch: SECURITY_API_BASE_URL; absent means deterministic mock mode.
- token is in-memory only until SEC.8.
- dashboard counters remain mock because no dashboard response schema was supplied.
- native camera QR capture is deferred to SEC.8.

Current validation state:
- Attempt 1: analyze had 2 info, tests had 4 viewport regressions, APK build passed.
- Hotfix v1 restores the already-locked SEC.4 persistent action/footer behavior while preserving SEC.7 API changes.

Next action:
Run flutter pub get, flutter analyze, flutter test, flutter build apk --debug. Lock SEC.7 only when the full gate is green, then continue SEC.8.
```
