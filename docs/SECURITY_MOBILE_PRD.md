# Aparthub Security Mobile — Product Requirement Document

## Product Goal

Aparthub Security is a Flutter mobile application for apartment security and front-desk teams. The product should look and behave like a production-grade enterprise operations app while the initial functional scope remains deliberately narrow.

The locked cumulative baseline through SEC.15 is complete. Current operational Flutter modules are **Visitor Verification**, **Patrol Management with APH.42 checkpoint photo evidence**, **Incident Reporting**, **Emergency SOS**, and **Package Receiving**. SEC.16 is the final production-readiness revalidation checkpoint and does not add product scope.

## Primary Users

- Security/front-desk officers handling visitor arrival and departure.
- Security supervisors who need a consistent operational view.

## Design Source of Truth

Two provided presentation boards are the visual source of truth:

1. **Visitor Verification** board: Security Platform Home, QR verification, manual verification/search, results, visitor detail, check-in, check-out, and history.
2. **Future Operational Modules** board: Patrol Management, Incident Reporting, Emergency Response, Access Control, and Vehicle Management. Patrol graduates from concept to operational execution in SEC.9 and Incident Reporting in SEC.10. APH.37 activates only the software SOS subset of Emergency Response for SEC.12; hardware-dependent emergency capabilities remain excluded.

Implementation must preserve the same visual language: white and soft-gray surfaces, deep Aparthub navy/indigo, subtle blue accents, slate secondary text, rounded enterprise cards, subtle borders and shadows, consistent bottom navigation, compact status chips, and a professional apartment-management SaaS aesthetic.

## Active Operational Scope

Current contracted software scope through SEC.15:

```text
Visitor Verification  ACTIVE
Patrol Management     ACTIVE — APH.42 photo evidence
Incident Reporting    ACTIVE
Emergency SOS         ACTIVE
Package Receiving     ACTIVE
Access Control        HOLD / concept
Vehicle Management   HOLD / concept
```

Visitor Verification remains the original MVP and must not regress while Patrol is activated.

Required workflow:

1. Security Home / Platform Dashboard
2. QR Visitor Verification
3. Manual Visitor Search
4. Visitor Search Results
5. Visitor Detail
6. Check-In Confirmation
7. Check-Out Confirmation
8. Verification History

### Verification paths

Visitor Verification has two first-class operational paths:

- QR scan
- Manual verification using Visit Code or Visitor ID

The product must never require QR scanning as the only verification method.

### Visitor status rules

- Approved -> Check-In available
- Checked-In -> Check-Out available
- Checked-Out -> read-only
- Expired -> Check-In blocked
- Rejected -> Check-In blocked
- Cancelled -> Check-In blocked

## Design Concepts / Coming Soon

After SEC.11, Access Control and Vehicle Management remain non-operational concept/HOLD modules. Emergency Response is split: APH.37 contracts the software-only Resident → Security SOS workflow for SEC.12, while panic hardware, GPS, CCTV/NVR, external alarms and push-provider automation remain HOLD.

Concept screens must not imply active workflows before their checkpoint. Hardware integrations must never be inferred from visual concepts.

## Frontend Strategy

Current implementation supports two compositions through the same repository boundary:

```text
Development / test
UI → Repository abstraction → Mock repository

Backend-integrated runtime
UI → Repository abstraction → API repository → Security Mobile V1 API
```

Release Android runtime must use the backend-integrated composition; mock fallback is intentionally disabled in release builds.

Mock data must be deterministic and must not be embedded directly inside large widgets.

## Minimal Frontend Domain

- `SecurityUser`
- `VisitorVisit`
- `ModulePreview`
- `PatrolSession` / `PatrolCheckpointVisit`
- `VisitorStatus`: Pending, Approved, Checked-In, Checked-Out, Expired, Rejected, Cancelled

## Non-Goals for Current Phase

- Building or changing the Aparthub backend.
- Implementing or implying hardware-dependent Security capabilities without a canonical contract.
- Building a large state-management framework before it is needed.
- Recreating the whole mobile product in a single checkpoint.

## Backend Dependency

The Visitor Verification Security Mobile API V1 contract is final for SEC.7 integration and is stored in `API_CONTRACT_SECURITY_MOBILE_V1.md`. Visitor Verification may run in API mode when `SECURITY_API_BASE_URL` is configured, while deterministic mock mode remains available for tests/demo. Patrol and Incident have explicit Security Mobile contracts under the platform V1 handoff. SEC.9 activates Patrol and SEC.10 activates Incident Reporting. APH.37 defines the operational Emergency SOS Security APIs, APH.38 defines Package Receiving through the existing Package Center, and APH.42 adds photo evidence to the existing Patrol checkpoint routes. Access Control, Vehicle hardware, panic hardware, GPS, CCTV/NVR, push provider, ANPR/barrier, RFID/NFC/BLE, package scanner/photo/smart-locker automation and device telemetry remain undefined/HOLD unless separately contracted.


## Android Runtime Baseline

SEC.8 completes the Android runtime baseline for Visitor Verification with:

- real device QR camera capture in API mode;
- Manual Verification retained as a first-class fallback;
- secure bearer-token persistence and startup session validation;
- fail-closed release API configuration;
- explicit network/retry behavior.

SEC.9 subsequently activates software-only Patrol Management, SEC.10 activates software-only Incident Reporting, and SEC.15 integrates APH.42 Patrol checkpoint photo evidence. SEC.12 activated APH.37 software-only Emergency SOS. SEC.13 activates APH.38 Package Receiving through the existing Package Center; hardware-dependent emergency/device/package capabilities remain non-operational.


## SEC.9 Patrol Operational Scope

Patrol mobile scope is **assigned execution only**. Security officers can view their own assigned sessions, start a Scheduled patrol, process Pending checkpoints as Completed or Skipped, complete the patrol once no Pending checkpoint remains, and view their own history.

Web Admin remains owner of route/checkpoint master data, scheduling, assignment, cancellation, and central monitoring.

The Patrol contract explicitly excludes checkpoint QR/NFC/RFID/BLE/GPS proof and does not expose the database-internal `scan_token`. APH.42 adds **photo evidence only** as the current checkpoint proof. Flutter must not invent any other proof mechanism.

## Dual-Language Requirement (SEC.9A)

Aparthub Security Mobile supports Bahasa Indonesia and English. Localization applies across authentication, navigation, Home, Visitor Verification, Patrol Management, Incident Reporting, and presentation-only future module screens.

The language layer must never modify canonical backend wire status values, stable error codes, timestamps, actor identity, authorization scope, or opaque QR/access credentials.



## SEC.10 Incident Operational Scope

Incident Mobile V1 supports dashboard, active list, history, standalone report creation, detail/timeline, acknowledge, start handling, resolve, and add-note. Actions are controlled by backend `can_*` capability flags. Closed/Cancelled lifecycle administration, assignment, reopening, media upload, emergency dispatch, CCTV/NVR, push messaging, and hardware integrations remain outside mobile V1.

Standalone create may select only from properties already exposed by the authenticated Security profile; client property context never widens server authorization. SEC.11 activates direct Patrol → Incident reporting for an `In Progress` patrol and `Pending` checkpoint by passing the documented `patrol_checkpoint_visit_id`. In API mode the backend remains authoritative for changing that checkpoint to exact status `Issue`; Flutter does not invent a separate checkpoint-mutation endpoint.


## SEC.11A Localization Runtime Contract

The selected/effective Security Mobile locale is transported to the backend on every request as `Accept-Language: id|en`. `Content-Language` is read from responses. Unsupported locale falls back to `en`. Backend human-readable messages may be localized, but the client must branch only on stable machine code and canonical domain values.

## SEC.12 Emergency SOS Contracted Scope

APH.37 defines a durable Resident → Security SOS flow with canonical `Open -> Acknowledged -> Resolved`. Security Mobile will use `/api/security/emergency-alerts/active` as the persistent modal queue source of truth, refresh on launch/login/resume and foreground cadence, apply first-wins acknowledge semantics, and allow only the owning Security officer to resolve. The contract explicitly excludes panic hardware, GPS, CCTV/NVR, external alarm, push provider, and automatic Incident/Service Request creation.

## SEC.13 Package Receiving Operational Scope

APH.38 promotes Package Receiving to an operational Security Mobile module. Security may search active Residents/Units, register a package into the existing Package Center `resident_packages` source of truth, list/detail packages, and mark `Ready for Pickup` packages `Collected`. Canonical statuses remain exact `Ready for Pickup`, `Collected`, `Expired`; Flutter must not manufacture server-owned package number, property/unit, status, actors, or timestamps. Courier integrations, barcode hardware, package photos, smart lockers, push providers, and proof-of-handover hardware remain out of scope.


## SEC.15 Patrol Checkpoint Photo Evidence

APH.42 extends the existing Patrol detail/checkpoint actions without creating new routes. `Complete` requires one image (`image/jpeg`, `image/png`, or `image/webp`, maximum 5 MB) plus optional notes and uses multipart. `Skip` keeps notes required and accepts an optional image; without an image it remains JSON. Mutations always use `visit_id`, never `checkpoint_id`. Backend owns status, `checked_at`, officer identity and temporary signed evidence URL. Flutter consumes `photo_evidence.url` as temporary data and refreshes Patrol Detail when the URL expires.

Camera and Gallery are both first-class sources with preview/remove/retake/change. No automatic mutation retry is allowed after an ambiguous timeout; canonical Patrol Detail must be refreshed first.

## SEC.16 Production Closure Requirement

Release runtime must use explicit `SECURITY_API_BASE_URL=https://<host>/api/security`. Mock fallback is forbidden in release, the base must end with exact `/api/security`, and release requires HTTPS. Final closure requires APH.42 targeted tests, automated analyzer/full-test/debug/release build gates plus real Android/backend smoke for all five operational modules, Auth/session, ID/EN runtime localization, Patrol Camera/Gallery photo evidence, signed-URL refresh behavior, and controlled network/session failure handling.
