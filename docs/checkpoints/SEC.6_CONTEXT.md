# SEC.6 Context — API-Ready Repository Boundary + Handoff Draft

## Current Status

`DONE`

SEC.6 is locked `DONE` after user-confirmed full local Flutter revalidation.

## Objective

Harden the active Visitor Verification frontend/backend seam so a future `ApiVisitorRepository` can replace mock data without forcing a UI rewrite.

SEC.6 is architectural preparation and handoff clarification only. It is **not** Security API integration.

## Scope / Product Boundary

### In Scope

- extract concrete repository construction from `SecurityAppShell`;
- add lightweight app composition via `AppDependencies`;
- preserve constructor injection;
- make Check-In/Check-Out actor identity repository-authoritative;
- add stable repository failure codes/exceptions;
- map repository failures to presentation messages without HTTP awareness;
- strengthen `API_HANDOFF_DRAFT.md` around Visitor Verification;
- add tests for composition and stable repository errors.

### Out of Scope / Do Not Implement

- HTTP client/package integration;
- real API base URL/environment configuration;
- login/token persistence;
- `ApiVisitorRepository` before the backend contract is final;
- real QR camera scanner;
- server synchronization;
- future-module repositories or API contracts;
- broad state-management framework migration.

## Last Completed Checkpoint

`SEC.5 — Coming Soon Module Presentation Screens` is locked `DONE` after user-confirmed green analyze/test/build following hotfix v3.

Future modules remain presentation-only.

## Implemented

### 1. Composition Root

New:

```text
lib/core/bootstrap/app_dependencies.dart
```

Current runtime:

```text
AparthubSecurityApp
  ↓
AppDependencies.mock()
  ↓
MockVisitorRepository
  ↓ as VisitorRepository
SecurityAppShell
```

`SecurityAppShell` no longer imports or creates `MockVisitorRepository`.

### 2. Repository Contract Hardened

Before:

```text
checkIn(visitId, officerName)
checkOut(visitId, officerName)
```

SEC.6:

```text
checkIn(visitId)
checkOut(visitId)
```

Reason: authenticated actor and action timestamps must be authoritative repository/backend results, not trusted UI inputs.

### 3. Stable Failure Taxonomy

`VisitorRepositoryFailureCode` now defines:

```text
visitNotFound
invalidQr
expiredVisit
rejectedVisit
cancelledVisit
alreadyCheckedIn
alreadyCheckedOut
invalidState
unauthorized
forbidden
unknown
```

`VisitorRepositoryException` carries the stable code.

### 4. Mock Contract Alignment

`MockVisitorRepository` remains deterministic but now:

- owns an injected/default mock `actorName`;
- returns actor/timestamps as repository output;
- throws typed repository failures for invalid mutations.

### 5. Presentation Error Mapping

Visitor Verification and History catch the typed repository exception and use:

```text
visitor_repository_failure_message.dart
```

No widget branches on HTTP status or raw backend messages.

### 6. Handoff Draft

`docs/API_HANDOFF_DRAFT.md` now details the proposed Visitor backend requirements and explicitly identifies unresolved items required before SEC.7.

It remains:

```text
DRAFT / PROPOSED FRONTEND HANDOFF CONTRACT
NOT FINAL BACKEND CONTRACT
```

## Architecture / Flow

Current:

```text
main.dart
  ↓
AparthubSecurityApp
  ↓
AppDependencies.mock()
  ↓
VisitorRepository
  ↓
SecurityAppShell
  ├── VisitorVerificationFlow
  └── VerificationHistoryFlow
```

Future intended swap after contract approval:

```text
AppDependencies.api(...)
  ↓
ApiVisitorRepository
  ↓
SAME VisitorRepository contract
  ↓
SAME Visitor UI
```

## Files Added / Modified

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/visitor/domain/repositories/visitor_repository.dart
lib/features/visitor/data/mock/mock_visitor_repository.dart
lib/features/visitor/presentation/verification/visitor_verification_flow.dart
lib/features/visitor/presentation/history/verification_history_flow.dart
lib/features/visitor/presentation/widgets/visitor_repository_failure_message.dart
test/mock_visitor_repository_test.dart
test/app_dependencies_test.dart
docs/API_HANDOFF_DRAFT.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/SEC.5_CONTEXT.md
docs/checkpoints/SEC.6_CONTEXT.md
```

## Deliberate Deferrals

- `ApiVisitorRepository` → SEC.7 only after contract approval.
- HTTP dependency/base URL/auth transport → SEC.7.
- QR camera plugin → later integration/readiness work when requirements are confirmed.
- remote History pagination/filter execution → SEC.7 after backend schema exists.
- future module operational repositories → not part of current Visitor MVP roadmap.

## Known Limitations

- current runtime remains entirely mock-first;
- mock action timestamps are deterministic, not wall-clock/server time;
- current mock actor is supplied by mock composition;
- search/history are in-memory;
- authentication is not implemented;
- `invalidQr`, `unauthorized`, `forbidden`, and `unknown` are integration-ready failure concepts but are not all produced by current mock paths;
- backend envelope/error names remain proposed.

## Backend Dependency

SEC.7 remains blocked until backend explicitly confirms the open contract items in `docs/API_HANDOFF_DRAFT.md`.

Minimum required handoff:

```text
auth mechanism
base/version path
Visitor endpoint paths
response envelope
field casing/nullability
status wire values
error envelope/codes
timezone semantics
QR payload semantics
History pagination/filter semantics
authorization behavior
```


## Validation Attempt 1 — RED

User local validation on 12 Aug 2026:

```text
flutter analyze           ❌ 13 issues
flutter test              ❌ compile/load failure
flutter build apk --debug ✅ success
```

Observed primary diagnostics:

```text
VisitorRepositoryException isn't a type
VisitorRepositoryFailureCode undefined
error.code unavailable because matcher type degraded to Object?
unnecessary_non_null_assertion on QR test
```

Root cause is a test import omission, not an application architecture failure. `VisitorRepositoryException` and `VisitorRepositoryFailureCode` are defined in:

```text
lib/features/visitor/domain/repositories/visitor_repository.dart
```

but `test/mock_visitor_repository_test.dart` referenced them without importing that file. Once the type is unresolved, the `.having((error) => error.code, ...)` callback also loses its concrete type and creates the cascading nullable/Object diagnostics.

The QR verifier returns `Future<VisitorVisit>` in SEC.6, therefore `visit!` is obsolete and triggers the analyzer warning.

### Hotfix Applied

```text
test/mock_visitor_repository_test.dart
```

Changes:

- import `visitor_repository.dart`;
- remove obsolete `isNotNull`/`!` usage from the non-null QR verification result;
- production `lib/` behavior is unchanged.

Re-run the full gate before locking SEC.6.

## Validation Evidence

Final local revalidation confirmed by the user on 12 Aug 2026:

```text
flutter analyze           ✅ green
flutter test              ✅ green
flutter build apk --debug ✅ green
```

The earlier test-import failure is closed and retained only as historical validation evidence.

## Done Criteria

- `flutter analyze` has no issues;
- all Flutter tests pass;
- Android debug APK builds;
- existing SEC.1–SEC.5 UI workflows regress cleanly;
- `SecurityAppShell` depends only on `VisitorRepository`;
- default runtime remains mock-first;
- UI no longer supplies trusted operator identity for Check-In/Check-Out;
- invalid mock mutations expose stable repository error codes;
- API handoff remains explicitly draft and Visitor-only;
- no real backend integration is introduced.

## Next Checkpoint

`SEC.7 — Security API Integration`

Status: `BLOCKED — awaiting final backend contract`. Do not invent transport details, endpoint envelopes, authentication, or error payloads.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile (Flutter frontend only).
Current checkpoint: SEC.7 — Security API Integration.
Current status: BLOCKED — awaiting final backend Security API contract.
Last completed checkpoint: SEC.6 — API-Ready Repository Boundary + Handoff Draft (DONE, full green gate confirmed).

Read first:
1. docs/checkpoints/SEC.7_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/API_HANDOFF_DRAFT.md
5. docs/ARCHITECTURE.md
6. docs/FRONTEND_SPEC.md
7. docs/DESIGN_SYSTEM.md

Important product boundaries:
- Visitor Verification remains the only active operational MVP.
- Patrol, Incident, Emergency, Access Control, and Vehicle remain presentation-only concepts.
- Do not redesign the established Aparthub Security visual language.
- Do not implement real Security API integration from the proposed draft alone.

Already implemented through SEC.6:
- App shell, Security Home, QR/manual mock verification, Visitor Detail, Check-In, Check-Out, History, and future-module presentation screens.
- App composition owns concrete repository selection.
- SecurityAppShell depends on VisitorRepository.
- UI does not supply trusted actor identity for mutations.
- Stable typed repository failure codes exist.
- API handoff draft exists but is explicitly non-final.

Current blocker:
- No actual/final backend Security API contract has been delivered.
- Missing final auth/token scheme, base/version path, endpoint response envelopes, field casing/nullability, status wire values, machine-readable error payloads, timezone semantics, QR payload semantics, authorization behavior, and History pagination/filter semantics.

Next action:
- Obtain the real backend Security API contract or actual backend implementation/source for Visitor Verification.
- Audit it against docs/API_HANDOFF_DRAFT.md.
- Only after gaps are resolved, implement ApiVisitorRepository and transport wiring without changing the Visitor UI contract.
```
