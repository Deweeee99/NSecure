# Aparthub Security Mobile API V1 — Patrol Management

> Frontend-vendored canonical Patrol contract for SEC.9. This file mirrors the backend APH.31 Patrol handoff used for implementation. The cross-module boundary is additionally governed by `API_CONTRACT_SECURITY_PLATFORM_V1.md`.

## Scope

Security Mobile executes only Patrol sessions assigned to the authenticated officer.

Mobile can:

- load Patrol dashboard counts;
- list own assigned Patrol sessions;
- load session detail/checkpoints;
- start a Scheduled session;
- mark a Pending checkpoint Completed;
- skip a Pending checkpoint with a reason;
- complete an In Progress Patrol after no Pending checkpoint remains;
- view own terminal Patrol history.

Web Admin retains route/checkpoint master, scheduling, assignment, cancellation and central monitoring.

## Base / Auth

```text
Base prefix: /api/security
Auth: Laravel Sanctum Bearer
Header: Authorization: Bearer <data.token>
```

Read requires active Security access + `security-management:read` + property/entitlement scope. Mutations additionally require `security-management:update`.

The authenticated officer can operate only own assigned sessions. Cross-officer/cross-property access fails closed as Patrol-specific 404s. Flutter does not submit `property_id` as an authorization selector.

## Exact Wire Statuses

Session:

```text
Scheduled
In Progress
Completed
Cancelled
```

Checkpoint visit:

```text
Pending
Completed
Skipped
Issue
```

## Envelope

Success:

```json
{
  "status": "success",
  "message": "Patrol loaded.",
  "data": {}
}
```

Paginated list:

```json
{
  "status": "success",
  "message": "Assigned patrols loaded.",
  "data": [],
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 0,
    "from": null,
    "to": null,
    "count": 0,
    "has_more": false,
    "sort": "scheduled_start_at_desc,id_desc"
  }
}
```

Error example:

```json
{
  "status": "error",
  "code": "PATROL_CHECKPOINTS_PENDING",
  "message": "Semua checkpoint harus diselesaikan atau di-skip sebelum patrol ditutup.",
  "errors": {},
  "data": {"pending_count": 2}
}
```

## Routes

```text
GET  /api/security/patrol/dashboard
GET  /api/security/patrol/sessions
GET  /api/security/patrol/sessions/{patrol_session_id}
POST /api/security/patrol/sessions/{patrol_session_id}/start
POST /api/security/patrol/checkpoint-visits/{visit_id}/complete
POST /api/security/patrol/checkpoint-visits/{visit_id}/skip
POST /api/security/patrol/sessions/{patrol_session_id}/complete
GET  /api/security/patrol/history
```

## Dashboard

```text
GET /api/security/patrol/dashboard
```

Canonical data:

```json
{
  "scheduled": 2,
  "in_progress": 1,
  "completed_today": 3,
  "cancelled_today": 0,
  "next_patrol": {}
}
```

`next_patrol` is nullable and uses the Patrol Session shape without requiring checkpoint detail.

## Assigned Sessions

```text
GET /api/security/patrol/sessions
```

Optional query:

```text
status=Scheduled|In Progress|Completed|Cancelled
date=YYYY-MM-DD
per_page=1..100
page=<integer>
```

Default sort:

```text
scheduled_start_at DESC, id DESC
```

List items contain `checkpoint_summary` and omit the detail `checkpoints` array.

## Patrol Session Detail

Core shape:

```json
{
  "patrol_session_id": 41,
  "session_number": "PAT-20260812-000041",
  "status": "Scheduled",
  "property": {
    "id": 1,
    "code": "SITE-A",
    "name": "Aparthub SITE-A"
  },
  "route": {
    "id": 4,
    "code": "NIGHT-A",
    "name": "Night Patrol A",
    "description": "Night perimeter patrol.",
    "expected_duration_minutes": 45
  },
  "officer": {
    "id": 12,
    "name": "Security Officer A"
  },
  "scheduled_start_at": "2026-08-12T22:00:00+07:00",
  "started_at": null,
  "completed_at": null,
  "cancelled_at": null,
  "notes": "Night shift.",
  "checkpoint_summary": {
    "total": 2,
    "pending": 2,
    "completed": 0,
    "skipped": 0,
    "issue": 0
  },
  "can_start": true,
  "can_complete": false,
  "checkpoints": []
}
```

Checkpoint shape:

```json
{
  "visit_id": 101,
  "checkpoint_id": 8,
  "code": "CP-01",
  "name": "Main Lobby",
  "location_label": "Ground Floor",
  "sequence": 1,
  "status": "Pending",
  "checked_at": null,
  "checked_by": null,
  "notes": null,
  "can_complete": true,
  "can_skip": true
}
```

`can_start`, `can_complete`, `can_skip` already combine workflow state and update permission. Flutter should consume them instead of re-creating authorization rules.

`scan_token` is intentionally absent.

## Start Patrol

```text
POST /api/security/patrol/sessions/{patrol_session_id}/start
```

No client-owned timestamp. Valid transition:

```text
Scheduled -> In Progress
```

Backend owns `started_at`.

## Complete Checkpoint

```text
POST /api/security/patrol/checkpoint-visits/{visit_id}/complete
```

Optional body:

```json
{"notes":"Area clear."}
```

Only Pending checkpoints in the authenticated officer's In Progress session can be processed. Backend owns checkpoint status, `checked_at`, and actor.

## Skip Checkpoint

```text
POST /api/security/patrol/checkpoint-visits/{visit_id}/skip
```

Required body:

```json
{"notes":"Area temporarily inaccessible."}
```

`notes` is required and max 2000 characters.

## Complete Patrol

```text
POST /api/security/patrol/sessions/{patrol_session_id}/complete
```

Optional body:

```json
{"notes":"Patrol finished."}
```

Requirements:

```text
session status = In Progress
Pending checkpoint count = 0
```

`Completed`, `Skipped`, and `Issue` checkpoints are terminal for Patrol completion purposes. Backend owns `completed_at`.

## History

```text
GET /api/security/patrol/history
```

Only terminal sessions:

```text
Completed
Cancelled
```

Optional query:

```text
status=Completed|Cancelled
per_page=1..100
page=<integer>
```

Default sort:

```text
updated_at DESC, id DESC
```

## Time Contract

```text
Application timezone: Asia/Jakarta unless deployment config changes it
Wire timestamps: ISO-8601 with timezone offset
Nullable lifecycle timestamps: JSON null
```

Flutter must not synthesize authoritative `started_at`, `checked_at`, or `completed_at`.

## Stable Error Codes

```text
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
SECURITY_PROPERTY_UNAVAILABLE
PATROL_NOT_FOUND
PATROL_ALREADY_STARTED
PATROL_ALREADY_COMPLETED
PATROL_CANCELLED
PATROL_INVALID_STATE
PATROL_NOT_IN_PROGRESS
PATROL_CHECKPOINT_NOT_FOUND
PATROL_CHECKPOINT_INVALID_STATE
PATROL_CHECKPOINT_ALREADY_PROCESSED
PATROL_CHECKPOINTS_PENDING
RESOURCE_NOT_FOUND
SERVER_ERROR
```

HTTP semantics:

```text
401 auth invalid
403 permission/property denied
404 scoped resource hidden/not found
409 workflow conflict
422 validation
500 unexpected server failure
```

## Hardware Boundary

Not defined or implied by Patrol V1:

```text
QR/NFC checkpoint scanning
RFID
BLE beacon
GPS proof
ANPR/CCTV
Dedicated scanner hardware
Device Registry
```

The database-internal `scan_token` is not a mobile contract. SEC.9 checkpoint processing is explicit authenticated mobile action only.
