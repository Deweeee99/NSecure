# HANDOFF — Security Package Collection API Contract V2

Status: **backend contract implemented / frontend alignment required**

Date: **26 Aug 2026**

## 1. Base URL

```text
https://airaai.my.id/admin/api
```

All endpoints below are relative to that base URL.

Authentication:

```http
Authorization: Bearer <security_token>
Accept: application/json
Content-Type: application/json
```

For localized human messages:

```http
Accept-Language: id
```

or:

```http
Accept-Language: en
```

Canonical status, keys, and recipient types are **not translated**.

---

# 2. Important semantic distinction

There are three different people involved in the package lifecycle.

```text
received_by
= Security officer who received / registered the package

collected_by
= person who physically picked up the package
= Resident OR Others

processed_by
= Security/Admin officer who processed the pickup handover
```

Do **not** map `processed_by` as the pickup recipient.

Do **not** map `received_by` as the pickup recipient.

The Flutter Package Detail UI should use:

```text
Received By  -> data.received_by.name
Picked Up By -> data.collected_by.name
Processed By -> data.processed_by.name
```

---

# 3. Collect Package endpoint

```http
POST /security/packages/{package_id}/collect
```

Example:

```text
POST https://airaai.my.id/admin/api/security/packages/55/collect
```

Required Security permission:

```text
security-management:update
```

Package Center must also be enabled for the Security user's assigned property.

---

# 4. Request body — Resident pickup

When the linked Resident physically picks up the package:

```json
{
  "collection_recipient_type": "resident",
  "collection_notes": "Picked up at lobby."
}
```

Required:

```text
collection_recipient_type
```

Optional:

```text
collection_notes
```

Do **not** send:

```text
collection_recipient_name
resident_id
processed_by
collected_at
status
```

for a Resident pickup.

The backend obtains the Resident name from the Resident already linked to the package and snapshots that name into the package pickup record.

Canonical value:

```text
collection_recipient_type = "resident"
```

---

# 5. Request body — Others pickup

When another person physically picks up the package:

```json
{
  "collection_recipient_type": "others",
  "collection_recipient_name": "Mbak Rina - ART",
  "collection_notes": "Picked up at lobby."
}
```

Required:

```text
collection_recipient_type
collection_recipient_name
```

when:

```text
collection_recipient_type = "others"
```

Optional:

```text
collection_notes
```

Canonical value:

```text
collection_recipient_type = "others"
```

Do not invent other wire values such as:

```text
other
guest
family
staff
security
```

---

# 6. Successful response envelope

A successful collect uses this envelope:

```json
{
  "status": "success",
  "message": "Package marked as collected.",
  "data": {
    "...": "package payload"
  }
}
```

HTTP status:

```text
200
```

The `message` is human/localized text. Flutter business logic must use fields under `data`, not parse the message.

---

# 7. FULL response body — Resident pickup

Representative response:

```json
{
  "status": "success",
  "message": "Package marked as collected.",
  "data": {
    "package_id": 55,
    "package_no": "PKG-260826-F94QSQFF",
    "status": "Collected",
    "courier_name": "J&T",
    "tracking_number": "03929393",
    "sender_name": "Blibli",
    "package_description": "motor",
    "storage_location": null,
    "notes": null,
    "collection_notes": null,
    "property": {
      "id": 1,
      "code": "DEFAULT",
      "name": "Aparthub Property"
    },
    "resident": {
      "id": 101,
      "name": "resident",
      "email": "resident@example.com",
      "mobile_no": "08xxxxxxxxxx",
      "property": {
        "id": 1,
        "code": "DEFAULT",
        "name": "Aparthub Property"
      },
      "unit": {
        "id": 20,
        "code": "001",
        "tower": "T001",
        "floor": 1
      }
    },
    "unit": {
      "id": 20,
      "code": "001",
      "tower": "T001",
      "floor": 1
    },
    "received_by": {
      "id": 9,
      "name": "jibran"
    },
    "collected_by": {
      "type": "resident",
      "name": "resident",
      "resident_id": 101
    },
    "processed_by": {
      "id": 9,
      "name": "jibran"
    },
    "received_at": "2026-08-26T16:04:00+07:00",
    "notified_at": null,
    "collected_at": "2026-08-26T16:04:00+07:00",
    "expires_at": null
  }
}
```

The critical part is:

```json
{
  "collected_by": {
    "type": "resident",
    "name": "resident",
    "resident_id": 101
  },
  "processed_by": {
    "id": 9,
    "name": "jibran"
  }
}
```

Flutter must render:

```text
Picked Up By Type : Resident
Picked Up By      : resident
Processed By      : jibran
```

---

# 8. FULL response body — Others pickup

Representative response:

```json
{
  "status": "success",
  "message": "Package marked as collected.",
  "data": {
    "package_id": 56,
    "package_no": "PKG-260826-OTHERS01",
    "status": "Collected",
    "courier_name": "JNE",
    "tracking_number": "JNE-0001",
    "sender_name": "Marketplace",
    "package_description": "Small box",
    "storage_location": "Front Desk",
    "notes": null,
    "collection_notes": "Collected by household staff.",
    "property": {
      "id": 1,
      "code": "DEFAULT",
      "name": "Aparthub Property"
    },
    "resident": {
      "id": 101,
      "name": "resident",
      "email": "resident@example.com",
      "mobile_no": "08xxxxxxxxxx",
      "property": {
        "id": 1,
        "code": "DEFAULT",
        "name": "Aparthub Property"
      },
      "unit": {
        "id": 20,
        "code": "001",
        "tower": "T001",
        "floor": 1
      }
    },
    "unit": {
      "id": 20,
      "code": "001",
      "tower": "T001",
      "floor": 1
    },
    "received_by": {
      "id": 9,
      "name": "jibran"
    },
    "collected_by": {
      "type": "others",
      "name": "Mbak Rina - ART",
      "resident_id": null
    },
    "processed_by": {
      "id": 9,
      "name": "jibran"
    },
    "received_at": "2026-08-26T15:30:00+07:00",
    "notified_at": null,
    "collected_at": "2026-08-26T16:10:00+07:00",
    "expires_at": null
  }
}
```

Flutter should render:

```text
Picked Up By Type : Others
Picked Up By      : Mbak Rina - ART
Processed By      : jibran
```

---

# 9. GET Package Detail

The same pickup fields are returned by package detail:

```http
GET /security/packages/{package_id}
```

Example:

```text
GET https://airaai.my.id/admin/api/security/packages/55
```

Successful envelope:

```json
{
  "status": "success",
  "message": "Package loaded.",
  "data": {
    "package_id": 55,
    "package_no": "PKG-260826-F94QSQFF",
    "status": "Collected",
    "received_by": {
      "id": 9,
      "name": "jibran"
    },
    "collected_by": {
      "type": "resident",
      "name": "resident",
      "resident_id": 101
    },
    "processed_by": {
      "id": 9,
      "name": "jibran"
    },
    "received_at": "2026-08-26T16:04:00+07:00",
    "collected_at": "2026-08-26T16:04:00+07:00"
  }
}
```

The actual payload also contains the other normal package fields such as resident, unit, courier, tracking number, sender, description, storage location, notes, notification timestamp, and expiry timestamp.

---

# 10. GET Package List

```http
GET /security/packages
```

Optional query parameters:

```text
property_id
status
search
per_page
```

Example:

```text
GET https://airaai.my.id/admin/api/security/packages?status=Collected&per_page=30
```

Each list item uses the same package payload shape, including:

```json
{
  "received_by": {
    "id": 9,
    "name": "jibran"
  },
  "collected_by": {
    "type": "resident",
    "name": "resident",
    "resident_id": 101
  },
  "processed_by": {
    "id": 9,
    "name": "jibran"
  }
}
```

Therefore the Flutter list model and detail model should not use conflicting field definitions.

---

# 11. Flutter JSON model mapping

Recommended contract:

```text
Package.receivedBy
<- data.received_by

Package.collectedBy
<- data.collected_by

Package.processedBy
<- data.processed_by
```

Suggested nested models:

```text
PackageActor
- id
- name

PackageCollectionRecipient
- type
- name
- residentId
```

Pseudo mapping:

```dart
receivedBy = json['received_by'] == null
    ? null
    : PackageActor.fromJson(json['received_by']);

collectedBy = json['collected_by'] == null
    ? null
    : PackageCollectionRecipient.fromJson(json['collected_by']);

processedBy = json['processed_by'] == null
    ? null
    : PackageActor.fromJson(json['processed_by']);
```

For recipient:

```dart
type       = json['type'];
name       = json['name'];
residentId = json['resident_id'];
```

Do **not** expect these as top-level response fields:

```text
collection_recipient_type
collection_recipient_name
collected_by_user_id
```

Those are persistence/input concepts. The canonical API response intentionally exposes the recipient through:

```text
data.collected_by
```

and the Security/Admin operator through:

```text
data.processed_by
```

---

# 12. Flutter Package Detail rendering rule

For a Collected package:

```text
Received At
Received By

Collected At

Picked Up By Type   <-- collected_by.type
Picked Up By        <-- collected_by.name

Processed By        <-- processed_by.name
```

Recommended rendering logic:

```text
if collected_by != null:
    show Picked Up By Type
    show Picked Up By
else:
    do not manufacture a recipient
    show "Pickup recipient not recorded" or "-"
```

Never use:

```text
processed_by.name
```

as a fallback for:

```text
Picked Up By
```

because that would incorrectly identify Security as the physical package recipient.

---

# 13. Why the screenshots differ

## Package `PKG-260826-F94QSQFF`

Web Package Center shows:

```text
Picked Up By Type : Resident
Picked Up By      : resident
Processed By      : Administrator Aparthub
```

Therefore the database already contains recipient metadata for this package.

If Security Mobile only shows:

```text
Processed By : Administrator Aparthub
```

and does not show `Picked Up By`, the likely mismatch is on the Flutter side:

```text
- model does not parse data.collected_by; or
- detail UI does not render data.collected_by; or
- Flutter still expects the old field shape.
```

The mobile client must read:

```text
response.data.collected_by.type
response.data.collected_by.name
response.data.collected_by.resident_id
```

## Package `PKG-260826-LEHWSRGU`

Web Package Center shows:

```text
Picked Up By Type : -
Picked Up By      : -
Processed By      : jibran
```

For this row the backend recipient metadata is genuinely missing.

Expected API result:

```json
{
  "collected_by": null,
  "processed_by": {
    "id": 9,
    "name": "jibran"
  }
}
```

This is a legacy/incomplete pickup record.

The Flutter app must **not** convert `processed_by` into `Picked Up By`.

---

# 14. Existing Collected package with missing recipient

The backend supports enriching an older already-collected row when its recipient metadata is still missing.

Request:

```http
POST /security/packages/{package_id}/collect
```

Body:

```json
{
  "collection_recipient_type": "resident"
}
```

or:

```json
{
  "collection_recipient_type": "others",
  "collection_recipient_name": "Mbak Rina - ART"
}
```

For this compatibility correction:

```text
status             remains Collected
original collected_at is preserved
original processed_by is preserved
recipient metadata is recorded
```

The backend does not create a second physical pickup event.

---

# 15. Validation errors

Missing recipient type:

```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "The given data was invalid.",
  "errors": {
    "collection_recipient_type": [
      "The collection recipient type field is required."
    ]
  }
}
```

HTTP:

```text
422
```

`others` without a name:

```json
{
  "status": "error",
  "code": "VALIDATION_ERROR",
  "message": "The given data was invalid.",
  "errors": {
    "collection_recipient_name": [
      "The collection recipient name field is required when collection recipient type is others."
    ]
  }
}
```

HTTP:

```text
422
```

If the linked Resident is no longer available for a Resident pickup:

```json
{
  "status": "error",
  "code": "PACKAGE_COLLECTION_RESIDENT_UNAVAILABLE",
  "message": "The package resident is no longer available for collection.",
  "errors": {}
}
```

HTTP:

```text
422
```

Package not found / inaccessible property:

```json
{
  "status": "error",
  "code": "PACKAGE_NOT_FOUND",
  "message": "Package not found.",
  "errors": {}
}
```

HTTP:

```text
404
```

---

# 16. Canonical values

Package status:

```text
Ready for Pickup
Collected
Expired
```

Recipient type:

```text
resident
others
```

These exact wire values must be preserved.

UI labels may be localized independently.

---

# 17. Frontend acceptance checklist

Security Flutter is aligned only when all of these pass:

- [ ] Collect modal/action offers `Resident` and `Others`.
- [ ] `Others` reveals a required free-text recipient name.
- [ ] Resident request does not send a fabricated resident name.
- [ ] Successful collect parses `data.collected_by`.
- [ ] Successful collect parses `data.processed_by`.
- [ ] Package detail parses the same fields.
- [ ] Package history/list uses the same package model contract.
- [ ] Package Detail renders `Picked Up By Type`.
- [ ] Package Detail renders `Picked Up By`.
- [ ] Package Detail keeps `Processed By` separate.
- [ ] `collected_by == null` is treated as missing legacy recipient metadata.
- [ ] `processed_by` is never used as fallback for `collected_by`.
- [ ] After POST collect, Flutter refreshes from returned `data` or re-fetches GET detail.
- [ ] Canonical status and recipient-type strings are not translated in transport parsing.

---

# 18. Backend source-of-truth contract

Canonical API response fields:

```text
received_by
collected_by
processed_by
```

Meaning:

```text
received_by  = who accepted the incoming package
collected_by = who physically picked it up
processed_by = who processed the handover
```

This semantic split is the contract frontend must implement.
