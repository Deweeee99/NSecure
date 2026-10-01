# SEC.5 Context — Coming Soon Module Presentation Screens

## Current Status

`DONE`

Final user-confirmed revalidation is green. SEC.5 is locked and must not be reopened without a real regression or requirement change.

## Objective

Implement the approved Future Operational Modules board as high-fidelity Flutter presentation concepts while keeping Visitor Verification as the only active operational MVP.

Required concepts:

```text
Patrol Management
Patrol Route / Checkpoints
Incident Reporting
Incident Detail
Emergency Response
Access Control
Vehicle Management
```

## Product Boundary

SEC.5 is deliberately presentation-only.

Allowed:

- realistic enterprise layouts;
- deterministic static example data;
- safe navigation between concept views;
- Coming Soon / concept notices;
- disabled future operational actions.

Not allowed:

- backend/API integration;
- fake production submission success;
- persistent patrol state;
- incident submission;
- SOS escalation or phone dialing;
- door/access hardware control;
- vehicle gate/parking automation;
- final API contracts for future modules.

## Implemented

### Navigation

Security Home future-module cards now open concept screens.

The root bottom navigation remains:

```text
Home / Verify / History / More
```

`More` now acts as a platform module catalog and preserves Active vs Coming Soon semantics.

### Patrol

Dashboard concept:

- Assigned Patrol;
- Tower A — Night Patrol;
- officer, timing, duration;
- 65% visual progress;
- completed/remaining checkpoints;
- next checkpoint;
- route summary.

Route concept:

- five checkpoints;
- Checked vs Pending visual states;
- completed timestamps;
- future Check-In action visibly disabled.

### Incident

Reporting concept:

- incident type presentation;
- location;
- description;
- evidence area;
- future Submit Report action disabled.

Detail concept:

- example incident metadata;
- description;
- static evidence preview;
- clearly labeled as example design data.

### Emergency

- emergency red semantic region;
- SOS visual control;
- contacts list;
- explicit concept-only warning;
- no action side effects.

### Access Control

- Residents / Visitors / Vendors tab treatment;
- search presentation;
- example access-status cards;
- Active / Inactive semantic locks;
- no door/hardware command.

### Vehicle Management

- plate search presentation;
- registered vehicle summary;
- resident/unit/access state;
- recent vehicle access example;
- no gate/hardware command.

## Architecture

Future-module concept views stay entirely in the presentation layer:

```text
Security Home / Module Catalog
            ↓
SecurityModuleConceptRouter
            ↓
Static concept screens
```

No repository is created for future modules because there is no active domain/backend contract yet.

This is intentional and prevents fake business logic from becoming accidental architecture.

## Design Guardrail

Use:

```text
approved Future Operational Modules panel
        ↓
docs/DESIGN_SYSTEM.md
        ↓
shared Security tokens/theme
        ↓
concept widgets/screens
```

All modules remain part of the same Aparthub Security application visual system.

Emergency red is semantic only and must not become a separate theme.

## Files Added / Modified

```text
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/features/security/presentation/concepts/security_module_concept_router.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
lib/features/security/presentation/concepts/patrol_management_concept_screen.dart
lib/features/security/presentation/concepts/incident_reporting_concept_screen.dart
lib/features/security/presentation/concepts/emergency_response_concept_screen.dart
lib/features/security/presentation/concepts/access_control_concept_screen.dart
lib/features/security/presentation/concepts/vehicle_management_concept_screen.dart
lib/features/security/presentation/concepts/widgets/concept_widgets.dart
test/widget_test.dart
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/DESIGN_SYSTEM.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/SEC.4_CONTEXT.md
docs/checkpoints/SEC.5_CONTEXT.md
```


## Validation Attempt 1 — 12 Aug 2026

Local validation did not pass the full gate:

```text
flutter analyze           ❌ 1 info: use_null_aware_elements
flutter test              ❌ 2 widget tests failed
flutter build apk --debug ✅ built successfully
```

Findings:

1. `ConceptSectionTitle` used an explicit null check for the optional trailing widget and triggered `use_null_aware_elements`.
2. The Patrol Route concept CTA was at the bottom of lazy scroll content and sat outside the default widget-test viewport, so `tap()` missed it.
3. `Recent Vehicle Access` is valid scrollable content but was not mounted in the default test viewport when the assertion ran.

Hotfix:

- remove the explicit trailing null-check by rendering `trailing ?? SizedBox.shrink()`;
- add an optional persistent footer slot to `ConceptPageBody`;
- move `View Patrol Route Concept` into the persistent concept footer;
- make the widget test explicitly scroll to the Vehicle recent-access section before asserting it;
- document the concept drill-down footer pattern in `DESIGN_SYSTEM.md`.

This does not activate any future operational capability. Patrol checkpoint Check-In and all other future operational actions remain disabled/non-operational.


## Validation Attempt 2 — 12 Aug 2026

After applying the first SEC.5 hotfix, local validation improved but the full gate was still not green:

```text
flutter analyze           ✅ No issues found
flutter test              ❌ 1 widget test failed
flutter build apk --debug ✅ built successfully
```

Remaining failure:

- `Emergency Access and Vehicle modules render concept screens` failed inside `scrollUntilVisible()` with `Bad state: No element`.
- The target text `Recent Vehicle Access` lives in a lazy `ListView` item that has not been mounted yet. `scrollUntilVisible()` needs a mounted target finder, so it is the wrong primitive for this lazy-content case.

Hotfix v3:

- replace `scrollUntilVisible()` with a direct drag on the active `ListView`;
- pump until settled;
- assert `Recent Vehicle Access` only after the lower list content has been mounted.

This is a test-harness correction only. No product behavior, future-module capability, backend boundary, or design-system rule changes.

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
- future module cards open concept screens;
- Patrol route concept is reachable;
- Incident detail concept is reachable;
- future operational actions do not mutate state;
- concept warnings remain visible;
- Visitor Verification remains the only active MVP;
- no speculative backend contract is introduced.

## Backend Dependency

No future-module backend dependency is resolved in SEC.5.

`SEC.7` remains blocked until the real Security API contract is ready.

## Next Checkpoint After Green Gate

`SEC.6 — API-Ready Repository Boundary + Handoff Draft`

SEC.6 should focus on Visitor Verification frontend/backend seam hardening and handoff readiness, not real API integration.

## Validation Attempt 3 — Final Lock

User confirmed the full SEC.5 gate is green after hotfix v3:

```text
flutter analyze           ✅ green
flutter test              ✅ green
flutter build apk --debug ✅ green
```

SEC.5 is therefore locked `DONE`.

## Handoff Update

The next active checkpoint is `SEC.6 — API-Ready Repository Boundary + Handoff Draft`. Use `docs/checkpoints/SEC.6_CONTEXT.md` as the current recovery file once the SEC.6 patch is applied.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile (Flutter frontend only).
Current checkpoint: SEC.6 — API-Ready Repository Boundary + Handoff Draft.
Current status: SEC.5 DONE; SEC.6 should be read from docs/checkpoints/SEC.6_CONTEXT.md.
Last completed checkpoint: SEC.5 — Coming Soon Module Presentation Screens.

Read first:
1. docs/checkpoints/SEC.6_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/API_HANDOFF_DRAFT.md
5. docs/ARCHITECTURE.md
6. docs/FRONTEND_SPEC.md
7. docs/DESIGN_SYSTEM.md

Locked SEC.5 facts:
- Full analyze/test/build gate is green.
- Future modules are presentation-only concepts.
- Patrol route and Incident detail concept navigation are implemented.
- Future operational actions remain disabled/non-mutating.

Next action:
- Continue from SEC.6_CONTEXT.md. Do not reopen SEC.5 unless a real regression is found.
```
