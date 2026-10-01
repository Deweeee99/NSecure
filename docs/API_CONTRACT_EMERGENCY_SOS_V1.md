# Aparthub Emergency SOS API V1 — Resident → Security

Status: **APH.37 implementation — regression pending**

## Purpose

Resident Mobile can trigger a software-only SOS alert. Security Mobile must keep showing an emergency modal/popup while the alert is still `Open`. The alert stops being part of the modal queue only after one authorized Security user takes/responds to it through the acknowledge endpoint.

This contract intentionally has **no dependency on panic-button hardware, GPS, CCTV, push provider, or external alarm devices**.

## Canonical lifecycle

```text
Open
  ↓ acknowledge / take
Acknowledged
  ↓ resolve
Resolved
```

These status values are canonical wire/database values and are never translated.

## Authentication / scope

Resident endpoints:

```text
Sanctum Resident token
+ active Resident
+ active Resident property
+ effective security-management entitlement on that property
```

Security endpoints:

```text
Sanctum Security token
+ active User
+ security-management:read
+ explicit authorized Security property scope
+ effective security-management entitlement
```

Security mutations additionally require:

```text
security-management:update
```

## Resident endpoints

### Trigger SOS

```http
POST /api/resident/emergency/sos
Authorization: Bearer <resident-token>
Accept-Language: id|en
Content-Type: application/json
```

Optional body:

```json
{
  "message": "Butuh bantuan segera."
}
```

Rules:

- The backend derives `property_id`, `resident_id`, and `unit_id` from the authenticated Resident.
- The client must not choose another property/unit.
- If the Resident already has an unresolved SOS (`Open` or `Acknowledged`), repeated taps return that existing alert instead of creating duplicates.
- A new alert returns HTTP `201`; an already-active alert returns HTTP `200`.

### Current SOS

```http
GET /api/resident/emergency/current
```

Returns the Resident's latest unresolved SOS, including acknowledgement state. `data = null` means there is no unresolved SOS.

### SOS history

```http
GET /api/resident/emergency/history?per_page=20
```

Returns resolved SOS history for the authenticated Resident/property.

## Security endpoints

### Persistent modal queue

```http
GET /api/security/emergency-alerts/active
```

This is the **source of truth for the Security emergency modal/popup**.

Response meta:

```json
{
  "meta": {
    "count": 1,
    "modal_required": true,
    "sort": "triggered_at_asc,id_asc"
  }
}
```

Only `Open` SOS alerts appear here.

Flutter Security behavior:

```text
app launch / login / resume
        ↓
GET /api/security/emergency-alerts/active
        ↓
meta.modal_required == true
        ↓
show SOS modal
        ↓
keep refreshing active alerts while app is active
        ↓
modal remains while alert remains Open
```

Do not rely on a one-shot local notification as the source of truth. The backend state is durable, so reopening the app must show an unresolved `Open` SOS again.

APH.37 does not introduce a push provider. The client may poll this endpoint at a practical foreground cadence and should refresh immediately on app resume and after an acknowledge attempt.

### Unresolved operational list

```http
GET /api/security/emergency-alerts?per_page=30
```

Returns `Open` + `Acknowledged` alerts in the Security user's authorized properties.

### History

```http
GET /api/security/emergency-alerts/history?per_page=30
```

Returns `Resolved` alerts.

### Detail

```http
GET /api/security/emergency-alerts/{emergencyAlert}
```

Cross-property probing fails closed with `404 EMERGENCY_ALERT_NOT_FOUND`.

### Take / acknowledge

```http
POST /api/security/emergency-alerts/{emergencyAlert}/acknowledge
```

Atomic ownership rules:

- First authorized Security user wins the row lock and becomes `acknowledged_by`.
- After acknowledgement, status becomes `Acknowledged` and the alert leaves `/active` for all Security clients.
- Repeating acknowledge by the same Security user is idempotent and returns the current alert.
- Another Security user receives `409 EMERGENCY_ALREADY_TAKEN`.

### Resolve

```http
POST /api/security/emergency-alerts/{emergencyAlert}/resolve
```

Optional body:

```json
{
  "notes": "Resident sudah aman."
}
```

Rules:

- The alert must already be `Acknowledged`.
- Only the Security user who took the alert may resolve it.
- Another Security user receives `409 EMERGENCY_ASSIGNED_TO_OTHER`.
- Resolved alerts move to history and no longer appear in Resident `current`.

## Payload shape

Representative Security payload:

```json
{
  "emergency_alert_id": 12,
  "alert_code": "SOS-20260814-000012",
  "status": "Open",
  "message": "Butuh bantuan segera.",
  "modal_required": true,
  "taken_by_me": false,
  "property": {
    "id": 1,
    "code": "DEFAULT",
    "name": "Aparthub Residence"
  },
  "resident": {
    "id": 101,
    "name": "Budi Santoso",
    "mobile_no": "0812..."
  },
  "unit": {
    "id": 44,
    "code": "A-101",
    "tower": "Tower A",
    "floor": 1
  },
  "triggered_at": "2026-08-14T13:15:00+07:00",
  "acknowledged_at": null,
  "acknowledged_by": null,
  "resolved_at": null,
  "resolved_by": null,
  "resolution_notes": null
}
```

Backend owns all timestamps and ownership fields.

## Stable Security error codes

```text
EMERGENCY_ALERT_NOT_FOUND
EMERGENCY_ALREADY_TAKEN
EMERGENCY_ALREADY_RESOLVED
EMERGENCY_NOT_ACKNOWLEDGED
EMERGENCY_ASSIGNED_TO_OTHER
VALIDATION_ERROR
UNAUTHENTICATED
FORBIDDEN
SERVER_ERROR
```

Security Flutter must branch on `code`, not localized `message`.

## Localization

Request:

```http
Accept-Language: id
```

or:

```http
Accept-Language: en
```

Response includes resolved `Content-Language`.

Human-readable `message` text may change language. Canonical status and stable error code remain exact.

## Audit

Durable audit events:

```text
security.emergency.sos.triggered
security.emergency.sos.acknowledged
security.emergency.sos.resolved
```

The trigger audit records the Resident ID in metadata. Security acknowledgement/resolution records the Security `user_id`.

## Explicitly out of APH.37

```text
panic-button hardware
GPS proof / location capture
CCTV / NVR automation
external siren / alarm panel
Firebase/APNs push integration
automatic Incident creation
automatic Service Request creation
package receiving
```

Package receiving is planned separately in APH.38 and must reuse Package Center as source of truth.
