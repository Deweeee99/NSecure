# Aparthub Security Mobile API V1 — Final Platform Handoff

Status: **Platform contract current through APH.38 Security Package Receiving — regression pending for APH.38**

This is the canonical cross-module handoff for the software-only Security Mobile scope.

## Active modules

```text
Visitor Verification
Patrol Management
Incident Reporting
Emergency SOS
Package Receiving
```

Hardware-dependent modules remain out of contract until field equipment is known.

## Base & authentication

```text
Base prefix: /api/security
Auth: Laravel Sanctum Bearer token
Header: Authorization: Bearer <token>
Timezone: Asia/Jakarta
Timestamp: ISO-8601 with offset
```

Login token lives at `data.token`; `data.token_type` is exact `Bearer`.

## Canonical response envelopes

Success:

```json
{
  "status": "success",
  "message": "...",
  "data": {}
}
```

List endpoints may use `data: []`. Paginated lists additionally include:

```json
{
  "meta": {
    "current_page": 1,
    "last_page": 1,
    "per_page": 20,
    "total": 0,
    "from": null,
    "to": null,
    "count": 0,
    "has_more": false,
    "sort": "<documented sort>"
  }
}
```

Error:

```json
{
  "status": "error",
  "code": "STABLE_MACHINE_CODE",
  "message": "Human-readable message.",
  "errors": {}
}
```

Validation errors use exact `code = VALIDATION_ERROR` and field arrays under `errors`.

## Canonical property authorization boundary

All Security Mobile modules use the same server-side scope:

```text
authenticated active Security user
+ explicit property_user assignment for non-admin users
+ active property
+ effective security-management entitlement
```

The API does **not** use the web `CurrentProperty` session selector. Client-supplied `property_id` may select among already-authorized properties only where a create workflow explicitly requires context; it can never widen authorization.

## Permissions

```text
security-management:read
  auth profile, Visitor read/search/history, Patrol read, Incident read, Emergency alert/modal read, Package resident lookup/list/detail

security-management:create
  Incident report creation, Package receive/register

security-management:update
  Visitor check-in/out, Patrol execution, Incident operational mutations, Emergency acknowledge/resolve, Package collection
```

## Route families

### Visitor Verification

```text
POST /api/security/login
GET  /api/security/me
POST /api/security/logout
GET  /api/security/dashboard
POST /api/security/visitor-access/validate
GET  /api/security/visitors/search
GET  /api/security/visitors/{visitor}
POST /api/security/visitors/{visitor}/check-in
POST /api/security/visitors/{visitor}/check-out
GET  /api/security/verification-history
GET  /api/security/visitors/{visitor}/identity-photo
```

Detailed contract: `docs/API_CONTRACT_SECURITY_MOBILE_V1.md`.

### Patrol Management

```text
GET  /api/security/patrol/dashboard
GET  /api/security/patrol/sessions
GET  /api/security/patrol/sessions/{patrolSession}
POST /api/security/patrol/sessions/{patrolSession}/start
POST /api/security/patrol/sessions/{patrolSession}/complete
POST /api/security/patrol/checkpoint-visits/{visit}/complete
POST /api/security/patrol/checkpoint-visits/{visit}/skip
GET  /api/security/patrol/history
```

Detailed contract: `docs/API_CONTRACT_SECURITY_PATROL_V1.md`.

### Incident Reporting

```text
GET  /api/security/incidents/dashboard
GET  /api/security/incidents
POST /api/security/incidents
GET  /api/security/incidents/history
GET  /api/security/incidents/{incident}
POST /api/security/incidents/{incident}/acknowledge
POST /api/security/incidents/{incident}/start
POST /api/security/incidents/{incident}/resolve
POST /api/security/incidents/{incident}/notes
```

Detailed contract: `docs/API_CONTRACT_SECURITY_INCIDENT_V1.md`.

### Emergency SOS

```text
GET  /api/security/emergency-alerts/active
GET  /api/security/emergency-alerts
GET  /api/security/emergency-alerts/history
GET  /api/security/emergency-alerts/{emergencyAlert}
POST /api/security/emergency-alerts/{emergencyAlert}/acknowledge
POST /api/security/emergency-alerts/{emergencyAlert}/resolve
```

`/active` is the durable source of truth for the persistent Security emergency modal. Only canonical `Open` alerts appear there; an alert leaves the modal queue atomically when one Security user acknowledges/takes it.

Detailed contract: `docs/API_CONTRACT_EMERGENCY_SOS_V1.md`.

### Package Receiving

```text
GET  /api/security/packages/residents/search
GET  /api/security/packages
POST /api/security/packages
GET  /api/security/packages/{residentPackage}
POST /api/security/packages/{residentPackage}/collect
```

Package Receiving writes to the existing Package Center / `resident_packages` domain and additionally requires effective `package-center` property entitlement.

Detailed contract: `docs/API_CONTRACT_SECURITY_PACKAGE_V1.md`.

## Cross-module error families

Shared:

```text
SECURITY_INVALID_CREDENTIALS
UNAUTHENTICATED
FORBIDDEN
SECURITY_PROPERTY_UNAVAILABLE
VALIDATION_ERROR
RESOURCE_NOT_FOUND
SERVER_ERROR
```

Visitor-specific codes are prefixed `VISITOR_`; Patrol-specific codes are prefixed `PATROL_`; Incident-specific codes are prefixed `INCIDENT_`; Emergency-specific codes are prefixed `EMERGENCY_`; Package-specific codes are prefixed `PACKAGE_`.

Cross-property/cross-officer resource probing fails closed as module-specific `404 *_NOT_FOUND` where applicable.

## Hardware boundary

Not part of V1:

```text
Device Registry
Access-control readers/controllers
ANPR/LPR
Barrier/boom gate
RFID/NFC
Dedicated QR scanners
Panic-button hardware
CCTV/NVR integration
GPS proof-of-presence
Device telemetry
```

Patrol `scan_token` remains internal and is not exposed. Visitor QR uses the existing visitor access-code contract; it does not imply dedicated scanner hardware.

## Frontend integration rule

Flutter should map wire values exactly and must not manufacture backend-owned timestamps, actors, statuses, or property authorization.

No silent breaking change is allowed to this V1 bundle after APH.33 is locked; changes require a new documented compatibility decision/version.

---

## Localization header contract (APH.35A)

Supported request locale headers:

```http
Accept-Language: id
Accept-Language: id-ID
Accept-Language: en
Accept-Language: en-US
```

The backend normalizes these to `id` or `en` and returns the resolved locale as:

```http
Content-Language: id
```

or:

```http
Content-Language: en
```

Canonical IDs, status wire values, permission/module slugs, and machine-readable error codes are not localized. Clients must not branch business logic on translated human-readable message text.

APH.35A establishes locale negotiation. Full API message/validation localization is closed in APH.35C.

## APH.38 — Security Package Receiving → Package Center

Security Mobile now also supports package receiving through the existing Package Center domain. No Security-specific package persistence is introduced.

```text
GET  /api/security/packages/residents/search
GET  /api/security/packages
POST /api/security/packages
GET  /api/security/packages/{residentPackage}
POST /api/security/packages/{residentPackage}/collect
```

Property authorization remains the standard Security boundary and additionally requires an effective `package-center` entitlement. Receive uses `security-management:create`; collection uses `security-management:update`.

Canonical package statuses remain exact `Ready for Pickup`, `Collected`, and `Expired`. Stable package error codes are `PACKAGE_CENTER_UNAVAILABLE`, `PACKAGE_RESIDENT_NOT_FOUND`, and `PACKAGE_NOT_FOUND`.

Detailed contract: `docs/API_CONTRACT_SECURITY_PACKAGE_V1.md`.

