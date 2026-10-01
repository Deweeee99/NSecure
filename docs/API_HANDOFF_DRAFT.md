> **SUPERSEDED BY CANONICAL PLATFORM/MODULE CONTRACTS**
>
> The backend has delivered canonical Security Mobile contracts. Normative sources are `docs/API_CONTRACT_SECURITY_PLATFORM_V1.md`, `docs/API_CONTRACT_SECURITY_MOBILE_V1.md`, and `docs/API_CONTRACT_SECURITY_PATROL_V1.md` (plus Incident when SEC.10 activates it). This draft remains historical proposal context only.

# Aparthub Security Mobile — API Handoff Draft

> **DRAFT / PROPOSED FRONTEND HANDOFF CONTRACT**  
> **NOT FINAL BACKEND CONTRACT**

This document describes what the Flutter frontend needs from the future Security backend. It is a handoff specification for discussion and contract finalization, not permission to start SEC.7.

## 1. Current Scope

Active handoff scope:

```text
Authentication
Security identity
Dashboard summary
Visitor manual search
Visitor QR verification
Visitor detail
Visitor Check-In
Visitor Check-Out
Verification History
```

Out of scope until explicitly activated:

```text
Patrol Management
Incident Reporting
Emergency Response
Access Control
Vehicle Management
```

For those future modules:

**Not yet defined**  
**No active backend contract yet**

## 2. Frontend Integration Boundary

Flutter is already structured around:

```text
UI
 ↓
VisitorRepository
 ↓
MockVisitorRepository now
ApiVisitorRepository later
```

The future API repository must translate backend transport data into the existing frontend domain model and failure taxonomy.

The backend contract should not force UI widgets to consume raw JSON, HTTP status codes, or backend-specific exception strings.

## 3. Proposed Authentication Capabilities

```http
POST /security/login
GET /security/me
```

Exact base path/version prefix is **OPEN**.

Frontend needs Security identity fields equivalent to:

```text
id
name
username
postName
propertyName
active
```

### Required authority rule

Check-In/Check-Out actor identity must be derived by the backend from the authenticated Security session.

The mobile app must **not** be trusted to submit:

```text
checkedInBy
checkedOutBy
officerName
```

as authoritative audit identity.

## 4. Dashboard

Proposed capability:

```http
GET /security/dashboard
```

Current presentation needs:

```text
todayVisitors
checkedIn
checkedOut
pendingArrivals
```

Exact response envelope is **OPEN**.

Future-module cards do not require backend enablement in the current phase.

## 5. Manual Visitor Search

Proposed capability:

```http
GET /security/visitors/search?q={query}
```

Required lookup keys:

```text
Visit Code
Visitor ID
```

Examples:

```text
VST-240515-0012
VIS-000245
```

Required semantics:

- trim surrounding whitespace;
- query must not be empty;
- backend should define case sensitivity explicitly;
- no match returns an empty collection, not a fabricated record;
- multiple matches are allowed if backend search is broader than exact identifiers.

Whether resident/name/phone search is supported is **OPEN** and is not required by the current MVP.

## 6. QR Visitor Verification

Proposed capability:

```http
POST /security/visitors/verify
Content-Type: application/json
```

Proposed intent:

```json
{
  "qr_payload": "opaque-or-backend-defined-value"
}
```

Important:

- QR payload format is owned by the backend contract;
- Flutter must not assume the demo Visit Code is the production QR payload format;
- invalid/unknown QR must have a machine-readable error semantic;
- camera decoding and backend verification are separate concerns.

Exact request/response shape is **OPEN**.

## 7. Visitor Detail

Proposed capability:

```http
GET /security/visitors/{visitId}
```

`visitId` should be a stable backend identifier and must not depend on display text.

## 8. Check-In

Proposed capability:

```http
POST /security/visitors/{visitId}/check-in
```

Frontend request should not need officer name or client-generated action time.

Required backend behavior:

1. authenticate the Security user;
2. authorize the action/property context;
3. load the latest visit state;
4. reject invalid status transitions;
5. perform the mutation atomically;
6. generate authoritative Check-In timestamp;
7. derive `checkedInBy` from authenticated identity;
8. return the updated Visitor Visit representation.

Successful response must let Flutter render confirmation without inventing audit data locally.

## 9. Check-Out

Proposed capability:

```http
POST /security/visitors/{visitId}/check-out
```

Required backend behavior mirrors Check-In:

- authenticate and authorize;
- enforce latest-state transition rules;
- generate authoritative Check-Out timestamp;
- derive `checkedOutBy` from authenticated identity;
- return the updated visit.

## 10. Verification History

Proposed capability:

```http
GET /security/verification-history
```

Current frontend filter concepts:

```text
All
Checked-In
Checked-Out
Pending
Expired
```

For production data volume, backend should eventually support pagination and filter parameters. Exact names/schema are **OPEN**.

Recommended direction for final contract discussion:

```text
status
page
per_page
start
end
```

Do not implement these parameters in Flutter until backend confirms them.

## 11. Required Visitor Fields

Frontend domain model currently needs equivalents of:

```text
visitId
visitCode
visitorId
visitorName
visitorPhone
residentName
propertyName
towerName
unitName
purpose
scheduledAt
validFrom
validUntil
status
checkedInAt
checkedOutAt
checkedInBy
checkedOutBy
```

QR verification additionally needs a backend-resolvable QR payload/token, but the raw payload does not need to be returned to UI if backend policy considers it sensitive or unnecessary.

## 12. Nullability Expectations

Required nullable fields by lifecycle:

```text
checkedInAt   null before Check-In
checkedInBy   null before Check-In
checkedOutAt  null before Check-Out
checkedOutBy  null before Check-Out
```

Core identity/scheduling fields required to render a Visitor Detail screen should not silently become empty strings.

The final contract must explicitly distinguish:

```text
missing key
null
empty string
```

for required vs optional fields.

## 13. Visitor Status Contract

Frontend currently supports exactly:

```text
Pending
Approved
Checked-In
Checked-Out
Expired
Rejected
Cancelled
```

Backend may use different wire values, but they must map deterministically to these frontend states.

Before SEC.7, backend and frontend must agree on canonical wire values and case formatting.

Unknown production status must not silently map to `Approved` or any actionable state.

## 14. Action Eligibility

Frontend display rules:

| Status | Check-In | Check-Out |
|---|---:|---:|
| Pending | No | No |
| Approved | Yes | No |
| Checked-In | No | Yes |
| Checked-Out | No | No |
| Expired | No | No |
| Rejected | No | No |
| Cancelled | No | No |

Backend must enforce the same transition policy. UI visibility is never the security boundary.

## 15. Date and Time Contract

The final API must return machine-readable ISO-8601 timestamps with an explicit timezone/offset, for example:

```text
2026-08-12T11:30:00+07:00
```

or normalized UTC:

```text
2026-08-12T04:30:00Z
```

The exact policy is **OPEN**, but it must be consistent.

Rules:

- server is authoritative for Check-In/Check-Out time;
- device local time must not be accepted as authoritative audit time;
- frontend may format timestamps for display after parsing the offset-aware value.

## 16. Proposed Machine-Readable Error Semantics

Frontend repository already exposes stable failure concepts:

```text
visitNotFound
invalidQr
expiredVisit
rejectedVisit
cancelledVisit
alreadyCheckedIn
alreadyCheckedOut
invalidState
unauthorized
forbidden
unknown
```

Backend naming does not have to match Dart enum names, but final API errors must be deterministic enough for the future API repository to map them.

Suggested backend concepts:

```text
VISIT_NOT_FOUND
INVALID_QR
VISIT_EXPIRED
VISIT_REJECTED
VISIT_CANCELLED
ALREADY_CHECKED_IN
ALREADY_CHECKED_OUT
INVALID_VISIT_STATE
UNAUTHENTICATED
FORBIDDEN
```

This list is **proposed**, not final.

## 17. Proposed HTTP Status Direction

Final mapping remains backend-owned, but a conventional direction is:

```text
200 / 201  success
401        unauthenticated
403        forbidden
404        visit not found
409        state conflict / already checked in/out
422        invalid QR / validation error
5xx        server failure
```

Flutter must still branch on machine-readable application semantics after transport mapping, not status code alone.

## 18. Proposed Success/Error Envelope

The final envelope is **OPEN**.

One acceptable direction would be:

```json
{
  "message": "Visitor checked in",
  "data": {
    "visit_id": "VISIT-000245"
  }
}
```

Error direction:

```json
{
  "message": "Visitor cannot be checked in",
  "code": "VISIT_EXPIRED",
  "errors": null
}
```

The exact envelope must be finalized before writing `ApiVisitorRepository`.

## 19. Data Naming / Mapping

Frontend uses Dart-style camelCase domain fields. Backend may return snake_case.

Example mapping direction:

```text
visit_id       → visitId
visit_code     → visitCode
visitor_id     → visitorId
scheduled_at   → scheduledAt
valid_from     → validFrom
valid_until    → validUntil
checked_in_at  → checkedInAt
checked_out_at → checkedOutAt
checked_in_by  → checkedInBy
checked_out_by → checkedOutBy
```

Transport mapping belongs in the future data/API layer, not in widgets.

## 20. Security / Audit Requirements for Handoff

Before production integration, backend should confirm:

- Security user authentication mechanism;
- property/site authorization scope;
- Check-In/Check-Out audit identity;
- authoritative server timestamps;
- duplicate-action/concurrency handling;
- whether QR payload is sensitive and whether it expires;
- whether history records are immutable/auditable;
- no sensitive internal fields are exposed unnecessarily.

## 21. SEC.7 Entry Checklist

Do **not** start real integration until these are resolved:

```text
[ ] Base API URL / version path
[ ] Authentication mechanism
[ ] Login request/response
[ ] GET /me response
[ ] Dashboard response
[ ] Visitor search request/response
[ ] QR verify request/response
[ ] Visitor detail response
[ ] Check-In request/response
[ ] Check-Out request/response
[ ] History filters/pagination
[ ] Visitor status wire values
[ ] Error envelope + machine-readable codes
[ ] Date/time timezone semantics
[ ] Authorization/forbidden behavior
[ ] QR payload semantics
```

Until then:

```text
AppDependencies.mock()
→ MockVisitorRepository
```

remains the only supported runtime composition.
