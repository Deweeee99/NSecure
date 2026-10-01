# SEC.11 Context — Cross-Module Regression: Visitor + Patrol + Incident

Status: **DONE**

Date opened: 13 Aug 2026

## Objective

Close the software-only Security Mobile V1 cumulative baseline by validating Visitor, Patrol, and Incident together and activating the documented Patrol checkpoint → Incident report workflow without expanding into hardware-dependent scope.

## Locked Input Baseline

SEC.1 through SEC.10 are green/DONE. Preserve:

- Visitor API integration, QR camera + manual fallback, secure Sanctum session;
- Patrol API integration and backend capability-driven actions;
- Incident API integration and backend `can_*` capability-driven lifecycle;
- Bahasa Indonesia + English localization;
- Android SEC.8 readiness settings;
- exact backend wire statuses/error codes;
- latest cumulative green source rule.

## Implementation

### Patrol → Incident

Eligible flow:

```text
Patrol status = In Progress
Checkpoint status = Pending
        ↓
Report Issue / Laporkan Masalah
        ↓
Incident Create
  property_id = already-authorized Patrol property context
  patrol_checkpoint_visit_id = canonical checkpoint visit ID
        ↓
POST /api/security/incidents
        ↓
backend owns Incident + checkpoint Issue transition
```

`SecurityAppShell` owns cross-module navigation composition. Patrol presentation does not import/use `IncidentRepository` directly.

Incident Create displays the linked checkpoint/session context and pre-fills location when available. Back/cancel returns to Patrol. After a successful report the user can return from Incident Dashboard to Patrol, which reloads canonical state.

### Mock coherence

The real backend contract atomically changes a linked Pending checkpoint to `Issue`. Deterministic mock composition mirrors this with a mock-only callback from `MockIncidentRepository` to `MockPatrolRepository.markCheckpointIssueFromIncident`. No production repository endpoint or fake hardware proof is introduced.

### Regression additions

- mock Patrol Issue side-effect test;
- mock Incident patrol-link hook test;
- application dependency cross-module state test;
- widget flow Patrol checkpoint → Incident Create → submit → return to Patrol → Issue;
- locale-controller regression for persisted Bahasa Indonesia / English selection;
- existing Visitor, Patrol, Incident, localization and future-module regression tests remain cumulative.

## Files Changed

```text
lib/core/bootstrap/app_dependencies.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/patrol/presentation/patrol_management_screen.dart
lib/features/patrol/data/mock/mock_patrol_repository.dart
lib/features/incident/domain/models/incident_models.dart
lib/features/incident/data/mock/mock_incident_repository.dart
lib/features/incident/presentation/incident_management_screen.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/app_dependencies_test.dart
test/mock_patrol_repository_test.dart
test/mock_incident_repository_test.dart
test/widget_test.dart
test/security_locale_controller_test.dart
docs/CHECKPOINTS.md
docs/ROADMAP.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/SECURITY_MOBILE_PRD.md
docs/DESIGN_SYSTEM.md
docs/checkpoints/SEC.10_CONTEXT.md
docs/checkpoints/SEC.11_CONTEXT.md
```

## Deliberate Deferrals / HOLD

- Incident photo/video upload;
- Emergency Response dispatch;
- CCTV/NVR;
- Access Control/ANPR/barrier;
- RFID/NFC/BLE/GPS proof;
- Panic hardware/device telemetry;
- push/WhatsApp/SMS dispatch;
- Patrol scan-token exposure;
- Incident admin close/cancel/reopen/assignment.

## Backend Dependency

Canonical base remains `/api/security` with Sanctum Bearer auth. Patrol-linked Incident creation relies on the documented Incident V1 rule: when `patrol_checkpoint_visit_id` is supplied, the Patrol session must be `In Progress`, the checkpoint must be `Pending`, property is derived/validated server-side, and backend changes the checkpoint to exact status `Issue`.

## Validation Attempt 1 — 13 Aug 2026

Local gate result after the initial SEC.11 patch:

```text
flutter analyze           ✅ No issues found
flutter test              ❌ one widget regression failed
flutter build apk --debug ✅ Built app-debug.apk
```

The failing test was `Patrol checkpoint can report an Incident and return with Issue state`. The flow had already opened Patrol-linked Incident Create successfully; the failure occurred when `enterText()` targeted `incidentDescriptionField` while that lower `ListView` field was not mounted in the widget-test viewport. This is a test-viewport issue, not a Patrol/Incident repository or backend-contract failure.

Validation hotfix v1 attempted to scroll the Incident Create form before entering text. Revalidation showed `scrollUntilVisible()` could not resolve the supplied `Scrollable` finder and raised `Bad state: No element`.

## Validation Attempt 2 — 14 Aug 2026

```text
flutter analyze           ✅ No issues found
flutter test              ❌ one widget regression failed
flutter build apk --debug ✅ Built app-debug.apk
```

The same cross-module test was the sole failure. The application compiled successfully; the failure occurred inside the widget-test scrolling helper, before the description field interaction. Validation hotfix v2 now finds the Incident Create `ListView`, performs bounded upward drags until `incidentDescriptionField` is mounted, asserts the field exists, and only then calls `enterText()`. No production behavior, API contract, lifecycle, localization, or dependency changes are introduced.

## Validation Gate

Run on the actual project:

```powershell
cd E:\aparthub_security
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Do not mark SEC.11 `DONE` if any gate is red.

After automated gate green, run real backend/device smoke for Visitor + Patrol + Incident, especially Patrol → Incident and session-expiry behavior.

## Final Validation / Closure

User confirmed the SEC.11 validation-hotfix-v2 gate green on 14 Aug 2026. SEC.11 is locked `DONE`.

## Next Checkpoint

Proceed with `SEC.11A — APH.35C / APH.37 Localization Runtime Alignment`. After that, APH.37 introduces `SEC.12 — Emergency SOS Resident → Security`, followed by `SEC.13 — Final Production Readiness / Security Mobile Closure`.

## New Chat Bootstrap

```text
Continue Aparthub Security Flutter from SEC.11.

Locked cumulative baseline:
- SEC.1 through SEC.10 are DONE.
- Visitor Verification, Patrol Management, and Incident Reporting are operational/API-integrated.
- Bahasa Indonesia + English localization is green.
- Android readiness baseline is green; preserve flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, and kotlin.incremental=false.

Current checkpoint:
SEC.11 — Cross-Module Regression: Visitor + Patrol + Incident.

SEC.11 activates Patrol checkpoint → Incident reporting only when Patrol is In Progress and checkpoint is Pending. SecurityAppShell composes the navigation. Incident Create receives the authorized property context plus canonical patrol_checkpoint_visit_id. In API mode the backend owns the checkpoint transition to exact status Issue; Flutter must not call or invent a second checkpoint-Issue endpoint. Deterministic mock mode mirrors this backend side effect via a mock-only callback.

SEC.11 validation hotfix v2 is confirmed green and SEC.11 is DONE.

Next: SEC.11A aligns API localization transport with APH.35C/APH.37: Accept-Language id|en, read Content-Language, fallback en, and never branch on localized message. Then SEC.12 implements software-only Emergency SOS Resident → Security. Panic hardware/GPS/CCTV/push remain out of scope.

Normative contracts:
- docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
- docs/API_CONTRACT_SECURITY_PATROL_V1.md
- docs/API_CONTRACT_SECURITY_INCIDENT_V1.md

Do not invent Emergency/Access/Vehicle hardware APIs.
```
