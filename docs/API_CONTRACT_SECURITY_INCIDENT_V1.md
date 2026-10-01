# Aparthub Security Mobile — Incident Reporting API V1

Status: **APH.32 implementation contract — regression pending**

This contract extends the existing Security Mobile Bearer/Sanctum boundary. It reuses the database-backed `security_incidents` and `security_incident_events` domain; it does not create mobile-only persistence.

## Base path

```text
/api/security/incidents
```

Authentication:

```http
Authorization: Bearer <Sanctum token>
Accept: application/json
```

Read requires active authenticated Security user + `security-management:read`. Create requires `security-management:create`. Status/note mutations require `security-management:update`.

## Routes

```text
GET  /api/security/incidents/dashboard
GET  /api/security/incidents
POST /api/security/incidents
GET  /api/security/incidents/history
GET  /api/security/incidents/{incidentId}
POST /api/security/incidents/{incidentId}/acknowledge
POST /api/security/incidents/{incidentId}/start
POST /api/security/incidents/{incidentId}/resolve
POST /api/security/incidents/{incidentId}/notes
```

## Property / authorization boundary

Incident Mobile API does **not** use the web `CurrentProperty` session selector.

Accessible property scope is derived server-side from:

```text
authenticated active Security user
+ explicit property_user assignment (admin may inspect active properties)
+ active property
+ effective security-management entitlement
```

Reads never trust a client-supplied property as an authorization override. Cross-property incident detail/action fails closed as `404 INCIDENT_NOT_FOUND`.

For **new standalone Incident reports**:

- if the user has exactly one accessible Security property, `property_id` may be omitted and backend selects it;
- if the user has multiple accessible Security properties, `property_id` is required and must be one of those accessible properties;
- if `patrol_checkpoint_visit_id` is supplied, property is derived from that patrol checkpoint and any supplied `property_id` must match it.

This is a routing/context selector only; it cannot widen authorization.

## Canonical Incident statuses

Exact JSON values:

```text
Open
Acknowledged
In Progress
Resolved
Closed
Cancelled
```

Mobile V1 lifecycle mutations intentionally expose only:

```text
Open -> Acknowledged
Open -> In Progress
Acknowledged -> In Progress
Acknowledged -> Resolved
In Progress -> Resolved
```

`Closed`, `Cancelled`, assignment changes, and administrative reopening remain web/admin responsibilities in V1.

## Canonical severities

```text
Low
Medium
High
Critical
```

## Response envelope

Success:

```json
{
  "status": "success",
  "message": "Incident loaded.",
  "data": {}
}
```

Paginated lists also include:

```json
{
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 1,
    "from": 1,
    "to": 1,
    "count": 1,
    "has_more": false,
    "sort": "reported_at_desc,id_desc"
  }
}
```

Error:

```json
{
  "status": "error",
  "code": "INCIDENT_NOT_FOUND",
  "message": "Incident tidak ditemukan.",
  "errors": {}
}
```

## Incident payload

Summary and detail use the same core shape. Detail additionally includes `timeline`.

```json
{
  "incident_id": 91,
  "incident_number": "INC-20260812-000091",
  "property": {
    "id": 3,
    "code": "APT-A",
    "name": "Aparthub Residence"
  },
  "patrol_context": {
    "checkpoint_visit_id": 14,
    "patrol_session_id": 8,
    "session_number": "PAT-20260812-000008",
    "checkpoint_id": 5,
    "checkpoint_name": "Parking Gate",
    "checkpoint_location": "B1"
  },
  "reported_by": {"id": 22, "name": "Security Officer"},
  "assigned_to": null,
  "category": "Safety",
  "severity": "High",
  "status": "Open",
  "title": "Emergency exit obstructed",
  "description": "Boxes block the emergency exit.",
  "location": "East Emergency Exit",
  "reported_at": "2026-08-12T22:15:00+07:00",
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

Nullability:

- `property`: expected non-null for valid persisted Incident;
- `patrol_context`: nullable for standalone reports;
- `reported_by`: nullable only for legacy/system-origin records whose reporter was removed;
- `assigned_to`: nullable;
- `location`: nullable;
- lifecycle timestamps are nullable until reached;
- `escalated_at`: nullable;
- `resolution_notes`: nullable until resolved.

Timestamps are ISO-8601 with configured application timezone offset, e.g. `+07:00` for Asia/Jakarta.

## Create Incident

```http
POST /api/security/incidents
```

Body:

```json
{
  "property_id": 3,
  "patrol_checkpoint_visit_id": null,
  "title": "Emergency exit obstructed",
  "description": "Boxes block the emergency exit.",
  "category": "Safety",
  "severity": "High",
  "location": "East Emergency Exit"
}
```

`property_id` and `patrol_checkpoint_visit_id` are nullable subject to the scope rules above.

Backend is authoritative for:

```text
incident_number
reported_by_user_id
reported_at
status = Open
all lifecycle timestamps
system audit event
incident timeline event
```

Client cannot submit `reported_at`, `assigned_to_user_id`, lifecycle timestamps, escalation level, or status.

Success: HTTP `201`.

## Create Incident from Patrol checkpoint

When `patrol_checkpoint_visit_id` is provided:

- checkpoint must belong to the authenticated officer's accessible property;
- patrol session must be `In Progress`;
- checkpoint visit must still be `Pending`;
- backend changes the checkpoint to exact status `Issue`;
- backend sets checkpoint `checked_at` and actor;
- Incident stores `patrol_checkpoint_visit_id`.

No QR/NFC/RFID/GPS/device proof is required or implied by this contract.

## List

```http
GET /api/security/incidents
```

Query:

```text
scope=mine|assigned|reported|all   default mine
status=<canonical status>
severity=Low|Medium|High|Critical
q=<incident number/title/description/location/category>
per_page=1..100                    default 20
page=<Laravel page>
```

`mine` means `reported_by == current user OR assigned_to == current user`.

Default sort:

```text
reported_at DESC, id DESC
```

## Dashboard

```http
GET /api/security/incidents/dashboard
```

Data:

```json
{
  "open": 3,
  "critical": 1,
  "escalated": 1,
  "assigned_to_me": 1,
  "reported_by_me": 4,
  "resolved_today": 2
}
```

Counts are authorization/property scoped. `open` means `Open`, `Acknowledged`, or `In Progress`.

## Detail / Timeline

```http
GET /api/security/incidents/{incidentId}
```

Detail adds:

```json
{
  "timeline": [
    {
      "event_id": 201,
      "event": "status_changed",
      "from_status": "Open",
      "to_status": "Acknowledged",
      "notes": "Acknowledged by front desk.",
      "metadata": {"source": "security_mobile"},
      "actor": {"id": 22, "name": "Security Officer"},
      "created_at": "2026-08-12T22:16:00+07:00"
    }
  ]
}
```

Newest event first.

## Acknowledge

```http
POST /api/security/incidents/{incidentId}/acknowledge
```

Optional body:

```json
{"notes":"Acknowledged by front desk."}
```

Backend sets `acknowledged_at` on first transition.

## Start handling

```http
POST /api/security/incidents/{incidentId}/start
```

Optional body:

```json
{"notes":"Checking the location."}
```

Valid from `Open` or `Acknowledged`.

## Resolve

```http
POST /api/security/incidents/{incidentId}/resolve
```

Required body:

```json
{"notes":"Hazard removed and area secured."}
```

Backend sets `resolved_at` and `resolution_notes`.

## Add note

```http
POST /api/security/incidents/{incidentId}/notes
```

Required body:

```json
{"notes":"CCTV footage secured."}
```

Notes are timeline events; Incident core description is not overwritten.

## History

```http
GET /api/security/incidents/history
```

Same `scope`, `severity`, `q`, pagination semantics as list. `status` is restricted to:

```text
Resolved
Closed
Cancelled
```

Default sort:

```text
updated_at DESC, id DESC
```

## Stable error codes

| HTTP | Code | Meaning |
|---:|---|---|
| 401 | `UNAUTHENTICATED` | Missing/invalid/revoked token |
| 403 | `FORBIDDEN` | Authenticated but missing required permission / inaccessible selected property |
| 404 | `INCIDENT_NOT_FOUND` | Missing or hidden by property/entitlement boundary |
| 404 | `PATROL_CHECKPOINT_NOT_FOUND` | Linked checkpoint missing/not owned/not accessible |
| 409 | `PATROL_NOT_IN_PROGRESS` | Linked Patrol is not running |
| 409 | `PATROL_CHECKPOINT_ALREADY_PROCESSED` | Linked checkpoint is no longer Pending |
| 409 | `INCIDENT_ALREADY_ACKNOWLEDGED` | Duplicate acknowledge |
| 409 | `INCIDENT_ALREADY_IN_PROGRESS` | Duplicate start |
| 409 | `INCIDENT_ALREADY_RESOLVED` | Incident already resolved |
| 409 | `INCIDENT_CLOSED` | Incident administratively closed |
| 409 | `INCIDENT_CANCELLED` | Incident administratively cancelled |
| 409 | `INCIDENT_INVALID_STATE` | Transition/action invalid for current state |
| 422 | `VALIDATION_ERROR` | Invalid/missing input |
| 500 | `SERVER_ERROR` | Unexpected backend error |

## Explicit exclusions / HOLD

APH.32 does **not** implement or imply:

```text
Emergency Response dispatch
panic button hardware
CCTV/NVR integration
Access Control hardware
ANPR/LPR/barrier integration
RFID/NFC/BLE/device registry
GPS proof
incident photo/video upload
push/WhatsApp/SMS dispatch
```

Existing automatic High/Critical escalation remains a backend/web operational capability; the mobile app only receives persisted `escalation_level`/`escalated_at`.
