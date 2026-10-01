# Aparthub Security Mobile — Frontend Specification

> **Status: ACTIVE FRONTEND IMPLEMENTATION SPEC**  
> This document translates the Product Requirement Document and the two approved design panels into screen, interaction, state, and component requirements for Flutter.

## 1. Product Surface

Aparthub Security is a mobile operational app for apartment security/front-desk teams.

Current operational product scope through SEC.15:

```text
Visitor Verification
Patrol Management — APH.42 checkpoint photo evidence
Incident Reporting
Emergency SOS
Package Receiving
```

Still non-operational / concept-only:

```text
Access Control
Vehicle Management
```

A module becomes operational only through its explicit frontend checkpoint and canonical backend contract.

## 2. Source of Truth

Frontend implementation is governed by:

1. the approved **Visitor Verification** design panel;
2. the approved **Future Operational Modules** design panel;
3. `SECURITY_MOBILE_PRD.md` for product scope;
4. `DESIGN_SYSTEM.md` for visual rules;
5. this file for screen/interaction behavior;
6. `ARCHITECTURE.md` for code boundaries;
7. `API_CONTRACT_SECURITY_PLATFORM_V1.md` for the shared Security Mobile V1 boundary;
8. `API_CONTRACT_SECURITY_MOBILE_V1.md` for Visitor;
9. `API_CONTRACT_SECURITY_PATROL_V1.md` for Patrol;
10. `API_CONTRACT_SECURITY_INCIDENT_V1.md` for Incident;
11. `API_HANDOFF_DRAFT.md` only as superseded historical proposal context.

If a visual detail is not explicitly documented, preserve the visual language of the two panels instead of inventing a new style.

## 3. Global Application Shell

Persistent primary navigation:

```text
Home | Verify | History | More
```

### Home

Purpose: operational overview and platform module entry point.

Required sections:

- top app identity/header;
- greeting;
- Security user/post identity;
- Today's Overview summary;
- Security Modules grid;
- active/coming-soon status language.

Mock-mode identity:

```text
Security Team
Front Desk • Main Lobby
Aparthub Residence
```

Current deterministic overview:

```text
Today's Visitors  12
Checked-In          8
Checked-Out         4
Pending Arrivals    3
```

These Visitor overview values remain presentation-only because the supplied Visitor/platform handoff names `GET /dashboard` but does not define its response payload. Do not infer dashboard fields. API-authenticated user identity is real; dashboard counters remain presentation data until a dashboard response contract is supplied.

### Verify

Purpose: active Visitor Verification workspace.

Default entry should prioritize QR verification while making Manual Verification equally obvious and reachable.

### History

SEC.4 target: functional Verification History.

Before SEC.4: placeholder only, never fake activity.

### More

Purpose: platform expansion entry point.

Before SEC.5: informative placeholder.

SEC.5: presentation screens for future security modules.

## 4. Security Module Cards

Required modules:

| Module | Current Product State | UI State |
|---|---|---|
| Visitor Verification | Active MVP | `ACTIVE` |
| Patrol Management | Active SEC.9 + APH.42 photo evidence in SEC.15 | `ACTIVE` |
| Incident Reporting | Active SEC.10 | `ACTIVE` |
| Emergency SOS | Active SEC.12 | `ACTIVE` |
| Access Control | Future | `COMING SOON` / `PLANNED` |
| Vehicle Management | Future | `COMING SOON` / `PLANNED` |

Visitor, Patrol, Incident, Emergency SOS, and Package Receiving may use the strong Aparthub navy `ACTIVE` treatment. Access Control and Vehicle Management must not imply production capability.

## 5. Visitor Verification — Screen Inventory

Target active workflow:

```text
1. Security Home / Platform Dashboard
2. QR Visitor Verification
3. Manual Visitor Search
4. Visitor Search Results
5. Visitor Detail
6. Check-In Confirmation
7. Check-Out Confirmation
8. Verification History
```

SEC.3 currently implements items 1–4. SEC.4 implements items 5–8 and operational mutations.

## 6. QR Visitor Verification

### Purpose

Resolve a visitor visit from a QR payload without making QR the only operational path.

### Required visual structure

- compact app bar/title `Scan QR` or equivalent;
- dark navy/deep-blue scanner surface;
- high-contrast scan frame/corners;
- concise instruction inside scanner area;
- clear `OR` separator;
- obvious manual-entry CTA;
- consistent bottom navigation.

### SEC.7 behavior

The repository/API contract now validates the exact opaque QR/access credential through `POST /visitor-access/validate`. The QR credential is distinct from `visit_code` and must not be trimmed, normalized, regenerated, or exposed in Visitor payloads.

Scanner behavior is now mode-aware. Deterministic mock mode keeps the sample QR path for tests/demo without opening a camera. API mode uses the device camera and forwards the detected raw QR payload unchanged to the repository/API boundary. Manual Verification remains fully operational in both modes.

### Production requirement

With the SEC.8 device scanner enabled:

- camera permission denial must not block Manual Verification;
- invalid/unreadable QR must surface an actionable state;
- repeated scanning must be guarded during an in-flight verification;
- decoded payload must be resolved through the repository/API boundary.

## 7. Manual Visitor Verification

Manual Verification is a first-class workflow, not an emergency-only fallback.

Required input keys:

```text
Visit Code
Visit ID
```

Examples:

```text
VST-240515-0012
245
```

### Required states

- empty input;
- loading;
- one or more matching results;
- no results;
- recent search shortcuts where available.

### Validation

- trim surrounding whitespace;
- empty input must not call the repository;
- query matching may be case-insensitive in mock mode;
- frontend must not invent visitor records when no match exists.

## 8. Visitor Search Results

Each result card should expose at minimum:

- visitor name;
- visit code;
- status chip;
- resident name;
- unit;
- tower;
- scheduled date;
- valid visit window.

Cards must be easily scannable at front-desk speed. Avoid dense paragraphs.

Selecting a result leads to Visitor Detail once SEC.4 is implemented.

## 9. Visitor Detail — SEC.4 Implemented

Required information hierarchy:

```text
Visitor identity
Visit Code
Visit ID
Resident
Property
Tower
Unit
Purpose
Scheduled date
Valid time window
Current status
Check-In/Check-Out timestamps when available
Officer identity when available
```

### Primary action matrix

| Visitor Status | Primary Action | Behavior |
|---|---|---|
| Pending | None | Read-only / not yet approved |
| Approved | Check-In Visitor | Enabled |
| Checked-In | Check-Out Visitor | Enabled |
| Checked-Out | None | Read-only |
| Expired | None | Check-In blocked |
| Rejected | None | Check-In blocked |
| Cancelled | None | Check-In blocked |

The same rule must apply regardless of whether the visitor was found via QR, Manual Verification, or History.

Implementation note: eligibility is centralized on `VisitorVisit.canCheckIn` and `VisitorVisit.canCheckOut`; repository mutations reject invalid transitions so UI visibility is not the only guard.

## 10. Check-In Confirmation — SEC.4 Implemented

After successful Check-In, show a dedicated confirmation surface consistent with the source-of-truth panel.

Required content:

- prominent success icon;
- `Check-In Successful!` or equivalent;
- visitor name;
- visit code;
- resident/unit reference;
- authoritative Check-In time;
- checked-in-by officer;
- `Done`;
- `Continue Verifying`.

The screen must not imply success before repository mutation succeeds.

## 11. Check-Out Confirmation — SEC.4 Implemented

Required content mirrors Check-In confirmation:

- prominent success state;
- visitor identity;
- visit code;
- resident/unit;
- Check-Out time;
- checked-out-by officer;
- `Done`;
- `Continue Verifying`.

## 12. Verification History — SEC.4 Implemented

Required filter concepts from the visual source of truth:

```text
All
Checked-In
Checked-Out
Pending
Expired
```

History rows/cards should show:

- visitor;
- visit code;
- resident/unit;
- status;
- relevant date/time.

History is operational activity, not a generic event log.

## 13. Visitor Domain Model

Frontend baseline fields:

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
qrPayload
checkedInAt
checkedOutAt
checkedInBy
checkedOutBy
```

Supported statuses:

```text
Pending
Approved
Checked-In
Checked-Out
Expired
Rejected
Cancelled
```

## 14. Loading, Empty, Error, and Disabled States

Every functional screen must account for non-happy paths.

### Loading

- prevent duplicate actions;
- preserve layout stability where practical;
- use concise progress feedback;
- do not block manual fallback because QR/camera is unavailable.

### Empty

- explain what was searched;
- provide a direct way back to Manual Verify or QR;
- do not present a blank list with no context.

### Domain-blocked action

For Expired, Rejected, Cancelled, Pending, and terminal states:

- action must be absent or disabled intentionally;
- status must remain visible;
- no fake successful mutation.

### Backend/network error — future

When API integration begins:

- preserve visitor context when possible;
- provide retry for transient failures;
- show authorization errors distinctly;
- never expose raw exception text.

## 15. Copywriting Rules

Use operational, concise English matching the design panels.

Preferred:

```text
Scan QR
Manual Verify
Search Results
Visitor Detail
Check-In Visitor
Check-Out Visitor
Verification History
Continue Verifying
Coming Soon
```

Avoid marketing copy inside operational screens.

Status terminology must be identical across Home, Verify, Detail, confirmation, and History.

## 16. Future Module Presentation Rules

For modules that remain presentation-only at their respective stage (Incident until SEC.10, Emergency SOS until SEC.12, Access, Vehicle):

Allowed before backend activation:

- presentation-quality concept screens;
- static data examples;
- status chips such as Planned/Coming Soon/Concept;
- safe navigation into a preview;
- explanatory non-production copy.

Not allowed:

- fake production submit success;
- fake emergency escalation;
- fake access unlock;
- fake patrol persistence;
- fake incident backend submission;
- fake vehicle access control;
- claims that hardware/API integrations already exist.

## 17. Responsive and Device Behavior

Primary target is mobile portrait.

Rules:

- preserve a compact enterprise density;
- maintain at least the documented horizontal page gutter;
- allow vertical scrolling rather than compressing critical content;
- cards and form controls must not overflow at common Android widths;
- support text scaling reasonably without clipping primary actions;
- tablet layouts may center/constrain content but must not redesign the visual language.

## 18. Acceptance Standard for New Screens

A frontend checkpoint is not visually complete unless:

- it matches the approved Aparthub Security visual language;
- it uses shared tokens/components instead of arbitrary styling;
- active vs future module state is unambiguous;
- QR and Manual Verification remain equally viable;
- status/action rules are consistent;
- loading/empty/blocked states are defined;
- `flutter analyze` passes;
- relevant tests pass;
- Android debug build passes when required by the checkpoint.

## 19. SEC.5 Future Operational Module Screen Specification

SEC.5 originally implemented the Future Operational Modules board as presentation concepts. SEC.9 supersedes only the Patrol presentation behavior with an operational assigned-execution flow; the design language remains unchanged.

### Patrol Management — superseded by SEC.9 operational behavior

Preserve the SEC.5 visual hierarchy (assigned route, property, officer, schedule/duration, progress and checkpoints), but source it from `PatrolRepository`. Operational Patrol Route / Checkpoints uses explicit backend `Start`, `Complete`, and `Skip` actions. There is no scanner-based checkpoint Check-In because the backend contract does not define QR/NFC/GPS proof.

### Incident Reporting

Required presentation content:

- incident type treatment;
- location field treatment;
- description field treatment;
- photo/evidence area;
- future submit CTA shown but disabled.

Incident Detail may show static example metadata and evidence. It must not imply a report was actually submitted.

### Emergency Response

Required presentation content:

- emergency semantic-red region;
- SOS control visual;
- emergency contacts;
- explicit concept-only notice.

SOS escalation, phone dialing, notification dispatch, and hardware integration are not active.

### Access Control

Required presentation content:

- Residents / Visitors / Vendors categorization;
- search treatment;
- identity/access cards;
- Active / Inactive semantic status.

No door, turnstile, lock, credential, or controller command is active.

### Vehicle Management

Required presentation content:

- plate search treatment;
- vehicle identity;
- owner/resident reference;
- registration state;
- parking/access state;
- recent vehicle access example.

No gate, ANPR, barrier, parking sensor, or other hardware integration is active.

### Navigation rule

Future module cards on Home and the More module catalog may open these concept screens.

This navigation is for product presentation only. It must not be interpreted as production module activation.

## 20. API-Ready Frontend Boundary — SEC.6

SEC.6 does not add HTTP integration. It defines how existing screens must interact with a future API repository.

### Dependency rule

```text
AparthubSecurityApp
  ↓
AppDependencies
  ↓
VisitorRepository
  ↓
SecurityAppShell / Visitor flows
```

Feature widgets must not instantiate a concrete repository.

### Mutation authority

Visitor action calls are identifier-only from UI:

```text
checkIn(visitId)
checkOut(visitId)
```

The returned repository entity is authoritative for status, operator identity, and timestamps.

UI must not submit `Security Team`, `DateTime.now()`, or another client value as trusted audit data.

### Error behavior

Presentation consumes `VisitorRepositoryException` and maps stable `VisitorRepositoryFailureCode` values to user-facing copy.

Do not expose raw HTTP errors or backend exception text directly in widgets.

### SEC.7 switch expectation

When backend is ready, the expected implementation change is primarily:

```text
AppDependencies.mock()
        ↓
AppDependencies.api(...)
```

plus data/API parser implementation. Existing Visitor screens should remain behaviorally stable unless the final backend contract requires a documented product change.


## SEC.8 Runtime States

### Session bootstrap

API mode must show login while no valid session exists. If a bearer token is restored from secure storage, `/me` validates the token before the Security shell becomes operational.

Invalid or forbidden restored sessions are deleted locally and return to login. A runtime `UNAUTHENTICATED` Visitor response also exits the operational shell.

### QR camera unavailable

The scanner panel must show an explicit camera-unavailable state. The layout must keep **Enter Code Manually** visible; camera failure must never dead-end visitor processing.

### History network failure

Verification History must render a stable error state with **Retry** instead of throwing an asynchronous repository error through the widget tree.

### Release configuration

Release builds do not silently enter mock mode. `SECURITY_API_BASE_URL` is mandatory and HTTPS-only for release runtime.


## 20. SEC.9 Patrol Management — Operational Specification

### Ownership boundary

Mobile owns only assigned execution:

```text
Dashboard → Assigned Patrol → Patrol Detail → Start → Complete/Skip Checkpoints → Complete Patrol → History
```

Web Admin owns route/checkpoint master, scheduling, officer assignment, cancellation and central monitoring.

### Dashboard

Required states/content:

- Scheduled count;
- In Progress count;
- Completed Today count;
- backend-selected active/next Patrol when present;
- assigned session cards with property, scheduled start, status and checkpoint progress;
- loading, refresh, empty, retry/error.

### Detail / route

Show only backend-supported fields:

- route name + session number;
- property;
- officer;
- scheduled/started/completed times when available;
- expected duration;
- notes when available;
- checkpoint summary/progress;
- ordered checkpoint list.

Do not invent expected checkpoint times because the current API does not expose them.

### Action rules

- `can_start=true` → show persistent `Start Patrol`;
- checkpoint `can_complete=true` → show `Mark Complete`;
- checkpoint `can_skip=true` → show `Skip`;
- Skip requires non-empty reason, max 2000;
- `can_complete=true` on an In Progress session → enable persistent `Complete Patrol`;
- if Pending checkpoints remain, keep Patrol completion disabled and communicate the pending count.

Backend capability flags are authoritative. Flutter may still enforce basic local input validation but must not re-create backend authorization logic.

### Hardware exclusion

Never render a QR/NFC/RFID/GPS scan requirement for Patrol. The internal backend `scan_token` is not a mobile field. APH.42 adds Camera/Gallery photo evidence as the only contracted checkpoint proof; all other checkpoint processing remains explicit authenticated software action.

### History

History contains terminal own sessions (`Completed`, `Cancelled`) and provides All / Completed / Cancelled presentation filters while preserving backend ordering.

## Dual-Language Frontend Requirement (SEC.9A)

Supported UI locales:

```text
id — Bahasa Indonesia
en — English
```

Language can be changed from Login and More. The selected locale is persisted locally under `security.locale.language_code`. UI labels, validation copy, empty/error states, status labels, and concept notices must come from localization resources. API status strings/error codes are never translated before parsing or transport.



## SEC.10 Incident Reporting — Operational Screen Inventory

```text
Incident Dashboard
Incident Active List
Create Incident
Incident Detail + Timeline
Acknowledge / Start / Resolve / Add Note
Incident History
```

Incident actions must use backend capability flags (`can_acknowledge`, `can_start`, `can_resolve`, `can_add_note`) rather than frontend-only status assumptions. Resolve and Add Note require non-empty notes; Acknowledge and Start may submit optional notes.

Incident create fields are title, description, category, canonical severity, optional location, and authorized property context where multiple properties exist. Do not expose or manufacture backend-owned status, actor, timestamps, escalation, assignment, or incident number. Media evidence is explicitly absent from V1.


## SEC.11 Patrol → Incident Flow

For an assigned Patrol session with exact status `In Progress`, a checkpoint with exact status `Pending` exposes `Report Issue` / `Laporkan Masalah`. The CTA is not shown for terminal checkpoints or non-running Patrols.

The Incident Create screen opens with authorized property context, `patrol_checkpoint_visit_id`, checkpoint name/session number display context, and checkpoint location prefilled when available. Required Incident title/category/description/severity rules remain unchanged.

Cancelling/backing out of a Patrol-linked Incident returns to Patrol. After successful create, Incident Dashboard is shown; using Back returns to Patrol, which reloads canonical state. API mode expects the backend-created `Issue` checkpoint state.

## SEC.11A Backend Localization Runtime Contract

Every backend-integrated Security request sends the currently selected/effective language as exact primary code `id` or `en` using `Accept-Language`. The client reads `Content-Language` from API responses. Unsupported client locale falls back to `en` before transport.

Backend human-readable messages may be displayed, but they are not a business-logic API. UI/repository branching must continue to use stable error code, canonical status, severity and other documented domain fields.

Status display copy follows `docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json`. Canonical wire values are not rewritten in repository/domain state.

## SEC.12 Emergency SOS Surface

APH.37 establishes the implemented software-only Emergency SOS path. The Security application treats `GET /api/security/emergency-alerts/active` as the persistent modal source of truth, not local notification state. This does not activate panic hardware, GPS, CCTV/NVR, external alarms, ANPR/barrier, RFID/NFC/BLE, or push-provider integrations.

## SEC.12 Emergency SOS UI

The Security Home and More catalog expose Emergency SOS as ACTIVE. An Open SOS renders a non-dismissible persistent modal above the current shell with Resident, Unit, alert code, optional message, trigger time, and Take Alert action. The operational Emergency screen shows unresolved alerts, resolved history, detail, acknowledge, and owner-only resolve with optional notes.


## SEC.13 Package Receiving UI

Package Receiving is ACTIVE on Security Home and More. The screen keeps the established Aparthub enterprise shell and provides Package Center source-of-truth messaging, package search/status filters, Resident/Unit lookup, receive/register form, package detail, and a persistent `Mark Collected` action for exact `Ready for Pickup` records. Receive requires Resident selection and courier; tracking number, sender, description, storage location, and notes are optional. Server-owned package number/status/property/unit/actors/timestamps are read-only. No scanner/photo/smart-locker/push affordance is rendered because those capabilities are outside APH.38.


## SEC.15 APH.42 Patrol Checkpoint Photo Evidence UI

For an exact Pending checkpoint in an `In Progress` Patrol, `Complete` opens a Camera/Gallery chooser. A selected image is previewed before submit and can be removed, retaken, or changed. Photo is mandatory for Complete; notes are optional. Submit uses the existing checkpoint-visit Complete action and the UI reloads Patrol Detail after success.

`Skip` keeps a mandatory reason and exposes an optional Camera/Gallery photo. Without photo, Skip uses the existing JSON action; with photo it uses multipart. Existing Completed/Skipped checkpoint evidence is rendered only from the backend-provided temporary `photo_evidence.url`. If the URL expires, the recovery affordance is Patrol Detail refresh; the UI never constructs a private-storage path.

Validation copy supports ID/EN. Missing/invalid/oversized photo and backend stable Patrol codes are surfaced without translating canonical state. Network ambiguity must instruct refresh-before-retry and must not trigger automatic mutation replay.

No GPS, QR/NFC/RFID/beacon/device-registry affordance is introduced by this evidence UI.

## SEC.16 Final Production Readiness Revalidation

SEC.16 adds no new screen family. It revalidates the existing software UI after APH.42 while preserving the production composition guardrails introduced in SEC.14. Release builds must use an explicit HTTPS `SECURITY_API_BASE_URL` ending in `/api/security`; release mock fallback is forbidden.

Final device/backend smoke must cover Auth/session recovery, ID/EN switching, Visitor QR/manual/check-in/out/history, Patrol execution/history, APH.42 Complete via Camera/Gallery, Skip with/without optional photo, evidence signed-URL refresh, Patrol → Incident linkage, Incident lifecycle, persistent Emergency SOS acknowledge/resolve ownership, Package receive/collect, and network/session failures. Hardware-HOLD concepts must remain visibly non-operational.
