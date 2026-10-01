# Aparthub Mobile Localization Handoff — APH.35C

## Purpose

This document is the localization handoff for:

- Resident Mobile;
- Technician Mobile;
- Security Mobile.

Supported locales:

```text
id
en
```

Backend API fallback locale:

```text
en
```

## Request / Response Contract

Mobile clients should send:

```http
Accept-Language: id
```

or:

```http
Accept-Language: en
```

Regional forms such as `id-ID` and `en-US` are normalized to `id` and `en`.

The backend returns:

```http
Content-Language: id
```

or:

```http
Content-Language: en
```

on normal and exception-rendered API responses.

Unsupported or absent API locale falls back to:

```text
en
```

## Critical Wire Rule

Never translate or mutate these values in transport/business logic:

```text
IDs
tokens
route/field names
module/permission slugs
canonical statuses
canonical priorities/severities
completion_mode
stable Security error codes
```

Examples that remain exact:

```text
Checked In
In Progress
Submitted for QC
Resolved
submitted_for_qc
qc_approved
technician_direct
VISITOR_ALREADY_CHECKED_IN
PATROL_NOT_FOUND
INCIDENT_INVALID_STATE
UNAUTHENTICATED
FORBIDDEN
VALIDATION_ERROR
```

Localization is display-only.

## Human API Messages

Backend-owned `message` and validation error text are localized according to `Accept-Language`.

Example, same Security error code:

```http
Accept-Language: id
```

```json
{
  "status": "error",
  "code": "VISITOR_ALREADY_CHECKED_IN",
  "message": "Visitor sudah check-in.",
  "errors": {}
}
```

```http
Accept-Language: en
```

```json
{
  "status": "error",
  "code": "VISITOR_ALREADY_CHECKED_IN",
  "message": "Visitor has already checked in.",
  "errors": {}
}
```

The client must branch on:

```text
code / status / canonical domain field
```

not on:

```text
message
```

## Validation

Laravel validation messages now have `id` and `en` catalogs.

Example:

```http
Accept-Language: id
POST /api/security/login
{}
```

```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "Data yang diberikan tidak valid.",
  "errors": {
    "username": [
      "Kolom nama pengguna wajib diisi."
    ],
    "password": [
      "Kolom kata sandi wajib diisi."
    ]
  }
}
```

English keeps the same envelope and code with English human text.

## Flutter Responsibility

Each Flutter app should own its UI strings through client localization resources.

Recommended pattern:

```text
canonical API value
        |
        v
client mapping key
        |
   +----+----+
   |         |
  id        en
```

Do not store translated labels as domain state.

Recommended client flow:

```dart
final status = api.status; // e.g. "Checked In"
final label = l10n.statusLabel(status);
```

Do not implement:

```dart
if (api.message == 'Visitor sudah check-in.') { ... }
```

Use:

```dart
if (api.code == 'VISITOR_ALREADY_CHECKED_IN') { ... }
```

## Machine-Readable Catalog

Use:

```text
docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json
```

It contains bilingual display mappings for:

- Visitor;
- Service Request priority/status;
- Work Order status;
- Work Order completion mode;
- Facility and Facility Booking;
- Billing invoice state;
- Payment Gateway state;
- Marketplace Order;
- Patrol Session;
- Patrol Checkpoint;
- Incident severity/status;
- Security stable error codes.

The JSON keys are canonical wire values. Do not replace those keys with translated strings.

## Resident Mobile

Backend-localized human messages cover the currently active Resident APIs including:

```text
authentication
profile photo
service request
visitor
facility / booking
billing
payment gateway
marketplace
validation
```

Resident UI must still localize canonical values client-side.

## Technician Mobile

Backend-localized human messages cover:

```text
authentication
profile update
service request actions
work order actions
schedule/dashboard
validation and evidence errors
```

Keep these completion modes exact:

```text
submitted_for_qc
qc_approved
technician_direct
```

Keep Work Order statuses exact.

## Security Mobile

Security API retains its V1 error-code contract.

Backend localizes:

```text
success message
error message
validation message
validation field errors
QR validation reason
```

The following remain canonical:

```text
status
code
visitor status
patrol status
checkpoint status
incident status
incident severity
```

## Client Rollout Rule

A mobile team may adopt the bilingual UI independently, but it must:

1. send the selected locale in `Accept-Language`;
2. treat `Content-Language` as the backend response language;
3. use canonical values for logic;
4. map canonical values to client-localized display labels;
5. treat backend `message` as display/helper copy only.

## APH.35C Boundary

APH.35C does not:

- rename API fields;
- rename persisted status values;
- introduce translated DB status values;
- introduce new Security error codes;
- change auth/token semantics;
- change route paths;
- change Resident/Technician/Security workflow state machines.
