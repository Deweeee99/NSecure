# SEC.9 Context — Patrol Management API Integration

## Current Status

`DONE`

## Previous Locked State

```text
SEC.1–SEC.8 DONE
Visitor Verification operational + API-integrated
Android readiness closed green
```

SEC.9 is built from the latest cumulative SEC.8 green state. No stale pre-SEC.4/SEC.8 presentation or runtime files may be restored.

## Objective

Graduate Patrol Management from the SEC.5 presentation concept into a real software-only operational module using the existing Security Sanctum session and the backend Patrol V1 contract.

## Scope / Product Boundary

### In Scope

- assigned Patrol dashboard;
- own assigned sessions;
- session detail and checkpoint list;
- start Scheduled Patrol;
- mark Pending checkpoint `Completed`;
- skip Pending checkpoint with mandatory reason;
- complete Patrol after Pending checkpoint count reaches zero;
- own terminal Patrol history;
- exact backend status/error mapping;
- loading, empty, error and retry states;
- Home/More activation of Patrol;
- mock/API repository parity and regression tests.

### Out of Scope / Do Not Implement

- Patrol route/checkpoint master CRUD;
- scheduling or assignment from mobile;
- administrative cancellation;
- central monitoring/admin operations;
- QR/NFC/RFID/BLE checkpoint scanning;
- GPS proof of presence;
- `scan_token` exposure or use;
- Incident reporting from Patrol in SEC.9;
- Emergency Response, Access Control or Vehicle backend operations.

## Canonical Backend Contract

Primary frontend references:

```text
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/API_CONTRACT_SECURITY_PATROL_V1.md
```

Base/auth:

```text
/api/security
Authorization: Bearer <Sanctum token>
```

Exact session wire values:

```text
Scheduled
In Progress
Completed
Cancelled
```

Exact checkpoint wire values:

```text
Pending
Completed
Skipped
Issue
```

Routes:

```text
GET  /patrol/dashboard
GET  /patrol/sessions
GET  /patrol/sessions/{patrolSession}
POST /patrol/sessions/{patrolSession}/start
POST /patrol/sessions/{patrolSession}/complete
POST /patrol/checkpoint-visits/{visit}/complete
POST /patrol/checkpoint-visits/{visit}/skip
GET  /patrol/history
```

Paths above are relative to `/api/security`.

## Postman Handoff Caveat

The backend combined Postman artifact is preserved under:

```text
docs/postman/Aparthub_Security_Mobile_V1.postman_collection.json
```

Its Patrol requests contain duplicated `/api/security` path segments even though `base_url` already ends in `/api/security`. The canonical Markdown contract wins. Flutter SEC.9 uses `/patrol/*` relative paths and does not reproduce the Postman packaging defect.

## Implemented Architecture

```text
AppDependencies
├── VisitorRepository
└── PatrolRepository
     ├── MockPatrolRepository
     └── ApiPatrolRepository
          ↓
       SecurityApiClient
          ↓
       same Sanctum Bearer session
```

Presentation remains transport-agnostic:

```text
Security Home / More
        ↓
PatrolManagementScreen
        ↓
PatrolRepository
        ↓
Mock or API
```

## Mutation Strategy

Backend remains authoritative for Patrol lifecycle state and timestamps.

SEC.9 performs the mutation request and then reloads the Patrol detail through `GET /patrol/sessions/{id}`. This avoids depending on any undocumented mutation response shortcut and ensures the screen renders canonical persisted state.

Flutter does not manufacture:

```text
started_at
checked_at
completed_at
checked_by
session/checkpoint status
property authorization
```

## Implemented UX

### Dashboard

- Scheduled / In Progress / Done Today metrics;
- active/next Patrol card;
- assigned Patrol list;
- pull-to-refresh;
- History entry point.

### Patrol Detail

- route/session/property/officer/schedule/duration;
- progress bar and checkpoint counters;
- checkpoint cards with exact statuses;
- backend capability-driven checkpoint actions;
- persistent `Start Patrol` or `Complete Patrol` footer where applicable.

### Checkpoint Actions

- `Mark Complete` for `can_complete=true`;
- `Skip` for `can_skip=true`;
- skip reason required, max 2000 characters;
- no scanner/hardware affordance is implied.

### History

- terminal assigned sessions only;
- All / Completed / Cancelled filters;
- detail remains available from History.

## Files Added / Modified

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/features/patrol/domain/models/patrol_models.dart
lib/features/patrol/domain/repositories/patrol_repository.dart
lib/features/patrol/data/api/patrol_api_decoder.dart
lib/features/patrol/data/api/api_patrol_repository.dart
lib/features/patrol/data/mock/mock_patrol_repository.dart
lib/features/patrol/presentation/patrol_management_screen.dart
lib/features/security/data/mock/security_home_mock_data.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
lib/features/security/presentation/concepts/security_module_concept_router.dart
lib/features/security/presentation/concepts/patrol_management_concept_screen.dart
test/api_patrol_repository_test.dart
test/mock_patrol_repository_test.dart
test/app_dependencies_test.dart
test/widget_test.dart
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/API_CONTRACT_SECURITY_PATROL_V1.md
docs/postman/Aparthub_Security_Mobile_V1.postman_collection.json
docs/SECURITY_MOBILE_PRD.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/DESIGN_SYSTEM.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/CONTEXT_TEMPLATE.md
docs/checkpoints/README.md
docs/checkpoints/SEC.8_CONTEXT.md
docs/checkpoints/SEC.9_CONTEXT.md
```

## Regression Guard / Locked Prior Decisions

- Visitor Verification behavior remains unchanged.
- SEC.4 persistent Visitor footer patterns remain locked.
- SEC.8 secure session / scanner / Android fixes remain locked.
- Patrol uses the same Security bearer session; no second auth subsystem.
- mobile cannot widen property/officer authorization.
- backend `can_*` flags are authoritative UI capabilities.
- `scan_token` is never used.
- Incident remains presentation-only in Flutter until SEC.10 even though backend platform handoff includes it.

## Validation Evidence

### Validation Attempt 1 — RED

Local gate after the initial SEC.9 patch:

```text
flutter analyze           ❌ 1 compile-time analyzer error
flutter test              ❌ 2 failures / load failure caused by the same compile error + mock async-validation mismatch
flutter build apk --debug ❌ blocked by the same Dart compile error
```

Observed defects:

1. `_PatrolScaffold.footer` is a public nullable field. Dart cannot promote a public field after `footer != null`, so a `Widget?` was inserted into `List<Widget>`.
2. `MockPatrolRepository.skipCheckpoint()` validated `reason` before entering an `async` boundary. The validation exception was thrown synchronously, while the repository contract/test expects a failed `Future`.

### SEC.9 Validation Hotfix v1

Applied corrections:

- capture `this.footer` into a local final variable before null checking, enabling sound null promotion;
- make `MockPatrolRepository.skipCheckpoint()` `async` so validation errors follow the asynchronous repository contract;
- no backend contract, UI flow, or Patrol lifecycle semantics changed.

### Validation Attempt 2 — PARTIAL GREEN / RED

Local gate after SEC.9 Validation Hotfix v1:

```text
flutter analyze           ❌ 1 info (`use_null_aware_elements`)
flutter test              ❌ 1 widget regression assertion
flutter build apk --debug ✅ built successfully
```

Observed defects:

1. Dart 3.12 lint prefers a null-aware collection element (`?footer`) instead of an explicit `if (footer != null)` collection element.
2. `Route Checkpoints` is below the Patrol detail summary inside a lazy `ListView`. The production UI is valid, but the widget test asserted the text before scrolling it into the mounted viewport.

### SEC.9 Validation Hotfix v2

Applied corrections:

- replace the explicit nullable footer `if` element with Dart null-aware collection element `?footer`;
- keep the persistent footer behavior unchanged;
- update the Patrol operational widget test to `scrollUntilVisible` before asserting `Route Checkpoints` and the first checkpoint;
- no backend contract, repository lifecycle, Patrol UI behavior, or SEC.8 Android baseline changed.

### Final Revalidation — GREEN

User-confirmed local gate after Validation Hotfix v2:

```text
flutter analyze           ✅ No issues found
flutter test              ✅ 61 tests passed
flutter build apk --debug ✅ Built app-debug.apk
```

SEC.9 is locked `DONE`.

## Done Criteria

- `flutter analyze` has no issues;
- all tests pass;
- debug APK builds;
- Visitor regression remains green;
- Home/More route Patrol to operational UI;
- mock mode remains deterministic;
- no Patrol hardware/scanner contract is invented.

## Localization Decision

Aparthub is now explicitly dual-language:

```text
Bahasa Indonesia
English
```

Localization is scheduled as `SEC.9A — Localization Foundation ID / EN` immediately after SEC.9 is green and before Incident implementation. API/wire values remain canonical English backend values; only presentation strings are localized.

## Next Checkpoint

`SEC.9A — Localization Foundation ID / EN`

SEC.9A may now proceed from this locked cumulative green baseline. SEC.10 Incident will then be implemented on top of the bilingual foundation.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile (Flutter frontend only).
Last completed checkpoint: SEC.9 — Patrol Management API Integration.
Status: DONE / LOCKED GREEN.
SEC.1–SEC.9 are locked green.

Read first:
1. docs/checkpoints/SEC.9_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
5. docs/API_CONTRACT_SECURITY_PATROL_V1.md
6. docs/ARCHITECTURE.md
7. docs/FRONTEND_SPEC.md
8. docs/DESIGN_SYSTEM.md

SEC.9 implementation already exists:
- PatrolRepository + MockPatrolRepository + ApiPatrolRepository.
- same Security Sanctum bearer session as Visitor.
- Patrol dashboard, assigned list, detail, start, complete/skip checkpoint, complete Patrol, history.
- Home + More mark Visitor and Patrol ACTIVE.
- backend can_start/can_complete/can_skip drive available actions.
- mutation is followed by canonical Patrol detail reload.

Hard boundaries:
- Build from latest cumulative green source.
- Do not regress SEC.4 Visitor footers or SEC.8 Android/session/scanner fixes.
- Patrol is assigned execution only; web owns master/schedule/assignment/cancellation.
- Do NOT add QR/NFC/RFID/BLE/GPS proof and never use scan_token.
- Incident remains presentation-only until SEC.10.
- Aparthub mobile is dual-language: Bahasa Indonesia + English; SEC.9A establishes localization before Incident implementation.
- Canonical Markdown Patrol contract wins over duplicated /api/security paths in the combined Postman handoff.

Next action:
Proceed with SEC.9A Localization Foundation — Bahasa Indonesia + English from the locked SEC.9 cumulative green baseline. After SEC.9A is green, continue SEC.10 Incident Reporting API Integration.
```
