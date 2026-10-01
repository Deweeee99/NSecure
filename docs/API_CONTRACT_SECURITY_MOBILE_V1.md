# Aparthub Security Mobile API V1 — Visitor Verification Final Handoff

## Status

**Contract state:** `FINAL FOR SEC.7 INTEGRATION — runtime patch pending local regression`

**Backend checkpoint:** `APH.30D — Security Visitor Verification API Contract Finalization`

This document is the source of truth for the Flutter Security Mobile **Visitor Verification** integration. Do not infer Patrol, Incident, Emergency, Access Control, Vehicle, or hardware APIs from this contract.

---

## 1. Base API and versioning

Current route prefix:

```text
/api/security
```

There is **no `/v1` segment in the URL**. The contract version is named **Security Mobile API V1** in documentation while retaining the existing `/api/security/...` routes.

Example production base:

```text
https://<host>/api/security
```

The Flutter application should keep the host configurable and append the paths in this document.

---

## 2. Canonical response envelopes

### Success

```json
{
  "status": "success",
  "message": "Visitor loaded.",
  "data": {}
}
```

A list endpoint may also include `meta`:

```json
{
  "status": "success",
  "message": "Verification history loaded.",
  "data": [],
  "meta": {}
}
```

### Error

```json
{
  "status": "error",
  "code": "VISITOR_ALREADY_CHECKED_IN",
  "message": "Visitor sudah check-in.",
  "errors": {}
}
```

Validation errors use the same envelope and place field errors under `errors`:

```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "The given data was invalid.",
  "errors": {
    "q": ["The q field is required."]
  }
}
```

QR validation failures may additionally include a safe `data` object with `is_valid: false` and the resolved Visitor payload when the Visitor is known.

---

## 3. Authentication

Authentication uses **Laravel Sanctum personal access tokens**.

Authorization header after login:

```http
Authorization: Bearer <token>
Accept: application/json
```

### 3.1 Login

```text
POST /api/security/login
```

Request:

```json
{
  "username": "security.frontdesk",
  "password": "secret-pass"
}
```

Successful response:

```json
{
  "status": "success",
  "message": "Login security berhasil.",
  "data": {
    "id": 12,
    "name": "Front Desk Security",
    "username": "security.frontdesk",
    "role": "Security",
    "is_active": true,
    "default_property": {
      "id": 1,
      "code": "SITE-A",
      "name": "Aparthub SITE-A",
      "is_default": true
    },
    "properties": [
      {
        "id": 1,
        "code": "SITE-A",
        "name": "Aparthub SITE-A",
        "is_default": true
      }
    ],
    "security_profile": null,
    "token": "1|...",
    "token_type": "Bearer"
  }
}
```

Token location:

```text
data.token
```

Invalid/inactive/not-permitted user:

```http
401 Unauthorized
```

```json
{
  "status": "error",
  "code": "SECURITY_INVALID_CREDENTIALS",
  "message": "Kredensial security tidak valid.",
  "errors": {}
}
```

Login requires:

- active `users.is_active`;
- valid username/password;
- effective `security-management:read` user permission.

Login is rate-limited by `security-login`.

### 3.2 Current Security user

```text
GET /api/security/me
```

Success uses the same profile object as login, excluding `token` and `token_type`.

`security_profile` is intentionally `null`; no dedicated Security Officer profile/master is being fabricated for this MVP.

### 3.3 Logout

```text
POST /api/security/logout
```

Only the current Sanctum token is revoked.

Successful response:

```json
{
  "status": "success",
  "message": "Logout security berhasil.",
  "data": null
}
```

### 3.4 Token errors

Missing/invalid/revoked token:

```http
401 Unauthorized
```

```json
{
  "status": "error",
  "code": "UNAUTHENTICATED",
  "message": "Unauthenticated.",
  "errors": {}
}
```

Authenticated but inactive or lacking Security read permission:

```http
403 Forbidden
```

```json
{
  "status": "error",
  "code": "FORBIDDEN",
  "message": "Forbidden.",
  "errors": {}
}
```

---

## 4. Visitor identifiers

The backend currently stores one `visitors` row per visit. There is no separate Visitor-person master record.

Canonical fields exposed to Flutter:

```text
visit_id     integer   canonical database visit identifier
visit_code   string    non-sensitive human-readable/manual reference, prefix VST-
visitor_id   integer   compatibility alias of visit_id in Security Mobile V1
```

Therefore in V1:

```text
visit_id == visitor_id
```

Clients should use:

- `visit_id` for API path parameters;
- `visit_code` for manual front-desk lookup/display;
- `visitor_id` only as a compatibility field if existing Flutter models already expect it.

`visit_code` is **not** the QR credential.

---

## 5. Visitor Search

```text
GET /api/security/visitors/search?q={query}&limit=20
```

Parameters:

| Field | Type | Required | Rule |
|---|---|---:|---|
| `q` | string | yes | max 255 |
| `limit` | integer | no | 1–50, default 20 |

A single `q` supports:

- exact `visit_code`;
- exact numeric `visit_id` / `visitor_id`;
- exact canonical QR/access code when pasted manually;
- visitor name contains;
- visitor phone contains;
- resident name contains;
- unit code contains.

The canonical QR/access code is searchable but is **never returned** in search/detail payloads.

Empty result:

```json
{
  "status": "success",
  "message": "Visitor search completed.",
  "data": [],
  "meta": {
    "count": 0,
    "limit": 20
  }
}
```

Search is automatically scoped by authenticated Security user property access + active property + effective `security-management` entitlement. Mobile must not send `property_id` or `tower_id` to establish authorization scope.

---

## 6. QR Visitor Verification

```text
POST /api/security/visitor-access/validate
```

Request:

```json
{
  "code": "CANONICAL_QR_PAYLOAD"
}
```

### QR payload format

The Resident API returns:

```text
qr_payload == access_code
```

Flutter/Resident encodes `qr_payload` into the QR image **exactly as received**.

Security Flutter sends the scanned raw payload as `code` without:

- JSON wrapping;
- URL prefix;
- base64 conversion;
- trimming/case normalization;
- local checksum or regeneration.

The QR credential is an opaque bearer credential and is distinct from `visit_code`.

### Valid QR response

```http
200 OK
```

```json
{
  "status": "success",
  "message": "Visitor QR valid.",
  "data": {
    "is_valid": true,
    "reason": null,
    "visit_id": 123,
    "visit_code": "VST-01K...",
    "visitor_id": 123,
    "visitor_name": "Budi",
    "status": "Approved"
  }
}
```

QR validation is read-only. It does **not** check the Visitor in.

A QR is valid only when the backend says all of these are true:

- exact credential match;
- status is `Approved`;
- current server date equals `visit_date`;
- `valid_until`/`expires_at` exists and has not passed.

Unknown, inaccessible, or non-matching QR returns a fail-closed response without revealing whether the credential exists in another property:

```http
404 Not Found
```

```json
{
  "status": "error",
  "code": "VISITOR_QR_INVALID",
  "message": "QR / kode akses visitor tidak valid.",
  "errors": {},
  "data": {
    "is_valid": false,
    "reason": "Visitor tidak ditemukan atau tidak dapat diakses."
  }
}
```

Known but currently invalid Visitor states return `422` with a stable code and safe resolved Visitor data.

---

## 7. Visitor Detail

```text
GET /api/security/visitors/{visitId}
```

Path parameter is the numeric `visit_id`.

Cross-property/non-entitled/missing visits fail closed as `404 VISITOR_NOT_FOUND`.

### Canonical Visitor payload

```json
{
  "status": "success",
  "message": "Visitor loaded.",
  "data": {
    "visit_id": 123,
    "visit_code": "VST-01K...",
    "visitor_id": 123,
    "visitor_name": "Budi Santoso",
    "visitor_phone": "081234567890",
    "resident_name": "Andi Pratama",
    "property_name": "Aparthub Residence",
    "tower_name": "Tower A",
    "unit_name": "A-1205",
    "purpose": "Personal Visit",
    "scheduled_at": "2026-08-12T10:15:00+07:00",
    "valid_from": "2026-08-12T00:00:00+07:00",
    "valid_until": "2026-08-12T23:59:59+07:00",
    "status": "Approved",
    "checked_in_at": null,
    "checked_out_at": null,
    "checked_in_by": null,
    "checked_out_by": null,
    "unit": "A-1205",
    "tower": "Tower A",
    "property": {
      "id": 1,
      "code": "SITE-A",
      "name": "Aparthub Residence"
    },
    "visit_date": "2026-08-12",
    "estimated_arrival_time": "10:15:00",
    "guest_count": 1,
    "visit_purpose": "Personal Visit",
    "can_check_in": true,
    "can_check_out": false,
    "identity_photo_url": "https://<host>/api/security/visitors/123/identity-photo"
  }
}
```

### Field type / nullability

| Field | Type | Nullable | Notes |
|---|---|---:|---|
| `visit_id` | integer | no | canonical path ID |
| `visit_code` | string | no after APH.30D migration | manual reference, non-secret |
| `visitor_id` | integer | no | alias of `visit_id` in V1 |
| `visitor_name` | string | no | persisted Visitor field |
| `visitor_phone` | string | no | persisted Visitor field |
| `resident_name` | string | practically no; decoder may tolerate null for legacy data | resident relation |
| `property_name` | string | decoder should tolerate null only for pre-APH.25 legacy data | production baseline backfills property scope |
| `tower_name` | string | yes | null when resident has no unit |
| `unit_name` | string | yes | null when resident has no unit |
| `purpose` | string | no | visit purpose |
| `scheduled_at` | ISO-8601 string | yes | visit date + estimated arrival |
| `valid_from` | ISO-8601 string | yes | start of visit date in backend timezone |
| `valid_until` | ISO-8601 string | yes | expiry timestamp |
| `status` | string enum | no | canonical values below |
| `checked_in_at` | ISO-8601 string | yes | backend source of truth |
| `checked_out_at` | ISO-8601 string | yes | backend source of truth |
| `checked_in_by` | object | yes | `{id:int,name:string}`; historical rows may be null |
| `checked_out_by` | object | yes | `{id:int,name:string}`; historical rows may be null |
| `identity_photo_url` | URL string | yes | protected authenticated endpoint |

`access_code` / QR credential is intentionally absent.

---

## 8. Check-In

```text
POST /api/security/visitors/{visitId}/check-in
```

Requires `security-management:update`.

### Manual mode

```json
{
  "verification_method": "manual",
  "access_card_number": null
}
```

Manual mode requires the officer to resolve the visit through Search/Detail first. It does not bypass status/date/expiry rules.

### QR mode

```json
{
  "verification_method": "qr",
  "code": "CANONICAL_QR_PAYLOAD",
  "access_card_number": null
}
```

### Success

```http
200 OK
```

The response is the canonical Visitor payload with:

```json
{
  "status": "Checked In",
  "checked_in_at": "2026-08-12T10:20:05+07:00",
  "checked_in_by": {
    "id": 12,
    "name": "Front Desk Security"
  },
  "can_check_in": false,
  "can_check_out": true
}
```

Backend is the source of truth for both `checked_in_at` and `checked_in_by`. Flutter must use the response and must not synthesize these values locally.

Check-in runs under a DB row lock and records `security.visitor.checked_in` in `system_audit_logs`.

---

## 9. Check-Out

```text
POST /api/security/visitors/{visitId}/check-out
```

Request body may be empty.

Requires `security-management:update`.

### Success

The canonical Visitor payload returns:

```json
{
  "status": "Checked Out",
  "checked_out_at": "2026-08-12T12:05:00+07:00",
  "checked_out_by": {
    "id": 12,
    "name": "Front Desk Security"
  },
  "can_check_in": false,
  "can_check_out": false
}
```

Backend is the source of truth for both `checked_out_at` and `checked_out_by`.

Check-out runs under a DB row lock and records `security.visitor.checked_out`.

---

## 10. Verification History

```text
GET /api/security/verification-history
```

Query parameters:

| Field | Type | Required | Rule |
|---|---|---:|---|
| `page` | integer | no | min 1, default 1 |
| `per_page` | integer | no | 1–100, default 20 |
| `status` | string | no | one canonical Visitor status |
| `q` | string | no | max 255; same searchable identity fields as Visitor Search |

History includes visits that have check-in/check-out activity or terminal `Rejected`, `Cancelled`, or `Expired` state.

Default ordering:

```text
updated_at DESC, id DESC
```

Response:

```json
{
  "status": "success",
  "message": "Verification history loaded.",
  "data": [],
  "meta": {
    "current_page": 1,
    "last_page": 3,
    "per_page": 20,
    "total": 55,
    "from": 1,
    "to": 20,
    "count": 20,
    "has_more": true,
    "sort": "updated_at_desc,id_desc"
  }
}
```

This is Visitor lifecycle history, not a first-class immutable list of every failed scanner attempt. Known QR verification actions are still recorded in system audit logs.

---

## 11. Canonical Visitor status wire values

Exact JSON strings are locked as:

```text
Pending
Approved
Rejected
Checked In
Checked Out
Cancelled
Expired
```

Do **not** send/expect:

```text
checked_in
checked-in
Checked-In
```

Flutter may map the wire strings to local enum names internally, but serialization/deserialization must preserve the exact backend values.

---

## 12. Date and time contract

Backend application timezone:

```text
APP_TIMEZONE
Default: Asia/Jakarta
```

Current Security Visitor lifecycle rules use the application timezone.

Timestamp fields use ISO-8601 with timezone offset, for example:

```text
2026-08-12T10:20:05+07:00
```

Date-only field retained for compatibility:

```text
visit_date = YYYY-MM-DD
```

Time-only field retained for compatibility:

```text
estimated_arrival_time = HH:mm:ss
```

Flutter should parse ISO-8601 timestamps as instants with offset and should not append its own timezone suffix.

---

## 13. Stable Security Visitor error codes

| HTTP | Code | Meaning |
|---:|---|---|
| 401 | `SECURITY_INVALID_CREDENTIALS` | login credentials/inactive/not Security-readable |
| 401 | `UNAUTHENTICATED` | missing/invalid/revoked bearer token |
| 403 | `FORBIDDEN` | authenticated but current user/action not permitted |
| 403 | `SECURITY_PROPERTY_UNAVAILABLE` | no accessible + entitled Security property for dashboard |
| 404 | `VISITOR_NOT_FOUND` | visit ID missing or hidden by property/entitlement boundary |
| 404 | `VISITOR_QR_INVALID` | QR not resolvable inside caller's authorization boundary |
| 409 | `VISITOR_PENDING_APPROVAL` | operation conflicts with Pending state |
| 409 | `VISITOR_REJECTED` | operation conflicts with Rejected state |
| 409 | `VISITOR_CANCELLED` | operation conflicts with Cancelled state |
| 409 | `VISITOR_ALREADY_CHECKED_IN` | duplicate check-in / state conflict |
| 409 | `VISITOR_ALREADY_CHECKED_OUT` | duplicate check-out / closed visit |
| 409 | `VISITOR_INVALID_STATE` | lifecycle transition is not allowed |
| 422 | `VISITOR_EXPIRED` | visit/credential expired for entry |
| 422 | `VISITOR_NOT_VALID_TODAY` | Approved visit is not on today's visit date |
| 422 | `VISITOR_QR_INVALID` | QR payload supplied for known visit does not match |
| 422 | `VALIDATION_ERROR` | malformed/missing request fields |
| 404 | `RESOURCE_NOT_FOUND` | non-Visitor Security route/resource missing |
| 500 | `SERVER_ERROR` | unexpected backend failure |

For QR verification of a known Visitor in a terminal/non-entry state, the API returns the state-specific code with `data.is_valid = false`.

---

## 14. Authorization / operational scope

Read operations require:

```text
active User
+ security-management:read
+ accessible active Property
+ effective security-management Property entitlement
```

Check-In and Check-Out additionally require:

```text
security-management:update
```

Property scope is derived entirely from the authenticated User and backend property assignments/entitlements.

Flutter must **not** send `property_id` or `tower_id` as an authorization selector.

Current Security authorization boundary is property-level, not tower-level. `tower_name` is visit context only.

Cross-property access fails closed as `404` where Visitor existence could otherwise be disclosed.

Admin users retain the existing backend admin permission bypass semantics but still operate only on active/effectively entitled Security properties through the Security service boundary.

---

## 15. Optional protected identity photo

```text
GET /api/security/visitors/{visitId}/identity-photo
```

Success is a **binary streamed image response**, not the JSON success envelope.

It still requires Security authentication and property authorization. Missing/inaccessible files return a Security JSON `404` error. Response is `private, no-store` and uses `X-Content-Type-Options: nosniff`.

---

## 16. Flutter SEC.7 integration lock

Frontend may now implement:

```text
ApiSecurityAuthRepository
ApiVisitorRepository
Security Bearer token session
Visitor Search
QR Validation
Visitor Detail
Check-In
Check-Out
Verification History
```

Do not implement backend calls yet for:

```text
Patrol Management
Incident Reporting
Emergency Response
Access Control
Vehicle Management
Security Device Registry / hardware integrations
```

Patrol is planned as the next Security Mobile API expansion after APH.30 final readiness and will reuse the already database-backed APH.23 Patrol domain.
