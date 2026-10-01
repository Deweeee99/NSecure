# APARTHUB SECURITY API — FULL FRONTEND / MOBILE HANDOFF

**Handoff date:** 20 August 2026  
**Contract basis:** Fresh source snapshot `aparthub-api-handoff-current.zip` supplied on 20 August 2026.  
**Contract authority:** Current source code > current routes > tests > maintained documentation.  
**Intended consumer:** Aparthub Security Flutter/mobile client and integration testers.  
**API family:** `/api/security/*` plus one signed patrol-photo route under `/api/files/*`.

> This document describes the API that exists in the supplied source. It does not invent hardware, GPS, QR checkpoint scanning, shift, badge, device registry, or other deferred capabilities.

---

## 1. Deployment Base URL

The source establishes the `/api` route paths. The currently known Aparthub deployment context is:

```text
Application : https://airaai.my.id/admin
API base    : https://airaai.my.id/admin/api
Security    : https://airaai.my.id/admin/api/security
```

The host/subpath above comes from the current deployment context; `.env` is intentionally not included in the source snapshot.

Examples:

```text
POST https://airaai.my.id/admin/api/security/login
GET  https://airaai.my.id/admin/api/security/me
GET  https://airaai.my.id/admin/api/security/patrol/sessions
```

---

## 2. Common Request Headers

Protected Security endpoints use Laravel Sanctum.

```http
Authorization: Bearer <token>
Accept: application/json
Accept-Language: id
```

Supported API locales:

```text
id
en
```

Regional values are normalized:

```text
id-ID → id
en-US → en
```

If `Accept-Language` is absent or unsupported, API locale falls back to `API_LOCALE`, source default `en`.

Every API response is given:

```http
Content-Language: id
```

or:

```http
Content-Language: en
```

For multipart endpoints, allow the HTTP client to generate the `Content-Type: multipart/form-data; boundary=...` header.

---

## 3. Security Identity and Authorization Model

Security Mobile does **not** authenticate against a separate employee table. `users` remains the canonical authentication identity.

```text
users
  │
  ├── property_user
  │     property membership
  │
  ├── user_modules
  │     security-management read/create/update/delete permission
  │
  └── security_personnel
        active operational roster membership per property
```

A property becomes an accessible Security property only when all applicable conditions pass:

1. `users.is_active` / `activeForApi()` is true.
2. User has `security-management` **read** permission.
3. User is linked to the Property.
4. Property is active.
5. Property entitlement `security-management` is enabled.
6. User has an active `security_personnel` row for that Property.
7. Admin-role accounts are excluded from the operational personnel roster.

### 3.1 Middleware boundary vs property boundary

The `security.api` middleware deliberately checks active personnel membership **without checking entitlement**. This preserves the existing fail-closed contract:

- aggregate/property-dependent endpoints can return `403`;
- resource probes outside the accessible property boundary can return `404`.

The actual accessible Property collection (`SecurityPropertyScope::properties`) **does** require entitlement.

### 3.2 `/me` nuance

Because middleware checks roster membership while `profilePayload()` calculates entitled properties separately, a stale/current token can theoretically receive:

```json
{
  "properties": [],
  "default_property": null
}
```

from `/me` if Security entitlement is removed while an active personnel membership remains. Frontend must therefore use returned `properties`, not assume a successful `/me` implies at least one currently entitled Property.

### 3.3 Important permission caveat — current source behavior

The current Web Admin `OperationalPersonnelManager` reconciles an active personnel membership to:

```text
can_read   = true
can_update = true
```

For a **new** `user_modules` permission row it initializes:

```text
can_create = false
can_delete = false
```

Therefore these two Security Mobile endpoints need explicit `security-management` **create** permission:

```text
POST /api/security/incidents
POST /api/security/packages
```

A newly created Security Personnel account can successfully log in and perform read/update operations, but may receive:

```http
403 FORBIDDEN
```

when creating an Incident or registering a Package until `can_create=true` is granted.

This is a backend provisioning/permission fact in the current source, not a frontend error.

---

## 4. Standard Security Response Contract

All `/api/security/*` endpoints use the dedicated Security response envelope.

### 4.1 Success

```json
{
  "status": "success",
  "message": "Localized message",
  "data": {}
}
```

When pagination or other metadata applies:

```json
{
  "status": "success",
  "message": "Localized message",
  "data": [],
  "meta": {}
}
```

### 4.2 Error

```json
{
  "status": "error",
  "code": "MACHINE_CODE",
  "message": "Localized human-readable message",
  "errors": {}
}
```

Some domain errors additionally expose structured `data`:

```json
{
  "status": "error",
  "code": "PATROL_CHECKPOINTS_PENDING",
  "message": "...",
  "errors": {},
  "data": {
    "pending_count": 2
  }
}
```

**Frontend rule:** branch on `HTTP status + code`; never branch on localized `message`.

When no field errors exist, `errors` is an empty JSON **object** `{}` on the wire.

### 4.3 Pagination metadata

Security paginated endpoints expose:

```json
{
  "current_page": 1,
  "last_page": 3,
  "per_page": 20,
  "total": 52,
  "from": 1,
  "to": 20,
  "count": 20,
  "has_more": true,
  "sort": "updated_at_desc,id_desc"
}
```

### 4.4 Timestamps

Contract timestamp helpers emit ISO-8601 values in the application timezone.

Example:

```text
2026-08-20T16:15:30+07:00
```

Nullable timestamps are returned as `null`.

---

# 5. Endpoint Inventory

There are **39 routes under `/api/security`**, plus **1 signed patrol-photo route**.

| # | Method | Endpoint | Extra permission |
|---:|---|---|---|
| 1 | POST | `/api/security/login` | Public login |
| 2 | GET | `/api/security/me` | Auth + Security roster/read |
| 3 | POST | `/api/security/logout` | Auth + Security roster/read |
| 4 | GET | `/api/security/dashboard` | Auth |
| 5 | POST | `/api/security/visitor-access/validate` | Auth |
| 6 | GET | `/api/security/visitors/search` | Auth |
| 7 | GET | `/api/security/visitors/{visitor}` | Auth |
| 8 | POST | `/api/security/visitors/{visitor}/check-in` | `update` |
| 9 | POST | `/api/security/visitors/{visitor}/check-out` | `update` |
| 10 | GET | `/api/security/verification-history` | Auth |
| 11 | GET | `/api/security/visitors/{visitor}/identity-photo` | Auth |
| 12 | GET | `/api/security/patrol/dashboard` | Auth |
| 13 | GET | `/api/security/patrol/sessions` | Auth |
| 14 | GET | `/api/security/patrol/sessions/{patrolSession}` | Auth |
| 15 | GET | `/api/security/patrol/history` | Auth |
| 16 | POST | `/api/security/patrol/sessions/{patrolSession}/start` | `update` |
| 17 | POST | `/api/security/patrol/sessions/{patrolSession}/complete` | `update` |
| 18 | POST | `/api/security/patrol/checkpoint-visits/{visit}/complete` | `update` |
| 19 | POST | `/api/security/patrol/checkpoint-visits/{visit}/skip` | `update` |
| 20 | GET | `/api/security/emergency-alerts/active` | Auth |
| 21 | GET | `/api/security/emergency-alerts` | Auth |
| 22 | GET | `/api/security/emergency-alerts/history` | Auth |
| 23 | GET | `/api/security/emergency-alerts/{emergencyAlert}` | Auth |
| 24 | POST | `/api/security/emergency-alerts/{emergencyAlert}/acknowledge` | `update` |
| 25 | POST | `/api/security/emergency-alerts/{emergencyAlert}/resolve` | `update` |
| 26 | GET | `/api/security/packages/residents/search` | Auth + Package Center entitlement |
| 27 | GET | `/api/security/packages` | Auth + Package Center entitlement |
| 28 | GET | `/api/security/packages/{residentPackage}` | Auth + Package Center entitlement |
| 29 | POST | `/api/security/packages` | **`create`** + Package Center entitlement |
| 30 | POST | `/api/security/packages/{residentPackage}/collect` | `update` + Package Center entitlement |
| 31 | GET | `/api/security/incidents/dashboard` | Auth |
| 32 | GET | `/api/security/incidents` | Auth |
| 33 | GET | `/api/security/incidents/history` | Auth |
| 34 | GET | `/api/security/incidents/{incident}` | Auth |
| 35 | POST | `/api/security/incidents` | **`create`** |
| 36 | POST | `/api/security/incidents/{incident}/acknowledge` | `update` |
| 37 | POST | `/api/security/incidents/{incident}/start` | `update` |
| 38 | POST | `/api/security/incidents/{incident}/resolve` | `update` |
| 39 | POST | `/api/security/incidents/{incident}/notes` | `update` |
| 40 | GET | `/api/files/security-patrol-checkpoint-visits/{visit}/photo?...` | Temporary signed URL |

---

# 6. Authentication

## 6.1 POST `/api/security/login`

### Request

```json
{
  "username": "security01",
  "password": "secret"
}
```

Validation:

| Field | Rule |
|---|---|
| `username` | required, string |
| `password` | required, string |

Security login matches **username only**. Email/mobile are not accepted as aliases by this endpoint.

### Required backend state

- valid active `User`;
- password matches;
- `security-management.can_read = true`;
- at least one currently accessible Security Property;
- active `security_personnel` membership for the Property;
- Security entitlement enabled on the Property.

### Success `200`

```json
{
  "status": "success",
  "message": "...",
  "data": {
    "id": 10,
    "name": "Security Officer",
    "username": "security01",
    "role": "Staff",
    "is_active": true,
    "default_property": {
      "id": 1,
      "code": "DEFAULT",
      "name": "Aparthub Property",
      "is_default": true
    },
    "properties": [
      {
        "id": 1,
        "code": "DEFAULT",
        "name": "Aparthub Property",
        "is_default": true
      }
    ],
    "security_profile": null,
    "token": "<plain-text-sanctum-token>",
    "token_type": "Bearer"
  }
}
```

`security_profile` is intentionally `null`. No shift/badge/device profile is fabricated in current source.

### Errors

| HTTP | Code | Meaning |
|---:|---|---|
| 401 | `SECURITY_INVALID_CREDENTIALS` | User/password/account/read permission invalid |
| 403 | `SECURITY_PROPERTY_UNAVAILABLE` | No accessible Security Property |
| 422 | `VALIDATION_ERROR` | Missing/invalid request fields |

---

## 6.2 GET `/api/security/me`

Bearer required.

Returns the same identity/property payload as login, without `token` and `token_type`.

Use this endpoint for session restore after loading a stored token.

---

## 6.3 POST `/api/security/logout`

Bearer required.

Revokes **current Sanctum token only**.

Success:

```json
{
  "status": "success",
  "message": "...",
  "data": null
}
```

---

# 7. Visitor Verification

## 7.1 Canonical Visitor statuses

```text
Pending
Approved
Rejected
Checked In
Checked Out
Cancelled
Expired
```

## 7.2 Common Security Visitor payload

```json
{
  "visit_id": 100,
  "visit_code": "VST-...",
  "visitor_id": 100,
  "visitor_name": "Guest Name",
  "visitor_phone": "0812...",
  "resident_name": "Resident Name",
  "property_name": "Aparthub Property",
  "tower_name": "A",
  "unit_name": "A-101",
  "purpose": "Visit",
  "scheduled_at": "2026-08-20T10:00:00+07:00",
  "valid_from": "2026-08-20T00:00:00+07:00",
  "valid_until": "2026-08-20T23:59:59+07:00",
  "status": "Approved",
  "checked_in_at": null,
  "checked_out_at": null,
  "checked_in_by": null,
  "checked_out_by": null,
  "unit": "A-101",
  "tower": "A",
  "property": {
    "id": 1,
    "code": "DEFAULT",
    "name": "Aparthub Property"
  },
  "visit_date": "2026-08-20",
  "estimated_arrival_time": "10:00:00",
  "guest_count": 2,
  "visit_purpose": "Visit",
  "can_check_in": true,
  "can_check_out": false,
  "identity_photo_url": "https://.../api/security/visitors/100/identity-photo"
}
```

Notes:

- `visitor_id` currently aliases the same visit record ID as `visit_id`.
- raw `access_code` is **not** exposed by visitor search/detail payloads.
- `identity_photo_url` is bearer-protected, not a public signed URL.
- legacy Visitor records with `property_id = null` retain a compatibility path in the Visitor service. New/current searching is property scoped.

---

## 7.3 GET `/api/security/dashboard`

Uses the authenticated user's **default accessible Security Property**.

Success data:

```json
{
  "property": {
    "id": 1,
    "code": "DEFAULT",
    "name": "Aparthub Property"
  },
  "today": {
    "total_visitors": 4,
    "pending_approval": 1,
    "approved_arrivals": 2,
    "checked_in": 1,
    "checked_out": 0
  }
}
```

No accessible default Security Property → `403 SECURITY_PROPERTY_UNAVAILABLE`.

---

## 7.4 GET `/api/security/visitors/search`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `q` | required string, max 255 | — |
| `limit` | integer 1..50 | 20 |

Searches accessible Security properties by:

- exact `visit_code`;
- exact `access_code`;
- visitor name;
- visitor phone;
- resident name;
- unit code;
- numeric query may also match Visitor ID.

Response is not paginated:

```json
{
  "status": "success",
  "data": [/* visitor payloads */],
  "meta": {
    "count": 2,
    "limit": 20
  }
}
```

Sort: visit date descending, then ID descending.

---

## 7.5 GET `/api/security/visitors/{visitor}`

Returns the common Visitor payload.

The service applies Visitor expiry before returning the record.

A Visitor outside the current Security property boundary fails closed as:

```http
404 VISITOR_NOT_FOUND
```

---

## 7.6 POST `/api/security/visitor-access/validate`

### Request

```json
{
  "code": "<access-code-from-QR>"
}
```

`code`: required string max 255.

### Valid result `200`

```json
{
  "status": "success",
  "data": {
    "is_valid": true,
    "reason": null,
    "...": "full visitor payload"
  }
}
```

### Invalid / inaccessible code

Unknown/inaccessible access code:

```http
404 VISITOR_QR_INVALID
```

with:

```json
{
  "data": {
    "is_valid": false,
    "reason": "localized reason"
  }
}
```

Known Visitor in an invalid state returns `422` with one of:

```text
VISITOR_BLACKLISTED
VISITOR_PENDING_APPROVAL
VISITOR_REJECTED
VISITOR_CANCELLED
VISITOR_ALREADY_CHECKED_IN
VISITOR_ALREADY_CHECKED_OUT
VISITOR_EXPIRED
VISITOR_NOT_VALID_TODAY
VISITOR_QR_INVALID
```

and `data` includes `is_valid`, `reason`, plus the Visitor payload.

QR validity requires the current source conditions to pass:

- status is `Approved`;
- Visitor is not blacklisted;
- access code exists;
- visit date exists;
- expiry exists;
- current date is the visit date;
- current time has not exceeded expiry.

Every QR validation attempt records a verification audit event.

---

## 7.7 POST `/api/security/visitors/{visitor}/check-in`

Requires `security-management.update`.

### Request

```json
{
  "verification_method": "qr",
  "code": "<required-when-qr>",
  "access_card_number": "CARD-001"
}
```

Rules:

| Field | Rule |
|---|---|
| `verification_method` | required, `qr` or `manual` |
| `code` | required when method=`qr`, string max255 |
| `access_card_number` | optional string max255 |

For QR mode, submitted code must match the Visitor access code.

Check-in is allowed only when the Visitor's canonical state/validity allows it. Blacklist is enforced.

Success returns the updated Visitor payload.

Common state failures include `409`/`422` with canonical Visitor codes, including already checked-in, expired, wrong date, invalid state, or blacklist.

---

## 7.8 POST `/api/security/visitors/{visitor}/check-out`

Requires `security-management.update`.

No request body is required.

Only a currently `Checked In` Visitor may check out.

Success sets:

```text
status = Checked Out
checked_out_at = now
checked_out_by = authenticated security user
```

Repeated checkout → `409 VISITOR_ALREADY_CHECKED_OUT`.

---

## 7.9 GET `/api/security/verification-history`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `page` | integer >=1 | 1 |
| `per_page` | integer 1..100 | 20 |
| `status` | one canonical Visitor status | null |
| `q` | string max255 | null |

History contains records with operational verification outcomes such as check-in/check-out and terminal rejection/cancel/expiry states.

Sort:

```text
updated_at DESC, id DESC
```

Returns standard Security pagination `meta`.

---

## 7.10 GET `/api/security/visitors/{visitor}/identity-photo`

Bearer-protected binary endpoint.

Rules:

- Visitor must be accessible to current Security user.
- File must exist on `local` disk.
- Missing file → `404`.

Response security headers include:

```http
Cache-Control: private, no-store
X-Content-Type-Options: nosniff
```

Do not persist the binary response indefinitely on a shared/public cache.

---

# 8. Patrol

## 8.1 Canonical statuses

Patrol Session:

```text
Scheduled
In Progress
Completed
Cancelled
```

Checkpoint Visit:

```text
Pending
Completed
Skipped
Issue
```

Security Mobile only sees Patrol Sessions:

- assigned to the authenticated Security user; and
- located in an accessible Security Property.

No QR/NFC/RFID/beacon/GPS checkpoint contract exists in current source. `scan_token` is intentionally not exposed.

---

## 8.2 GET `/api/security/patrol/dashboard`

Returns:

```json
{
  "scheduled": 1,
  "in_progress": 0,
  "completed_today": 2,
  "cancelled_today": 0,
  "next_patrol": null
}
```

`next_patrol`, when present, uses the Patrol Session summary payload.

No accessible property → `403 SECURITY_PROPERTY_UNAVAILABLE`.

---

## 8.3 GET `/api/security/patrol/sessions`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `status` | one Patrol Session status | null |
| `date` | `Y-m-d` | null |
| `per_page` | integer 1..100 | 20 |

Sort:

```text
scheduled_start_at DESC, id DESC
```

Session payload:

```json
{
  "patrol_session_id": 12,
  "session_number": "PAT-...",
  "status": "Scheduled",
  "property": {"id":1,"code":"DEFAULT","name":"Aparthub Property"},
  "route": {
    "id": 3,
    "code": "Patroli-A",
    "name": "Lobby & Parking",
    "description": null,
    "expected_duration_minutes": 30
  },
  "officer": {"id":10,"name":"Security Officer"},
  "scheduled_start_at": "2026-08-20T20:00:00+07:00",
  "started_at": null,
  "completed_at": null,
  "cancelled_at": null,
  "notes": null,
  "checkpoint_summary": {
    "total": 3,
    "pending": 3,
    "completed": 0,
    "skipped": 0,
    "issue": 0
  },
  "can_start": true,
  "can_complete": false
}
```

---

## 8.4 GET `/api/security/patrol/sessions/{patrolSession}`

Only the assigned authenticated officer can retrieve the session.

Outside owner/property scope → `404 PATROL_NOT_FOUND`.

Detail adds:

```json
"checkpoints": []
```

Checkpoint payload:

```json
{
  "visit_id": 50,
  "checkpoint_id": 7,
  "code": "CP-LOBBY",
  "name": "Lobby",
  "location_label": "Main Lobby",
  "sequence": 1,
  "status": "Pending",
  "checked_at": null,
  "checked_by": null,
  "notes": null,
  "photo_evidence": null,
  "can_complete": true,
  "can_skip": true
}
```

With photo evidence:

```json
"photo_evidence": {
  "url": "https://.../api/files/security-patrol-checkpoint-visits/50/photo?expires=...&signature=...",
  "original_name": "checkpoint.jpg",
  "mime_type": "image/jpeg",
  "file_size": 123456,
  "uploaded_at": "2026-08-20T20:10:00+07:00"
}
```

---

## 8.5 POST `/api/security/patrol/sessions/{patrolSession}/start`

Requires `update`.

No request body.

Allowed:

```text
Scheduled → In Progress
```

Sets `started_at`.

Errors:

| HTTP | Code |
|---:|---|
| 404 | `PATROL_NOT_FOUND` |
| 409 | `PATROL_ALREADY_STARTED` |
| 409 | `PATROL_CANCELLED` |
| 409 | `PATROL_ALREADY_COMPLETED` |
| 409 | `PATROL_INVALID_STATE` |

---

## 8.6 POST `/api/security/patrol/checkpoint-visits/{visit}/complete`

Requires `update`.

**Multipart request:**

| Field | Rule |
|---|---|
| `photo` | **required**, jpg/jpeg/png/webp, max 5120 KB |
| `notes` | optional string max2000 |

Operational requirements:

- checkpoint belongs to current user's Patrol Session;
- property is accessible;
- session status is `In Progress`;
- checkpoint status is `Pending`.

Result:

```text
checkpoint.status = Completed
checked_at = now
checked_by = current officer
```

Photo is stored privately on local disk.

Errors include:

```text
PATROL_CHECKPOINT_NOT_FOUND       404
PATROL_NOT_IN_PROGRESS            409
PATROL_CHECKPOINT_ALREADY_PROCESSED 409
PATROL_CHECKPOINT_INVALID_STATE   409
PATROL_CHECKPOINT_PHOTO_STORE_FAILED 500
VALIDATION_ERROR                  422
```

---

## 8.7 POST `/api/security/patrol/checkpoint-visits/{visit}/skip`

Requires `update`.

Multipart:

| Field | Rule |
|---|---|
| `notes` | **required**, string max2000 |
| `photo` | optional jpg/jpeg/png/webp max5120 KB |

Result:

```text
status = Skipped
```

Skip reason is mandatory. Photo is optional.

---

## 8.8 POST `/api/security/patrol/sessions/{patrolSession}/complete`

Requires `update`.

Request:

```json
{
  "notes": "Optional completion notes"
}
```

Requirements:

- session is `In Progress`;
- no checkpoint remains `Pending`.

If pending checkpoints remain:

```http
409 PATROL_CHECKPOINTS_PENDING
```

```json
{
  "data": {
    "pending_count": 2
  }
}
```

Success:

```text
status = Completed
completed_at = now
```

---

## 8.9 GET `/api/security/patrol/history`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `status` | `Completed` or `Cancelled` | null |
| `per_page` | integer 1..100 | 20 |

Sort:

```text
updated_at DESC, id DESC
```

---

## 8.10 Signed Patrol Photo

`GET /api/files/security-patrol-checkpoint-visits/{visit}/photo?expires=...&signature=...`

The URL is generated by backend in `photo_evidence.url`.

Properties:

- temporary signed Laravel route;
- no Bearer token is required for the signed file request itself;
- signed URL expiry is enforced;
- default TTL is 30 minutes;
- configured TTL is clamped to 1..60 minutes;
- throttle: 120 requests/minute;
- file must be on local disk;
- private/no-store;
- `nosniff`.

Frontend should treat signed URLs as ephemeral and refetch Patrol detail when the URL expires.

---

# 9. Security Incidents

## 9.1 Canonical severity

```text
Low
Medium
High
Critical
```

## 9.2 Canonical status

```text
Open
Acknowledged
In Progress
Resolved
Closed
Cancelled
```

Security Mobile can create and operationally transition incidents. `Closed`/`Cancelled` exist as canonical domain states but there are no Mobile close/cancel endpoints in this route set.

---

## 9.3 GET `/api/security/incidents/dashboard`

Returns:

```json
{
  "open": 3,
  "critical": 1,
  "escalated": 1,
  "assigned_to_me": 1,
  "reported_by_me": 2,
  "resolved_today": 4
}
```

`open` includes:

```text
Open
Acknowledged
In Progress
```

`escalated` means open incident with `escalation_level > 0`.

---

## 9.4 GET `/api/security/incidents`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `status` | any canonical Incident status | null |
| `severity` | Low/Medium/High/Critical | null |
| `scope` | `mine`, `assigned`, `reported`, `all` | `mine` |
| `q` | string max255 | null |
| `per_page` | integer 1..100 | 20 |

Scopes:

```text
mine     = assigned_to current user OR reported_by current user
assigned = assigned_to current user
reported = reported_by current user
all      = all incidents inside accessible Security properties
```

Search covers number/title/description/location/category.

Sort:

```text
reported_at DESC, id DESC
```

Incident payload:

```json
{
  "incident_id": 80,
  "incident_number": "INC-20260820-000080",
  "property": {"id":1,"code":"DEFAULT","name":"Aparthub Property"},
  "patrol_context": null,
  "reported_by": {"id":10,"name":"Security Officer"},
  "assigned_to": null,
  "category": "Safety",
  "severity": "High",
  "status": "Open",
  "title": "Wet floor",
  "description": "Description",
  "location": "Lobby",
  "reported_at": "2026-08-20T16:00:00+07:00",
  "acknowledged_at": null,
  "resolved_at": null,
  "closed_at": null,
  "escalated_at": null,
  "escalation_level": 0,
  "resolution_notes": null,
  "can_acknowledge": true,
  "can_start": true,
  "can_resolve": false,
  "can_add_note": true
}
```

---

## 9.5 GET `/api/security/incidents/history`

Same list filters, except `status` may only be:

```text
Resolved
Closed
Cancelled
```

Sort:

```text
updated_at DESC, id DESC
```

---

## 9.6 GET `/api/security/incidents/{incident}`

Property scoped.

Outside scope → `404 INCIDENT_NOT_FOUND`.

Adds `timeline`:

```json
[
  {
    "event_id": 1,
    "event": "created",
    "from_status": null,
    "to_status": "Open",
    "notes": "...",
    "metadata": {},
    "actor": {"id":10,"name":"Security Officer"},
    "created_at": "2026-08-20T16:00:00+07:00"
  }
]
```

---

## 9.7 POST `/api/security/incidents`

Requires **`security-management.create`**.

### Request

```json
{
  "property_id": 1,
  "patrol_checkpoint_visit_id": null,
  "title": "Wet floor",
  "description": "Water found near lift.",
  "category": "Safety",
  "severity": "High",
  "location": "Tower A Lobby"
}
```

Rules:

| Field | Rule |
|---|---|
| `property_id` | optional integer |
| `patrol_checkpoint_visit_id` | optional integer |
| `title` | required string max255 |
| `description` | required string max5000 |
| `category` | required string max80 |
| `severity` | required canonical severity |
| `location` | optional string max255 |

### Property selection

If no checkpoint is linked:

- one accessible property → backend auto-selects it;
- multiple accessible properties → `property_id` is required;
- inaccessible requested property → `403 FORBIDDEN`.

If a Patrol checkpoint is linked:

- property derives from the checkpoint;
- explicitly supplied `property_id`, if any, must match;
- checkpoint must belong to the authenticated officer;
- Patrol Session must be `In Progress`;
- checkpoint must still be `Pending`.

Creating an incident from a Patrol checkpoint also changes the checkpoint to:

```text
status = Issue
checked_at = now
checked_by = current officer
notes = incident description
```

Success: `201`.

Incident number format:

```text
INC-YYYYMMDD-xxxxxx
```

---

## 9.8 POST `/api/security/incidents/{incident}/acknowledge`

Requires `update`.

Request:

```json
{"notes":"optional"}
```

`notes`: optional max5000.

Allowed transition:

```text
Open → Acknowledged
```

---

## 9.9 POST `/api/security/incidents/{incident}/start`

Requires `update`.

Request:

```json
{"notes":"optional"}
```

Allowed:

```text
Open → In Progress
Acknowledged → In Progress
```

---

## 9.10 POST `/api/security/incidents/{incident}/resolve`

Requires `update`.

Request:

```json
{
  "notes": "Resolution notes are required."
}
```

Allowed:

```text
Acknowledged → Resolved
In Progress → Resolved
```

`notes` required max5000 and becomes `resolution_notes`.

---

## 9.11 POST `/api/security/incidents/{incident}/notes`

Requires `update`.

```json
{
  "notes": "Operational note"
}
```

Required max5000.

Current source allows notes for `Resolved`; it blocks only:

```text
Closed
Cancelled
```

---

## 9.12 Incident state error codes

```text
INCIDENT_NOT_FOUND
INCIDENT_ALREADY_ACKNOWLEDGED
INCIDENT_ALREADY_IN_PROGRESS
INCIDENT_ALREADY_RESOLVED
INCIDENT_CLOSED
INCIDENT_CANCELLED
INCIDENT_INVALID_STATE
PATROL_CHECKPOINT_NOT_FOUND
PATROL_NOT_IN_PROGRESS
PATROL_CHECKPOINT_ALREADY_PROCESSED
VALIDATION_ERROR
FORBIDDEN
```

Typical invalid lifecycle transitions use HTTP `409`.

---

# 10. Emergency SOS

SOS creation originates from the **Resident API**. Security consumes and responds to those alerts.

Canonical statuses:

```text
Open
Acknowledged
Resolved
```

---

## 10.1 GET `/api/security/emergency-alerts/active`

Returns only `Open` alerts, sorted oldest first:

```text
triggered_at ASC, id ASC
```

Response meta:

```json
{
  "count": 2,
  "modal_required": true,
  "sort": "triggered_at_asc,id_asc"
}
```

Once an alert is acknowledged, it leaves this active modal queue.

---

## 10.2 GET `/api/security/emergency-alerts`

Query:

```text
per_page: optional integer 1..100, default 30
```

Returns unresolved alerts:

```text
Open
Acknowledged
```

Sort:

```text
triggered_at DESC, id DESC
```

---

## 10.3 GET `/api/security/emergency-alerts/history`

`per_page` 1..100, default 30.

Returns `Resolved` alerts only.

Sort:

```text
resolved_at DESC, id DESC
```

---

## 10.4 GET `/api/security/emergency-alerts/{emergencyAlert}`

Accessible Security property only.

Payload:

```json
{
  "emergency_alert_id": 4,
  "alert_code": "SOS-...",
  "status": "Open",
  "message": "Emergency message",
  "modal_required": true,
  "taken_by_me": false,
  "property": {"id":1,"code":"DEFAULT","name":"Aparthub Property"},
  "resident": {"id":20,"name":"Resident","mobile_no":"0812..."},
  "unit": {"id":5,"code":"A-101","tower":"A","floor":"1"},
  "triggered_at": "2026-08-20T16:00:00+07:00",
  "acknowledged_at": null,
  "acknowledged_by": null,
  "resolved_at": null,
  "resolved_by": null,
  "resolution_notes": null
}
```

---

## 10.5 POST `/api/security/emergency-alerts/{emergencyAlert}/acknowledge`

Requires `update`.

No body.

Behavior:

- `Open` → `Acknowledged`, assigned to current Security user.
- already acknowledged by **same** user → idempotent success.
- acknowledged by another user → `409 EMERGENCY_ALREADY_TAKEN`.
- already resolved → `409 EMERGENCY_ALREADY_RESOLVED`.

---

## 10.6 POST `/api/security/emergency-alerts/{emergencyAlert}/resolve`

Requires `update`.

Request:

```json
{
  "notes": "Optional resolution notes"
}
```

`notes`: optional max2000.

Requirements:

- status must be `Acknowledged`;
- alert must be acknowledged by current Security user.

Errors:

```text
EMERGENCY_ALERT_NOT_FOUND
EMERGENCY_ALREADY_RESOLVED
EMERGENCY_NOT_ACKNOWLEDGED
EMERGENCY_ASSIGNED_TO_OTHER
```

---

# 11. Package Receiving / Package Center

Security Package APIs have **two authorization layers**:

1. Security property access; and
2. `package-center` entitlement enabled on that Property.

Canonical statuses:

```text
Ready for Pickup
Collected
Expired
```

Ready packages whose `expires_at` is already in the past are auto-expired when relevant Package APIs execute.

---

## 11.1 GET `/api/security/packages/residents/search`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `q` | optional string max120 | empty |
| `property_id` | optional integer | null |
| `limit` | integer 1..50 | 30 |

Only active Residents (`Aktif` or `Active`) inside accessible Package Center properties.

Search:

- name;
- mobile;
- email;
- unit code;
- tower.

Sort: Resident name ascending.

Resident payload:

```json
{
  "id": 20,
  "name": "Resident",
  "email": "resident@example.com",
  "mobile_no": "0812...",
  "property": {"id":1,"code":"DEFAULT","name":"Aparthub Property"},
  "unit": {"id":5,"code":"A-101","tower":"A","floor":"1"}
}
```

---

## 11.2 GET `/api/security/packages`

Query:

| Parameter | Rule | Default |
|---|---|---|
| `property_id` | optional integer | null |
| `status` | Ready for Pickup / Collected / Expired | null |
| `search` | optional string max120 | empty |
| `per_page` | integer 1..100 | 30 |

Search covers package/tracking/courier/sender/resident/unit/tower.

Current query ordering prioritizes `Ready for Pickup` and `Expired`, then:

```text
received_at DESC
id DESC
```

The response `meta.sort` label is currently:

```text
received_at_desc,id_desc
```

Frontend should not attempt to reconstruct server ordering independently.

No Package-enabled accessible property:

```http
409 PACKAGE_CENTER_UNAVAILABLE
```

---

## 11.3 GET `/api/security/packages/{residentPackage}`

Accessible Package Center properties only.

Missing/out-of-scope → `404 PACKAGE_NOT_FOUND`.

---

## 11.4 POST `/api/security/packages`

Requires **Security `create` permission** and Package Center entitlement.

Request:

```json
{
  "resident_id": 20,
  "courier_name": "JNE",
  "tracking_number": "AWB123",
  "sender_name": "Sender",
  "package_description": "Box",
  "storage_location": "Lobby Rack A",
  "notes": "Optional"
}
```

Rules:

| Field | Rule |
|---|---|
| `resident_id` | required integer |
| `courier_name` | required string max100 |
| `tracking_number` | optional max160 |
| `sender_name` | optional max160 |
| `package_description` | optional max255 |
| `storage_location` | optional max120 |
| `notes` | optional max2000 |

Resident must be active and in an accessible Package Center Property.

Unknown/inaccessible Resident:

```http
404 PACKAGE_RESIDENT_NOT_FOUND
```

Success `201` creates:

```text
status = Ready for Pickup
received_by = authenticated Security user
received_at = now
```

Package number generated with current source format similar to:

```text
PKG-yymmdd-XXXXXXXX
```

---

## 11.5 POST `/api/security/packages/{residentPackage}/collect`

Requires `update`.

Request:

```json
{
  "collection_notes": "Handed to resident"
}
```

`collection_notes`: optional max1000.

If not already collected:

```text
status = Collected
collected_by = current Security user
collected_at = now
```

If already `Collected`, current service returns the existing package successfully; collection is effectively idempotent.

---

## 11.6 Package payload

```json
{
  "package_id": 1,
  "package_no": "PKG-...",
  "status": "Ready for Pickup",
  "courier_name": "JNE",
  "tracking_number": "AWB123",
  "sender_name": "Sender",
  "package_description": "Box",
  "storage_location": "Lobby Rack A",
  "notes": null,
  "collection_notes": null,
  "property": {"id":1,"code":"DEFAULT","name":"Aparthub Property"},
  "resident": {
    "id":20,
    "name":"Resident",
    "email":"resident@example.com",
    "mobile_no":"0812...",
    "property":{"id":1,"code":"DEFAULT","name":"Aparthub Property"},
    "unit":{"id":5,"code":"A-101","tower":"A","floor":"1"}
  },
  "unit": {"id":5,"code":"A-101","tower":"A","floor":"1"},
  "received_by": {"id":10,"name":"Security Officer"},
  "collected_by": null,
  "received_at": "2026-08-20T16:00:00+07:00",
  "notified_at": null,
  "collected_at": null,
  "expires_at": null
}
```

---

# 12. Security Error Matrix

Core API errors:

| HTTP | Code | Meaning |
|---:|---|---|
| 401 | `UNAUTHENTICATED` | Missing/invalid Sanctum auth |
| 401 | `SECURITY_INVALID_CREDENTIALS` | Login rejected |
| 403 | `FORBIDDEN` | Permission/action forbidden |
| 403 | `SECURITY_PROPERTY_UNAVAILABLE` | No accessible Security Property |
| 404 | `RESOURCE_NOT_FOUND` | Generic missing Security resource |
| 422 | `VALIDATION_ERROR` | Request/state validation |
| 500 | `SERVER_ERROR` | Unhandled server error |

Visitor:

```text
VISITOR_NOT_FOUND
VISITOR_QR_INVALID
VISITOR_PENDING_APPROVAL
VISITOR_REJECTED
VISITOR_CANCELLED
VISITOR_ALREADY_CHECKED_IN
VISITOR_ALREADY_CHECKED_OUT
VISITOR_EXPIRED
VISITOR_INVALID_STATE
VISITOR_NOT_VALID_TODAY
VISITOR_BLACKLISTED
```

Patrol:

```text
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
PATROL_CHECKPOINT_PHOTO_STORE_FAILED
```

Incidents:

```text
INCIDENT_NOT_FOUND
INCIDENT_ALREADY_ACKNOWLEDGED
INCIDENT_ALREADY_IN_PROGRESS
INCIDENT_ALREADY_RESOLVED
INCIDENT_CLOSED
INCIDENT_CANCELLED
INCIDENT_INVALID_STATE
```

Emergency:

```text
EMERGENCY_ALERT_NOT_FOUND
EMERGENCY_ALREADY_TAKEN
EMERGENCY_ALREADY_RESOLVED
EMERGENCY_NOT_ACKNOWLEDGED
EMERGENCY_ASSIGNED_TO_OTHER
```

Package:

```text
PACKAGE_CENTER_UNAVAILABLE
PACKAGE_RESIDENT_NOT_FOUND
PACKAGE_NOT_FOUND
```

---

# 13. Flutter Integration Rules

## 13.1 Login/session

Recommended flow:

```text
POST /security/login
        ↓
securely store bearer token
        ↓
GET /security/me on cold start
        ↓
if 401/403 → clear session / return login
```

Do not infer Security access only from Role. The backend roster/property response is authoritative.

## 13.2 Property handling

Use `data.properties` and `default_property` from auth profile.

Do not fabricate properties from old local cache.

A user can belong to multiple Aparthub properties but Security sees only the subset meeting current entitlement + personnel rules.

## 13.3 Canonical statuses

Store/compare canonical status strings exactly as sent by backend. Translate only UI labels.

Do not translate machine `code`.

## 13.4 Errors

Correct pattern:

```dart
if (statusCode == 409 && code == 'PATROL_CHECKPOINTS_PENDING') {
  ...
}
```

Incorrect:

```dart
if (message == 'Semua checkpoint...') { ... }
```

Messages change with `Accept-Language`.

## 13.5 Photos

- Visitor identity photo: authenticated endpoint.
- Patrol checkpoint photo: temporary signed URL.
- Completed checkpoint requires photo.
- Skip checkpoint photo optional.
- Do not persist signed URL permanently.

## 13.6 Security create permission

Flutter should gracefully surface `403 FORBIDDEN` for Incident creation / Package receiving. Do **not** assume login access means create access.

If product requirement is “every active Security Personnel can always create Incident/Package”, backend provisioning should be changed explicitly rather than worked around client-side.

---

# 14. Current Source Boundaries / Explicit Non-Features

Current API does **not** establish these contracts:

```text
Security shift management
attendance / leave
employee number
badge number
device registry
RFID
NFC
checkpoint QR scanner token
GPS proof
beacon
ANPR
CCTV integration
panic hardware
access-control hardware
```

Do not invent request fields or UI state for them.

`security_profile` remains:

```json
null
```

until a real profile schema is intentionally introduced.

---

# 15. Recommended Security Mobile Smoke Sequence

After deployment, a representative end-to-end smoke is:

```text
1. Login Security Personnel
2. GET /me and verify property scope
3. Visitor manual/search
4. QR validate
5. Visitor check-in
6. Visitor check-out
7. Patrol list/detail
8. Start Patrol
9. Complete checkpoint with photo
10. Skip checkpoint with reason
11. Complete Patrol
12. Create Incident (requires create permission)
13. Incident acknowledge/start/resolve
14. Receive Resident SOS
15. Acknowledge SOS
16. Resolve SOS
17. Search resident for Package
18. Register Package (requires create permission)
19. Collect Package
20. Logout
```

Validate both:

```text
Accept-Language: en
Accept-Language: id
```

and verify `Content-Language`.

---

# 16. Source Areas Audited

Primary current-source files used for this contract include:

```text
routes/api.php
bootstrap/app.php
app/Http/Middleware/SetLocale.php
app/Http/Middleware/EnsureAuthenticatedSecurityUser.php
app/Http/Controllers/Api/SecurityAuthController.php
app/Http/Controllers/Api/SecurityVisitorAccessController.php
app/Http/Controllers/Api/SecurityPatrolController.php
app/Http/Controllers/Api/SecurityPatrolCheckpointPhotoController.php
app/Http/Controllers/Api/SecurityIncidentController.php
app/Http/Controllers/Api/SecurityEmergencyController.php
app/Http/Controllers/Api/SecurityPackageController.php
app/Services/OperationalPersonnelManager.php
app/Services/SecurityOperations/SecurityPropertyScope.php
app/Services/SecurityOperations/SecurityPatrolMobileService.php
app/Services/SecurityOperations/SecurityIncidentMobileService.php
app/Services/SecurityOperations/EmergencySosService.php
app/Services/SecurityOperations/SecurityPackageMobileService.php
app/Services/Visitors/SecurityVisitorService.php
app/Support/SecurityApiResponse.php
app/Support/SecurityApiContract.php
app/Models/SecurityPersonnel.php
app/Models/SecurityPatrolSession.php
app/Models/SecurityPatrolCheckpointVisit.php
app/Models/SecurityIncident.php
app/Models/SecurityEmergencyAlert.php
app/Models/ResidentPackage.php
tests/Feature/Security*FeatureTest.php
tests/Feature/CrossAppEndToEndIntegrationTest.php
tests/Feature/VisitorBlacklistFeatureTest.php
tests/Feature/OperationalPersonnelMasterTest.php
```

---

**End of Security API handoff.**
