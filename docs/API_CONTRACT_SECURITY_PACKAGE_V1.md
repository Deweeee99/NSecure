# Aparthub Security Package Receiving API V1

Status: **APH.38 implementation contract — regression pending**

## Purpose

Security Mobile is an additional operational input channel for the existing Package Center domain.

There is **no Security-specific package table**. All mutations write directly to the existing:

```text
resident_packages
```

Web Admin Package Center and Resident Mobile therefore read the same durable record.

## Base / auth

```text
Base prefix: /api/security
Auth: Laravel Sanctum Bearer token
Security boundary: security.api + SecurityPropertyScope
```

Package availability additionally requires an effective `package-center` entitlement on the assigned Security property.

The mobile API does not use web `CurrentProperty`.

## Routes

```text
GET  /api/security/packages/residents/search
GET  /api/security/packages
POST /api/security/packages
GET  /api/security/packages/{residentPackage}
POST /api/security/packages/{residentPackage}/collect
```

Resident read-only visibility:

```text
GET /api/resident/packages
GET /api/resident/packages/{residentPackage}
```

## Security permissions

```text
security-management:read
  resident lookup, package list, package detail

security-management:create
  receive/register package

security-management:update
  mark package collected
```

Security users do not need a separate web `package-center` UserModule grant. `package-center` is enforced as a **property entitlement**, while Security Mobile actions remain governed by Security permissions.

## Resident search

```http
GET /api/security/packages/residents/search?q=John&property_id=12&limit=30
```

Parameters:

- `q` optional, max 120; searches resident name/mobile/email and unit code/tower;
- `property_id` optional and may only select an already-authorized Security property with Package Center enabled;
- `limit` optional, 1–50, default 30.

Only active Residents (`Aktif` / `Active`) are returned.

Response item includes resident, property, and current unit context.

## Receive package

```http
POST /api/security/packages
Content-Type: application/json
```

Request:

```json
{
  "resident_id": 101,
  "courier_name": "JNE",
  "tracking_number": "JNE-123456",
  "sender_name": "Marketplace Seller",
  "package_description": "Medium box",
  "storage_location": "Lobby Rack A",
  "notes": "Handle with care"
}
```

Required:

```text
resident_id
courier_name
```

Server-owned fields:

```text
package_no
property_id
unit_id
received_by_user_id
received_at
status = Ready for Pickup
```

The backend resolves `property_id` and `unit_id` from the selected Resident and verifies that the Security user can access that property and that Package Center is enabled there.

The client must not submit or manufacture `received_at`, `status`, or actor IDs.

Successful receive returns HTTP `201` and writes audit event:

```text
package.registered
metadata.source = security-mobile
```

## Package list / detail

```http
GET /api/security/packages?status=Ready%20for%20Pickup&search=JNE&property_id=12&per_page=30
GET /api/security/packages/{residentPackage}
```

Canonical statuses are exact:

```text
Ready for Pickup
Collected
Expired
```

They must not be localized on the wire.

When `expires_at` has passed, due `Ready for Pickup` records are normalized to canonical `Expired` before they are returned.

## Collect package

```http
POST /api/security/packages/{residentPackage}/collect
```

Optional request:

```json
{
  "collection_notes": "Collected by resident at lobby."
}
```

The transition writes:

```text
status = Collected
collected_by_user_id = authenticated Security user
collected_at = server timestamp
collection_notes = optional
```

The operation is idempotent: repeating collection on an already-collected package returns the same durable state and does not duplicate the `package.collected` audit event.

## Package payload

Representative payload:

```json
{
  "package_id": 55,
  "package_no": "PKG-260814-AB12CD34",
  "status": "Ready for Pickup",
  "courier_name": "JNE",
  "tracking_number": "JNE-123456",
  "sender_name": "Marketplace Seller",
  "package_description": "Medium box",
  "storage_location": "Lobby Rack A",
  "notes": "Handle with care",
  "collection_notes": null,
  "property": {
    "id": 1,
    "code": "APT-01",
    "name": "Aparthub Residence"
  },
  "resident": {
    "id": 101,
    "name": "Resident Name",
    "email": "resident@example.com",
    "mobile_no": "0812...",
    "property": {},
    "unit": {}
  },
  "unit": {
    "id": 20,
    "code": "A-1201",
    "tower": "Tower A",
    "floor": 12
  },
  "received_by": {
    "id": 9,
    "name": "Security Officer"
  },
  "collected_by": null,
  "received_at": "2026-08-14T13:30:00+07:00",
  "notified_at": null,
  "collected_at": null,
  "expires_at": null
}
```

## Stable Security error codes

```text
PACKAGE_CENTER_UNAVAILABLE
PACKAGE_RESIDENT_NOT_FOUND
PACKAGE_NOT_FOUND
VALIDATION_ERROR
FORBIDDEN
UNAUTHENTICATED
```

Client logic must branch on `code`, never on localized `message`.

Cross-property probing intentionally collapses to `PACKAGE_NOT_FOUND` / `PACKAGE_RESIDENT_NOT_FOUND` rather than disclosing existence.

## Localization

`Accept-Language: id|en` localizes human `message` and validation text. `Content-Language` returns the resolved locale.

These remain exact regardless of locale:

```text
Ready for Pickup
Collected
Expired
PACKAGE_CENTER_UNAVAILABLE
PACKAGE_RESIDENT_NOT_FOUND
PACKAGE_NOT_FOUND
```

## Notification boundary

APH.38 does **not** invent a push provider. Receiving a package creates the durable Package Center record immediately. Resident Mobile can read that record through the Resident package endpoints.

`notified_at` remains the existing Package Center notification-tracking field and is not falsely set by Security receiving unless an actual notification workflow records it.
