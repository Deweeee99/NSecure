# Handoff — Security Package Collection Recipient Refinement

Status: **backend implemented / local validation pending**

## Base URL

```text
https://airaai.my.id/admin/api
```

## Why this changed

`received_by` is correctly the Security officer who receives/registers an incoming package.

For pickup/collection, the authenticated Security officer is only the operator processing the handover. The physical pickup recipient must now be captured separately as either the linked Resident or another person.

## Endpoint

```http
POST /security/packages/{package_id}/collect
Authorization: Bearer <security_token>
Content-Type: application/json
```

### Resident pickup

```json
{
  "collection_recipient_type": "resident",
  "collection_notes": "Picked up at lobby."
}
```

The backend takes the recipient name from the package's linked Resident. The app does not send a resident name.

### Other person pickup

```json
{
  "collection_recipient_type": "others",
  "collection_recipient_name": "Mbak Rina - ART",
  "collection_notes": "Picked up at lobby."
}
```

`collection_recipient_name` is mandatory when `collection_recipient_type = others`.

## Response semantics

```json
{
  "status": "success",
  "data": {
    "status": "Collected",
    "collected_by": {
      "type": "resident",
      "name": "Resident Name",
      "resident_id": 101
    },
    "processed_by": {
      "id": 9,
      "name": "Security Officer"
    },
    "collected_at": "2026-08-26T14:30:00+07:00",
    "collection_notes": "Picked up at lobby."
  }
}
```

For `others`:

```json
{
  "collected_by": {
    "type": "others",
    "name": "Mbak Rina - ART",
    "resident_id": null
  }
}
```

## Flutter UI rule

On **Collect Package**:

1. Show recipient choice: `Resident` / `Others`.
2. Default may be `Resident`.
3. If `Others`, reveal a required free-text recipient-name field.
4. `collection_notes` remains optional.
5. After success, display `collected_by.name` as the pickup recipient.
6. `processed_by.name` may be shown in audit/detail UI as the Security officer who processed the handover.

Do not display `processed_by` as the person who picked up the package.

## Canonical values

```text
collection_recipient_type:
- resident
- others

package status:
- Ready for Pickup
- Collected
- Expired
```

## Validation

Missing recipient type or missing `collection_recipient_name` for `others` returns HTTP `422` using the standard Security API validation envelope.

## Compatibility

The DB column `collected_by_user_id` is retained to avoid destructive schema churn, but its semantics are now explicitly **processed by**. New client code must consume `processed_by` for the Security actor and `collected_by` for the pickup recipient.

Historical rows collected before this refinement may have `collected_by = null` because no physical-recipient identity was persisted at that time.
