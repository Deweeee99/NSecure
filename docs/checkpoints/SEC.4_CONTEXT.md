# SEC.4 Context — Visitor Detail + Check-In + Check-Out + History

## Current Status

`DONE`

Final revalidation after the SEC.4 hotfix was confirmed green by the user on 12 Aug 2026.



## Final Revalidation — GREEN

User-confirmed final gate after applying the SEC.4 validation hotfix:

```text
flutter analyze           ✅ green
flutter test              ✅ green
flutter build apk --debug ✅ green
```

SEC.4 is locked `DONE`. The next checkpoint is SEC.5.

## Local Validation Attempt 1 — RED

User validation on 12 Aug 2026 produced:

```text
flutter analyze           ❌ 2 info findings (unnecessary underscores)
flutter test              ❌ 15 passed / 4 failed
flutter build apk --debug ✅ built successfully
```

The four widget-test failures were not domain/repository failures. The action/read-only widgets lived at the tail of a lazy `ListView`, so they were not built in the test viewport when the finder executed. This also made the operational CTA less reliably visible on smaller devices.

### SEC.4 Hotfix

- Visitor Detail now uses a persistent bottom action/footer area outside the scrollable information content.
- Approved `Check-In`, Checked-In `Check-Out`, and blocked/read-only messaging are therefore always mounted and visible.
- Check-In/Check-Out confirmation actions (`Done`, `Continue Verifying`) now also use a persistent footer outside the scrollable confirmation summary.
- Analyzer findings in Verification History separator builders were corrected by using Dart wildcard `_` parameters.
- No business rule, repository transition, mock data, or backend boundary was changed.

This hotfix is intentionally aligned with the visual source of truth, where operational CTAs remain visible at the bottom of Visitor Detail and confirmation screens.

## Objective

Complete the operational Visitor Verification MVP after SEC.3 search/QR resolution.

The workflow now extends to:

```text
QR / Manual Search
        ↓
Search Results
        ↓
Visitor Detail
   ├── Approved   → Check-In → Confirmation
   ├── Checked-In → Check-Out → Confirmation
   └── Pending / Checked-Out / Expired / Rejected / Cancelled → read-only

History tab
        ↓
Verification History
        ↓
Visitor Detail
```

## Implemented in This Checkpoint

### Domain / Repository

- centralized eligibility getters:
  - `VisitorVisit.canCheckIn`
  - `VisitorVisit.canCheckOut`
- immutable `VisitorVisit.copyWith`;
- `VisitorRepository.checkIn(...)`;
- `VisitorRepository.checkOut(...)`;
- deterministic in-memory mutation in `MockVisitorRepository`;
- operational history includes Checked-In, Checked-Out, Pending, Expired;
- history refreshes after mutations.

### Visitor Detail

Displays:

- visitor identity + phone;
- Visit Code;
- Visitor ID;
- resident;
- property;
- tower;
- unit;
- purpose;
- scheduled date;
- valid window;
- current status;
- Check-In/Check-Out timestamps and officer when present.

Action matrix is status-driven and must stay aligned with `FRONTEND_SPEC.md`.

### Check-In / Check-Out

- Approved → Check-In only;
- Checked-In → Check-Out only;
- invalid state transitions rejected by repository;
- mock mutations remain asynchronous to preserve future API boundary;
- successful mutation updates shared repository state.

### Confirmation

- dedicated Check-In success surface using semantic green;
- dedicated Check-Out success surface using Aparthub primary blue;
- visitor / visit / resident-unit / time / officer summary;
- `Done`;
- `Continue Verifying`.

### Verification History

Filters:

- All;
- Checked-In;
- Checked-Out;
- Pending;
- Expired.

History rows expose visitor, visit code, resident/unit, status, and relevant activity time.

## Design Guardrail

Use the approved Visitor Verification panel as the visual source of truth and `docs/DESIGN_SYSTEM.md` as the normative implementation contract.

Do not introduce a second visual language for detail/history/confirmation screens.

## Backend Boundary

Still mock-first.

No Security API URL, HTTP client, auth transport, or speculative backend response parser is introduced here.

`SEC.7` remains blocked until the real backend contract is ready.

## Files Added / Modified

```text
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/visitor/domain/models/visitor_visit.dart
lib/features/visitor/domain/repositories/visitor_repository.dart
lib/features/visitor/data/mock/mock_visitor_repository.dart
lib/features/visitor/presentation/verification/visitor_verification_flow.dart
lib/features/visitor/presentation/detail/visitor_detail_screen.dart
lib/features/visitor/presentation/detail/visitor_action_confirmation_screen.dart
lib/features/visitor/presentation/history/verification_history_screen.dart
lib/features/visitor/presentation/history/verification_history_flow.dart
lib/features/visitor/presentation/widgets/visitor_formatters.dart
test/mock_visitor_repository_test.dart
test/widget_test.dart
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/DESIGN_SYSTEM.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/*
```

## Required Validation

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

## Done Criteria

- analyze = clean;
- all tests = pass;
- Android debug APK builds;
- Approved visitor can Check-In;
- Checked-In visitor can Check-Out;
- blocked statuses remain read-only;
- mutation appears in History;
- no API/backend claim introduced.

## Next Checkpoint After Green Gate

`SEC.5 — Coming Soon Module Presentation Screens`

SEC.5 must stay presentation-only for Patrol, Incident, Emergency, Access, and Vehicle.
