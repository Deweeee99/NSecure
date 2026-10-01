# Aparthub Security Mobile — Architecture

> **Status: ACTIVE ARCHITECTURE BASELINE**  
> This document governs frontend code structure and dependency direction for the Flutter application. Keep it lightweight. Do not introduce additional architectural layers unless a real product requirement justifies them.

## 1. Architecture Goal

Aparthub Security Mobile must remain:

- deterministic mock-capable for tests/demo while production modules use explicit canonical Security API contracts;
- API-ready without coupling UI directly to HTTP;
- easy to extend checkpoint by checkpoint;
- easy to test with deterministic repositories;
- consistent with the approved Security design panels;
- intentionally simple enough for a small mobile codebase.

Target dependency direction:

```text
Application composition
        ↓
Presentation / UI
        ↓
Domain models + repository contracts
        ↓
Repository implementation
        ↓
Mock source / HTTP source
```

The presentation layer must not know whether Visitor, Patrol, Incident, Emergency, or Package data comes from deterministic memory repositories or the remote Security API.

## 2. Runtime Composition — SEC.16

Current composition supports two explicit modes:

```text
No SECURITY_API_BASE_URL in debug/test
  → AppDependencies.mock()
  ├── MockVisitorRepository
  ├── MockPatrolRepository
  ├── MockIncidentRepository
  ├── MockEmergencyAlertRepository
  └── MockSecurityPackageRepository

SECURITY_API_BASE_URL configured
  → AppDependencies.api(...)
  → IoSecurityApiClient
  ├── ApiSecurityAuthRepository
  ├── ApiVisitorRepository
  ├── ApiPatrolRepository
  ├── ApiIncidentRepository
  ├── ApiEmergencyAlertRepository
  └── ApiSecurityPackageRepository
  → SecurityAuthGate
  → Visitor + Patrol + Incident + Emergency + Package operational UI
```

Widgets remain HTTP-agnostic. API mode is activated with `--dart-define=SECURITY_API_BASE_URL=https://<host>/api/security`. The app intentionally has no guessed production host.

The screen hierarchy should not need redesign solely because the repository implementation changes.

## 3. Composition Root

`lib/core/bootstrap/app_dependencies.dart` is the lightweight application composition root.

Current responsibility:

```text
choose concrete Auth, Visitor, Patrol, Incident, Emergency, and Package repository implementations
```

It is not a service locator and does not expose global mutable state.

Rules:

- constructor injection remains the default dependency mechanism;
- do not resolve dependencies from inside feature widgets;
- do not add GetIt/Riverpod/Provider/Bloc solely for dependency injection;
- API-specific construction belongs at the composition boundary, not in screens.

## 4. Folder Structure

Current relevant structure:

```text
lib/
├── main.dart
├── app.dart
├── core/
│   ├── bootstrap/
│   │   └── app_dependencies.dart
│   └── theme/
│       ├── security_tokens.dart
│       └── security_theme.dart
└── features/
    ├── security/
    │   ├── data/mock/
    │   ├── domain/models/
    │   └── presentation/
    ├── visitor/
    │   ├── data/{api,mock}/
    │   ├── domain/{models,repositories}/
    │   └── presentation/{detail,history,verification,widgets}/
    ├── patrol/
    │   ├── data/{api,mock}/
    │   ├── domain/{models,repositories}/
    │   └── presentation/
    └── incident/
        ├── data/{api,mock}/
        ├── domain/{models,repositories}/
        └── presentation/
```

API/runtime files currently live under:

```text
core/network/
core/session/
features/security/data/api/
features/security/domain/repositories/
features/security/presentation/auth/
features/visitor/data/api/
features/patrol/data/api/
features/incident/data/api/
```

The Security API transport remains a small `dart:io` client. SEC.8 adds a `SecuritySessionStore` boundary backed by platform secure storage for the Sanctum bearer token, plus finite request timeout and release URL hardening. Passwords are never persisted.

## 5. Layer Responsibilities

### 5.1 Application Composition

Owns:

- selecting mock vs API repositories;
- constructing repository dependencies;
- passing contracts into the application shell.

Must not own:

- screen state;
- Visitor/Patrol/Incident business rules;
- UI copy;
- HTTP response parsing itself.

### 5.2 Presentation

Owns:

- screens and widgets;
- navigation intent;
- transient UI state;
- loading/empty/error presentation;
- mapping stable repository failures into user-facing copy.

Must not own:

- HTTP calls;
- endpoint strings;
- bearer tokens;
- raw backend error handling;
- authoritative operator identity;
- authoritative action timestamps;
- duplicated mock datasets.

### 5.3 Domain

Owns stable frontend concepts:

```text
SecurityUser
ModulePreview
VisitorVisit
VisitorStatus
VisitorRepository
PatrolSession
PatrolCheckpointVisit
PatrolRepository
IncidentRecord
IncidentStatus
IncidentSeverity
IncidentRepository
stable repository failure codes/exceptions
```

Domain naming should survive a transport swap.

### 5.4 Data

Owns concrete repository behavior and source-specific translation.

Current concrete data sources:

```text
MockVisitorRepository
ApiVisitorRepository
MockPatrolRepository
ApiPatrolRepository
```

The future API repository must translate:

```text
HTTP + backend JSON
        ↓
transport DTO/parser
        ↓
VisitorVisit / VisitorRepositoryException
```

Raw JSON maps and HTTP status codes must not leak into widgets.

## 6. Visitor Repository Contract

SEC.7 preserves the repository seam while adding the backend-proven Check-In capability gap:

```dart
abstract interface class VisitorRepository {
  Future<List<VisitorVisit>> search(String query);
  Future<VisitorVisit> verifyQrPayload(String qrPayload);
  Future<VisitorVisit?> findByVisitId(String visitId);
  Future<VisitorVisit> checkIn(
    String visitId, {
    VisitorVerificationMethod method = VisitorVerificationMethod.manual,
    String? qrPayload,
  });
  Future<VisitorVisit> checkOut(String visitId);
  Future<List<VisitorVisit>> history();
}
```

The verification method is required by the final backend contract: manual Check-In sends `verification_method=manual`; QR Check-In sends `verification_method=qr` plus the exact opaque credential. Actor identity and timestamps remain backend-authoritative.

The API never returns the QR/access credential inside Visitor payloads. `VisitorVisit.qrPayload` is therefore optional and remains mock/demo-only.

## 7. Repository Error Boundary

Stable frontend codes:

```text
visitNotFound
invalidQr
expiredVisit
notValidToday
pendingApproval
rejectedVisit
cancelledVisit
alreadyCheckedIn
alreadyCheckedOut
invalidState
validation
unauthorized
forbidden
unknown
```

Rules:

- mock repository throws `VisitorRepositoryException` for invalid mutations;
- future API repository maps backend/HTTP errors into the same exception type;
- UI catches the stable exception, not `StateError`, socket errors, HTTP status codes, or raw JSON messages;
- backend diagnostic text may be logged later, but must not become the UI contract.

## 8. State Management Rule

Current rule: **prefer local Flutter state until complexity proves otherwise**.

Use:

- `StatelessWidget` for pure presentation;
- `StatefulWidget` for local workflows;
- constructor injection for repository/callback dependencies;
- `IndexedStack` for persistent bottom navigation.

Consider broader state management only when real API/auth/cache requirements justify it.

## 9. Navigation Architecture

Root navigation:

```text
Home
Verify
History
More
```

Visitor Verification and History have internal state-driven stages. Future modules remain presentation-only concept routes until their product scope is activated.

## 10. Mock-First Rules

Mock mode must be:

- deterministic;
- testable;
- free from fake network delays unless a UX test specifically needs one;
- semantically compatible with the repository contract;
- replaceable at the composition root.

Do not hide mock/API branching inside individual widgets.

## 11. API Integration Entry Criteria

SEC.7 must not begin until backend handoff resolves the items marked open in `docs/API_HANDOFF_DRAFT.md`, including:

- auth mechanism;
- base path/versioning;
- exact response envelope;
- field casing/nullability;
- status values;
- machine-readable error codes;
- QR verification semantics;
- date/time timezone contract;
- History pagination/filter semantics.

## 12. Testing Strategy

Minimum categories:

```text
repository behavior tests
repository failure-code tests
application composition test
widget workflow tests
full analyze/test/build gate
```

When `ApiVisitorRepository` exists, add contract/parser tests using deterministic fixtures before switching runtime composition away from mock.

## 13. Anti-Patterns

Do not introduce:

```text
Widget → http.get(...)
Widget → endpoint string
Widget → raw Map<String, dynamic>
Widget → hardcoded authenticated officer identity for mutation
Widget → DateTime.now() as authoritative backend action time
SecurityAppShell → new concrete repository
backend message text → business branching
```

## 14. Change Control

Any future architectural change that modifies dependency direction, runtime composition, repository contract, or state-management strategy must update:

```text
docs/ARCHITECTURE.md
docs/CHECKPOINTS.md
docs/checkpoints/SEC.<n>_CONTEXT.md
```


## SEC.8 Android Runtime Boundary

Final active-MVP composition:

```text
AparthubSecurityApp
↓
AppDependencies
├── mock mode (non-release, no base URL)
│   ├── MockVisitorRepository
│   └── deterministic QR demo
│
└── API mode
    ├── IoSecurityApiClient
    ├── ApiSecurityAuthRepository
    │   └── SecuritySessionStore
    │       └── FlutterSecureSecuritySessionStore
    ├── ApiVisitorRepository
    └── device QR scanner
```

Release builds are fail-closed: they must receive `SECURITY_API_BASE_URL`, and the URL must use HTTPS. Mock fallback is a development/test capability, not a production fallback.

The camera scanner is presentation/input infrastructure only. It must not decode domain meaning locally. Its sole output is the raw QR string passed unchanged into `VisitorRepository.verifyQrPayload()`.

Repository `unauthorized` failures are session-boundary events. In authenticated API mode they route back through logout/session cleanup instead of leaving stale operational screens active.


## SEC.9 Patrol Repository Boundary

Patrol uses the same dependency direction as Visitor:

```text
PatrolManagementScreen
        ↓
PatrolRepository
   ├── MockPatrolRepository
   └── ApiPatrolRepository
             ↓
      SecurityApiClient
             ↓
        /api/security/patrol/*
```

The API repository owns wire decoding, pagination and stable backend-error translation. Widgets never consume raw JSON or HTTP status codes.

Mutation rule:

```text
POST lifecycle action
        ↓
GET canonical Patrol detail
        ↓
replace UI state with persisted backend representation
```

This deliberately keeps `started_at`, `checked_at`, `completed_at`, actor identity, workflow status and authorization server-authoritative.

Patrol must never create a second authentication/session client; it shares the same `SecurityApiClient` bearer token owned by the existing Security auth boundary.

The current Patrol domain contract is explicit action-based checkpoint processing only. `scan_token`, QR/NFC/RFID/BLE/GPS proof, and hardware abstractions do not belong in the frontend architecture until a later canonical contract defines them.

## SEC.9A Localization Architecture

Localization is a presentation-layer concern. `AppLocalizations` is generated from `lib/l10n/app_en.arb` and `lib/l10n/app_id.arb`; `SecurityLocaleController` owns the selected locale and persists only the language code. Repository, decoder, and domain model layers continue to use canonical backend wire values.

```text
Backend JSON / exact wire values
        ↓
Repository + domain models (untranslated)
        ↓
Presentation mapping
        ↓
AppLocalizations (id / en)
```

Locale preference failure must not block authentication or Security operational workflows.



## SEC.11 Cross-Module Composition

Patrol → Incident is composed at `SecurityAppShell`, not by coupling Patrol presentation directly to Incident repositories. Patrol emits a report-incident navigation intent containing the current session/checkpoint. The shell creates an `IncidentCreateContext` and opens Incident Create.

```text
PatrolManagementScreen
  → navigation intent(session, checkpoint)
SecurityAppShell
  → IncidentCreateContext
IncidentManagementScreen
  → IncidentRepository.createIncident(...)
```

API mode sends the documented `patrol_checkpoint_visit_id`; the backend transaction owns the resulting Patrol checkpoint `Issue` state. Mock composition wires a mock-only side-effect callback between the in-memory Incident and Patrol repositories so deterministic demo/regression state mirrors the backend behavior without widening the production repository contract.

## SEC.11A API Localization Transport

APH.35C makes localization a transport concern in addition to the existing presentation resources. The shared `IoSecurityApiClient` now owns a narrow localization seam while repositories/domain models remain locale-agnostic.

```text
SecurityLocaleController
  effectiveLanguageCode (id|en, fallback en)
        ↓
AppDependencies.setApiLanguageCode(...)
        ↓
IoSecurityApiClient
  Accept-Language: id|en
        ↓
Security API
  Content-Language: id|en
```

`Content-Language` is read as response metadata only. It must never rewrite a domain status, stable error code, ID, token, permission slug or field name. Backend `message` remains human-readable display/helper copy; repository branching stays on canonical `code` / status fields.

SEC.12 Emergency SOS and SEC.13 Package Receiving reuse the same localization seam and shared Sanctum Security session.

## SEC.12 Emergency SOS Runtime

Emergency SOS is a software-only operational module. `EmergencyAlertRepository` shares the same Security API client and Sanctum session as Visitor, Patrol, and Incident. `SecurityAppShell` owns foreground modal coordination because `/emergency-alerts/active` must be checked independent of the currently visible module. API mode polls every 15 seconds while foreground and refreshes on shell creation/login, resume, and mutations. The modal is backend-state-driven; local dismissal is not a state transition.

Hardware/push concerns remain outside this boundary.


## SEC.13 Package Receiving Boundary

Package Receiving follows the existing repository dependency direction:

```text
PackageManagementScreen
  → SecurityPackageRepository
      ├── MockSecurityPackageRepository
      └── ApiSecurityPackageRepository
          → shared SecurityApiClient
```

The frontend domain represents package records and Resident/Unit lookup context only. Persistence remains the backend's existing `resident_packages` Package Center domain. The API repository sends only documented client-owned receive/collect fields and maps `PACKAGE_*` machine codes to stable repository failures. Canonical package status parsing fails closed on unknown wire values.


## SEC.14 Production Composition Guardrails (Cumulative)

`AppDependencies.fromEnvironment()` delegates to a testable `fromRuntimeConfig(...)` boundary. Debug/test may use deterministic mock composition when no API base is supplied. Release may not: an empty release API base throws, the configured URL must end with exact `/api/security`, and release requires HTTPS. This prevents accidental mock/demo runtime from being shipped as a production Security build.

The existing `IoSecurityApiClient` remains the single HTTP/localization bearer-token seam for every operational module. SEC.14 does not add a second client, service locator, or module-specific auth stack.


## SEC.15 APH.42 Patrol Photo Evidence Boundary

APH.42 extends the existing Patrol domain/repository boundary rather than creating a new feature stack:

```text
PatrolManagementScreen
  → PatrolRepository
      → ApiPatrolRepository
          → shared SecurityApiClient
          → SecurityMultipartApiClient capability for photo mutations
```

`IoSecurityApiClient` implements both the existing JSON API seam and the narrow multipart capability. `ApiPatrolRepository` checks/casts that capability only when Complete or photo-assisted Skip requires multipart. No second HTTP client, auth token store, locale negotiation path, or Patrol endpoint family is introduced.

Photo files are local transient inputs represented by `PatrolPhotoInput`; backend photo proof is represented by `PatrolCheckpointPhotoEvidence`. The domain never stores an internal backend path. `photo_evidence.url` is treated as an expiring presentation link and refreshed through the canonical Patrol Detail call.

Mutation safety remains backend-authoritative. The repository does not automatically replay Complete/Skip after network ambiguity because the backend may already have processed the `visit_id`.

## SEC.16 Final Revalidation Boundary

SEC.16 changes no production dependency direction. It verifies that the cumulative release composition from SEC.14 still uses the shared API/localization client and that the same concrete client provides APH.42 multipart transport. Production closure therefore validates the architecture after the new Patrol capability instead of reopening product scope.
