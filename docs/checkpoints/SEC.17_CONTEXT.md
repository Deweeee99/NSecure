# SEC.17 Context — UI & Runtime Corrective Round 1

## Status

```text
SEC.17 — UI & Runtime Corrective Round 1
IMPLEMENTED — VALIDATION PENDING
```

## Boundary

Production / release timing is user-controlled. This checkpoint is corrective
development only and does not declare or imply production readiness/final
closure.

## Scope

1. Incident Detail bottom CTA layout cleanup.
2. Hide ACTIVE status badges from active module cards on Home and More.
3. Correct Patrol checkpoint multipart transport and improve server validation
   visibility for APH.42 Mark Complete / Skip-with-photo.

## Implementation

### Incident Detail footer

- Add Note is a full-width secondary action.
- Lifecycle actions are rendered below it.
- One lifecycle action uses full width.
- Two lifecycle actions use equal-width 48px buttons.
- Existing action keys and backend capability flags remain authoritative.

### Security module cards

- ACTIVE badges are removed from Home and More.
- Only already-active production modules remain listed.
- No Coming Soon module is restored.

### Patrol checkpoint multipart

APH.42 remains unchanged:

```text
POST /api/security/patrol/checkpoint-visits/{visit_id}/complete
multipart/form-data
photo required
notes optional
```

The custom `dart:io` multipart body is now buffered (evidence is already capped
at 5 MB) and sent with deterministic `Content-Length`. This avoids relying on
chunked multipart transfer through the production reverse-proxy/PHP stack.

No endpoint, field, canonical status, `visit_id`, or backend behavior is changed.

Laravel `VALIDATION_ERROR` field details are now surfaced from `errors` rather
than collapsing everything to the generic `The given data was invalid.`. If a
server-side validation issue remains after this transport correction, real
device smoke will show the actual field message (for example `photo`).

## Files changed

```text
lib/core/network/security_api_client.dart
lib/features/incident/presentation/incident_management_screen.dart
lib/features/patrol/data/api/api_patrol_repository.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
test/api_patrol_repository_test.dart
test/security_api_multipart_transport_test.dart
test/widget_test.dart
docs/CHECKPOINTS.md
docs/ROADMAP.md
docs/checkpoints/SEC.17_CONTEXT.md
```

## Deliberate non-scope

- no backend endpoint changes;
- no new dummy data;
- no new module activation;
- no change to QR / Visitor transport;
- no production declaration;
- no GPS / NFC / RFID / checkpoint QR proof.

## Validation gate

```powershell
flutter pub get
flutter gen-l10n

flutter test `
  test\security_api_multipart_transport_test.dart `
  test\api_patrol_repository_test.dart `
  test\widget_test.dart

flutter analyze
flutter test
flutter build apk --debug
```

## Real-device smoke

```text
Incident Detail
- Open: Add Note + Acknowledge/Start layout
- Acknowledged: Add Note + Start/Resolve layout
- In Progress: Add Note + Resolve layout

Home / More
- no ACTIVE badges
- active module navigation remains functional

Patrol
- Mark Complete chooses Camera/Gallery
- preview
- submit required photo
- backend returns Completed
- evidence renders after detail refresh
- if 422 remains, record the now-specific field validation text
```

## Next

Do not infer production/final closure from this checkpoint. Continue corrective
work according to user-selected scope after validation.

## New Chat Bootstrap

```text
Aparthub Security Flutter is in SEC.17 — UI & Runtime Corrective Round 1.
Production timing is explicitly user-controlled; do not declare final closure.
SEC.17 cleans Incident Detail CTA layout, hides ACTIVE module badges, and
hardens APH.42 multipart checkpoint upload with Content-Length plus field-level
validation error surfacing. Validate targeted tests, analyze, full test, debug
APK, then real-device Incident/Home/Patrol smoke.
```


## Package Collection Recipient Refinement — 26 Aug 2026

Backend handoff:
`docs/handoffs/HANDOFF_SECURITY_PACKAGE_COLLECTION_RECIPIENT_20260826.md`

Package pickup semantics are refined without changing the Security audit actor.

```text
processed_by
→ authenticated Security officer who processes handover

collected_by
→ physical pickup recipient
→ resident | others
```

Collect UI now:

```text
Pickup Recipient
[ Resident | Others ]

Resident
→ backend derives linked Resident name
→ Flutter does not submit resident name

Others
→ required free-text Recipient Name

Collection Notes
→ optional
```

Request contract:

```json
{
  "collection_recipient_type": "resident",
  "collection_notes": "Picked up at lobby."
}
```

or:

```json
{
  "collection_recipient_type": "others",
  "collection_recipient_name": "Mbak Rina - ART",
  "collection_notes": "Picked up at lobby."
}
```

Canonical recipient values remain exact:

```text
resident
others
```

Package detail renders `collected_by.name` as **Pickup Recipient** and
`processed_by.name` as **Processed By**. It no longer presents the Security
operator as the person who physically picked up the package.

Historical collected rows are supported when `collected_by = null`.

Validation:
- recipient type is always sent;
- Others recipient name is validated client-side and server-side;
- backend 422 field errors remain available through the Package repository.

This remains SEC.17 corrective development and is not a production milestone.


## Package Recipient Compatibility Hotfix v1

Real-device Package list smoke after the 26 Aug recipient refinement surfaced:

```text
Package field type is required.
```

The failure was caused by a strict frontend decoder assuming every non-null
`collected_by` object already uses the new recipient-aware shape:

```json
{"type":"resident|others","name":"...","resident_id":...}
```

Existing/historical rows can still be serialized with the pre-refinement actor
shape:

```json
{"id":9,"name":"Security Officer"}
```

That legacy actor is **not** a physical pickup recipient. Compatibility handling
now follows the refined semantics:

```text
new collected_by with type
→ decode as Pickup Recipient

legacy collected_by {id,name} without type
→ Pickup Recipient = unknown/null
→ if processed_by is absent, preserve legacy actor as Processed By
```

This prevents one historical package from breaking the entire Package list and
avoids falsely presenting a Security officer as the person who picked up the
package. New recipient-aware rows remain strict and canonical.

SEC.17 remains corrective development / validation pending.


## Package Collection API Contract V2 Alignment — 26 Aug 2026

Canonical source:
`docs/handoffs/HANDOFF_SECURITY_PACKAGE_COLLECTION_API_CONTRACT_20260826_V2.md`

Flutter uses one package model for collect response, detail, and list:

```text
received_by  = incoming-package Security receiver
collected_by = physical pickup recipient
processed_by = handover processor
```

Collected Package Detail now renders:

```text
Received By
Collected At
Picked Up By Type
Picked Up By
Processed By
```

`processed_by` is never used as the physical pickup recipient.

V2 also allows correcting an already-Collected legacy/incomplete row when
`collected_by == null`. In that exact state Flutter exposes `Record Pickup
Recipient` and calls the existing collect endpoint with `resident` or `others`.
The backend preserves the original `collected_at` and `processed_by`.

`PACKAGE_COLLECTION_RESIDENT_UNAVAILABLE` is mapped explicitly.

SEC.17 remains corrective development / validation pending.
