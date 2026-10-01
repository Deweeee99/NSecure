# SEC.10 Context — Incident Reporting API Integration

## Current Status

`HOTFIX APPLIED — REVALIDATION REQUIRED`

## Previous Locked State

```text
SEC.1–SEC.9A DONE
Visitor Verification operational + API-integrated
Patrol Management operational + API-integrated
Localization foundation ID/EN green
Android debug baseline green
```

SEC.10 is built from the latest cumulative green SEC.9A state.

## Objective

Activate Incident Reporting as the third operational software-only Security Mobile module while preserving the shared Sanctum/property authorization boundary and bilingual presentation architecture.

## Canonical Backend Inputs

```text
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/API_CONTRACT_SECURITY_INCIDENT_V1.md
```

Incident base family:

```text
/api/security/incidents
```

Routes used:

```text
GET  /incidents/dashboard
GET  /incidents
POST /incidents
GET  /incidents/history
GET  /incidents/{incidentId}
POST /incidents/{incidentId}/acknowledge
POST /incidents/{incidentId}/start
POST /incidents/{incidentId}/resolve
POST /incidents/{incidentId}/notes
```

All paths are relative to configured `SECURITY_API_BASE_URL`, which already ends in `/api/security`.

## Canonical Wire Values

Statuses remain exact internally:

```text
Open
Acknowledged
In Progress
Resolved
Closed
Cancelled
```

Severities remain exact internally:

```text
Low
Medium
High
Critical
```

ID/EN translation happens only at presentation.

## Implemented Architecture

```text
AppDependencies
├── VisitorRepository
├── PatrolRepository
└── IncidentRepository
    ├── MockIncidentRepository
    └── ApiIncidentRepository
            ↓
      SecurityApiClient
            ↓
      shared Sanctum bearer session
            ↓
      /api/security/incidents/*
```

Incident source tree:

```text
lib/features/incident/
├── domain/models/incident_models.dart
├── domain/repositories/incident_repository.dart
├── data/api/incident_api_decoder.dart
├── data/api/api_incident_repository.dart
├── data/mock/mock_incident_repository.dart
└── presentation/incident_management_screen.dart
```

## Operational UI

```text
Incident Dashboard
├── counters: open / critical / escalated / resolved today
├── active incidents
├── Report Incident
└── Incident History

Incident Detail
├── canonical status/severity
├── property / reporter / assignment / timestamps
├── escalation metadata
├── optional Patrol context
├── timeline
└── capability-driven actions
    ├── Acknowledge
    ├── Start Handling
    ├── Resolve (notes required)
    └── Add Note (notes required)
```

## Property Scope

Auth profile decoding now retains backend-documented `default_property` and `properties` values. When multiple authorized properties are present, create UI exposes a property selector. This selector is context only and cannot widen backend authorization.

Reads never send `property_id` as an authorization override.

## Server-Authoritative Fields

Flutter must not manufacture:

```text
incident_number
reported_by_user_id
reported_at
status
lifecycle timestamps
assigned_to_user_id
escalation level/timestamp
timeline actor/timestamp
```

Mutation UI reloads canonical Incident detail after lifecycle actions.

## Patrol Context

Repository create input supports:

```text
patrol_checkpoint_visit_id
```

No QR/NFC/RFID/GPS/device proof is added. Direct Patrol → Incident UX launch is deliberately deferred to SEC.11 cross-module work unless explicitly requested before then.

## Explicit HOLD / Exclusions

```text
incident photo/video upload
Emergency Response dispatch
panic-button hardware
CCTV/NVR
Access Control hardware
ANPR/LPR/barrier
RFID/NFC/BLE/GPS proof
push/WhatsApp/SMS dispatch
administrative close/cancel/reopen/assignment
```

## Files Changed / Added

Core/composition:

```text
lib/core/bootstrap/app_dependencies.dart
lib/app.dart
lib/features/security/domain/models/security_user.dart
lib/features/security/data/api/api_security_auth_repository.dart
lib/features/security/data/mock/security_home_mock_data.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
```

Incident:

```text
lib/features/incident/**
```

Localization:

```text
lib/l10n/app_en.arb
lib/l10n/app_id.arb
```

Tests:

```text
test/api_incident_repository_test.dart
test/mock_incident_repository_test.dart
test/api_security_auth_repository_test.dart
test/app_dependencies_test.dart
test/widget_test.dart
```

Docs:

```text
docs/API_CONTRACT_SECURITY_INCIDENT_V1.md
docs/postman/Aparthub_Security_Incident_V1.postman_collection.json
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/SECURITY_MOBILE_PRD.md
docs/DESIGN_SYSTEM.md
docs/checkpoints/SEC.10_CONTEXT.md
```

## Validation Gate

Run:

```powershell
cd E:\aparthub_security
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Do not lock SEC.10 `DONE` if any gate is red.

## Validation Attempt 1

Result: `RED`

Observed compiler root cause:

```text
incident_management_screen.dart imported sibling/core/domain files with one extra `../` level
→ compiler searched non-existent lib/security/... and lib/features/domain/... paths
→ Incident/Security types became unresolved
→ flutter test and flutter build failed as cascading errors
```

Validation Hotfix v1 corrects the five relative imports to:

```text
../../security/domain/models/security_user.dart
../../../core/localization/app_localizations_x.dart
../../../core/theme/security_tokens.dart
../domain/models/incident_models.dart
../domain/repositories/incident_repository.dart
```

No backend contract or business behavior changed. Full revalidation is required.

## Next Checkpoint

After SEC.10 green:

```text
SEC.11 — Cross-Module Regression: Visitor + Patrol + Incident
```

Focus SEC.11 on cross-module navigation, session-expiry consistency, localization regression, property scope, Patrol-linked Incident UX decision, Android smoke, and cumulative regression.

## New Chat Bootstrap

Copy this into a new chat if the session is lost:

```text
Continue Aparthub Security Flutter from SEC.10.

Locked cumulative baseline:
- SEC.1 through SEC.9A are DONE.
- Visitor Verification is operational/API-integrated.
- Patrol Management is operational/API-integrated.
- Bahasa Indonesia + English localization foundation is green.
- Android readiness baseline is green; preserve flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, and kotlin.incremental=false.

Current checkpoint:
SEC.10 — Incident Reporting API Integration.

SEC.10 implementation is present but validation may still be pending. Incident uses the shared /api/security Sanctum boundary and implements dashboard, active list, history, create, detail/timeline, acknowledge, start, resolve, and add note. UI actions use backend can_* flags. Exact Incident wire statuses/severities and error codes are never translated; only presentation labels are ID/EN.

Normative contracts:
- docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
- docs/API_CONTRACT_SECURITY_INCIDENT_V1.md

Explicit HOLD:
- Incident media upload
- Emergency dispatch
- CCTV/NVR
- Access Control / ANPR / RFID / NFC / GPS hardware
- push/WhatsApp/SMS
- admin close/cancel/reopen/assignment

Direct Patrol checkpoint → Incident navigation is deferred to SEC.11; repository support for patrol_checkpoint_visit_id already exists.

First inspect docs/checkpoints/SEC.10_CONTEXT.md and the latest local validation output. If analyze/test/build are green, lock SEC.10 DONE and proceed to SEC.11. If red, hotfix only from the latest cumulative state and update SEC.10_CONTEXT.md.
```

## Validation Attempt 2 + Hotfix v2

Validation after hotfix v1 progressed past the import/compiler blocker. Results:

- `flutter analyze`: 3 info-level `use_null_aware_elements` findings in `ApiIncidentRepository`;
- `flutter test`: 3 widget-test failures caused by lazy `ListView` children not being mounted in the default test viewport (`Active Incidents`, Report Incident CTA, and future-module `COMING SOON` chips);
- Android build reached Gradle assembly; the supplied log did not include the final build result.

Hotfix v2:

- uses Dart null-aware map values for nullable `q` and `location` entries without changing API payload semantics;
- makes Incident dashboard/create widget tests scroll to operational targets before asserting/tapping;
- makes the More/catalog test scroll to the future-module section before asserting `COMING SOON`;
- does not change Incident lifecycle, wire values, authorization, backend routes, localization contract, or hardware HOLD boundary.

Revalidation gate remains:

```text
flutter analyze
flutter test
flutter build apk --debug
```

SEC.10 must not be marked DONE until all three are green.


## Final Closure — GREEN

User confirmed the final SEC.10 local gate green on 13 Aug 2026. SEC.10 is locked `DONE`. The cumulative baseline now includes operational Visitor Verification, Patrol Management, Incident Reporting, and ID/EN localization. Next checkpoint: SEC.11 cross-module regression.
