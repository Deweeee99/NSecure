# Checkpoint Context Handoff

Every Aparthub Security Mobile checkpoint must maintain a dedicated context file:

```text
docs/checkpoints/SEC.<n>_CONTEXT.md
```

Purpose: allow a new ChatGPT session or developer to resume the project without reconstructing prior chat history.

## Mandatory Sections

Each checkpoint context file must include:

1. Current Status
2. Objective
3. Scope / Product Boundary
4. Implemented
5. Architecture / Flow
6. Files Added / Modified
7. Deliberate Deferrals
8. Known Limitations
9. Backend Dependency
10. Validation Evidence
11. Done Criteria
12. Next Checkpoint
13. New Chat Bootstrap

## Status Rules

Use one of these checkpoint statuses:

```text
PLANNED
ACTIVE
IMPLEMENTED — VALIDATION PENDING
HOTFIX APPLIED — REVALIDATION REQUIRED
DONE
BLOCKED
```

A checkpoint must not be marked `DONE` while any required validation gate is red.

## New Chat Bootstrap

The `New Chat Bootstrap` section must be concise and copy-ready. It should tell a new session:

- project name and frontend-only boundary;
- current checkpoint and status;
- last completed checkpoint;
- source-of-truth documents to read first;
- what has already been implemented;
- what must not be reworked;
- current blocker or validation state;
- exact next action.

When a checkpoint becomes `DONE`, update its context file with final validation evidence and point the bootstrap to the next active checkpoint.

Use `CONTEXT_TEMPLATE.md` when starting a new checkpoint.

## Patch Baseline Rule

Every new checkpoint patch must be produced from the **latest cumulative project state**, including all previously validated hotfixes. A checkpoint must never restore an older copy of a file simply because that file is also being modified for the new feature.

Before packaging a patch that touches an existing file:

1. treat all prior `DONE` checkpoints as locked regression constraints;
2. merge the new checkpoint change into the latest green version of that file;
3. preserve design-system and viewport fixes already documented;
4. run or request the full checkpoint gate after packaging;
5. if a regression is found, record the validation attempt and root cause in the active `SEC.<n>_CONTEXT.md`.

For Visitor screens specifically, the persistent operational action footer introduced and validated in SEC.4 is a locked UX/test constraint unless a later checkpoint explicitly redesigns it and updates `DESIGN_SYSTEM.md`. For Patrol, capability-driven persistent primary actions introduced in SEC.9 must likewise remain aligned with `DESIGN_SYSTEM.md` and the canonical Patrol contract.
