# SEC.X Context — <Checkpoint Name>

## Current Status

`<PLANNED | ACTIVE | IMPLEMENTED — VALIDATION PENDING | HOTFIX APPLIED — REVALIDATION REQUIRED | DONE | BLOCKED>`

## Objective

<What this checkpoint is meant to achieve.>

## Scope / Product Boundary

### In Scope

- <item>

### Out of Scope / Do Not Implement

- <item>

## Implemented

- <item>

## Architecture / Flow

```text
<relevant frontend flow / dependency boundary>
```

## Files Added / Modified

```text
<paths>
```

## Regression Guard / Locked Prior Decisions

- Build from the latest cumulative green source.
- Preserve all validated UI/layout/API/runtime fixes from prior `DONE` checkpoints.
- Active vs concept modules are determined by the latest roadmap and canonical contracts, not by old design-board labels.
- Never infer hardware capability from a software-only API contract.

## Deliberate Deferrals

- <work intentionally postponed and target checkpoint>

## Known Limitations

- <limitation>

## Backend Dependency

<Exact canonical contract / unresolved backend dependency.>

## Validation Evidence

```text
flutter analyze           <status>
flutter test              <status>
flutter build apk --debug <status>
```

## Done Criteria

- <criterion>

## Next Checkpoint

`SEC.X — <name>`

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile (Flutter frontend only).
Current checkpoint: SEC.X — <name>.
Current status: <status>.
Last completed checkpoint: SEC.X.

Read first:
1. docs/checkpoints/SEC.X_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/DESIGN_SYSTEM.md
5. docs/FRONTEND_SPEC.md
6. docs/ARCHITECTURE.md
7. relevant docs/API_CONTRACT_*.md

Critical rules:
- Build every patch from the latest cumulative green state.
- Do not overwrite validated hotfixes with stale file copies.
- Respect the exact active/concept module state in ROADMAP.md.
- Map backend wire values exactly; do not manufacture backend-owned actors, timestamps, statuses, or authorization scope.
- Do not infer QR/NFC/RFID/GPS/device/hardware behavior unless a canonical contract explicitly defines it.
- Preserve the established Aparthub Security design system.

Already implemented:
- <compact summary>

Current blocker / validation state:
- <compact summary>

Next action:
- <one exact action>
```
