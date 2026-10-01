# Aparthub Security Mobile — Roadmap

## Status Legend

- `DONE` — implemented and validation gate green.
- `IMPLEMENTED / VALIDATION PENDING` — source completed, awaiting local Flutter gate.
- `IMPLEMENTED / FINAL VALIDATION PENDING` — final closure source completed; automated + real-device/backend gates are still required.
- `ACTIVE` — current implementation focus.
- `PLANNED` — not started.
- `BLOCKED` — waiting for an external dependency.

## Roadmap

| Checkpoint | Scope | Status |
|---|---|---|
| SEC.1 | Baseline Flutter + Essential Docs + Design Tokens | DONE |
| SEC.2 | App Shell + Security Platform Home | DONE |
| SEC.3 | Visitor Verification Flow — QR + Manual Search | DONE |
| SEC.4 | Visitor Detail + Check-In + Check-Out + History | DONE |
| SEC.5 | Future Module Presentation Screens | DONE |
| SEC.6 | API-Ready Repository Boundary + Handoff Draft | DONE |
| SEC.7 | Visitor Verification Security API Integration | DONE |
| SEC.8 | Final Visitor Regression + Android Readiness | DONE |
| SEC.9 | Patrol Management API Integration | DONE |
| SEC.9A | Localization Foundation — Bahasa Indonesia + English | DONE |
| SEC.10 | Incident Reporting API Integration | DONE |
| SEC.11 | Cross-Module Regression — Visitor + Patrol + Incident | DONE |
| SEC.11A | APH.35C / APH.37 Localization Runtime Alignment | DONE |
| SEC.12 | Emergency SOS Resident → Security Integration | DONE |
| SEC.13 | Security Package Receiving → Package Center | DONE |
| SEC.14 | Final Production Readiness / Security Mobile Closure | SUPERSEDED BY APH.42 REVALIDATION |
| SEC.15 | APH.42 Patrol Checkpoint Photo Evidence | DONE |
| SEC.16 | Final Production Readiness Revalidation / APH.42 Closure | REMEDIATION B IMPLEMENTED / VALIDATION PENDING |

## Current Checkpoint

`SEC.16 — Final Production Readiness Revalidation / APH.42 Closure`

SEC.11A is locked `DONE` after the user confirmed the localization runtime alignment gate green on 14 Aug 2026.

SEC.12 activates the APH.37 software-only Emergency SOS flow:

```text
Resident SOS
  ↓
Open alert
  ↓
Security persistent foreground modal
  ↓ first authorized Security takes alert
Acknowledged
  ↓ owner Security resolves
Resolved
```

`GET /api/security/emergency-alerts/active` is the durable modal source of truth. The app refreshes on shell creation/login, app resume, after mutations, and at a practical foreground cadence in API mode.

## Active / Contracted Software Modules

```text
Visitor Verification  ACTIVE
Patrol Management     ACTIVE — APH.42 photo evidence
Incident Reporting    ACTIVE
Emergency SOS         ACTIVE
Package Receiving     ACTIVE
Access Control        HOLD / concept
Vehicle Management   HOLD / concept
```

Package Receiving from APH.38 must reuse existing Package Center / `resident_packages`; no parallel Security package domain is allowed.

## Context Handoff Rule

Every checkpoint must maintain `docs/checkpoints/SEC.<n>_CONTEXT.md`, including a copy-ready `New Chat Bootstrap`.

## Cumulative Green Baseline Rule

Every patch must be generated from the latest cumulative green project state. Never restore stale pre-hotfix copies of Visitor, Patrol, Incident, Android, localization, theme, or shared navigation files.

## Hardware Guardrail

Do not add panic-button hardware, GPS proof, CCTV/NVR, external alarm/siren, dedicated scanners, NFC/RFID/BLE, ANPR/LPR, barrier control, device telemetry or a push provider without an explicit later contract.


## SEC.13 Package Receiving Integration

SEC.12 is locked `DONE` after the user confirmed the validation hotfix v1 gate green. SEC.13 activates the APH.38 Package Receiving contract through the existing Package Center source of truth.

```text
Search Resident / Unit
  ↓
POST /api/security/packages
  ↓
existing resident_packages row
  ↓
Ready for Pickup
  ↓
POST /api/security/packages/{id}/collect
  ↓
Collected
```

Flutter never manufactures `package_no`, property/unit context, actor IDs, timestamps, or package status. Canonical package statuses stay exact `Ready for Pickup`, `Collected`, and `Expired`; stable `PACKAGE_*` codes drive error handling.


## SEC.13 Validation Attempt 1

The 18 Aug 2026 local gate produced a green analyzer and debug APK, with one test-only failure in the Package end-to-end widget flow. The failure came from a generic `scrollUntilVisible(... find.byType(Scrollable).last)` lookup before a lazy Package form field was mounted. Hotfix v1 changes only the widget-test scroll strategy to bounded direct drags on the active Package `ListView`; production Package Receiving behavior is unchanged.


## SEC.13 Closure

The user confirmed the SEC.13 validation hotfix v1 gate fully green on 18 Aug 2026. Package Receiving is locked `DONE` and joins the cumulative green operational baseline.

## SEC.14 Final Production Readiness

SEC.14 introduced the production-composition guardrails but was not treated as final closure after APH.42 added a new contracted Patrol capability. Its runtime hardening remains cumulative and unchanged.

## SEC.15 APH.42 Patrol Checkpoint Photo Evidence

APH.42 adds software-only photo proof to the existing Patrol checkpoint routes. Complete requires one JPG/JPEG/PNG/WEBP photo up to 5 MB and optional notes; Skip keeps notes required and accepts an optional photo. Mutation identity remains exact `visit_id`. Backend `photo_evidence.url` is a temporary signed URL and is never reconstructed or persisted as a permanent reference.

The user confirmed the latest SEC.15 targeted + full Flutter gate green on 19 Aug 2026, so SEC.15 is locked `DONE`.

## SEC.16 Final Production Readiness Revalidation

SEC.16 adds no product feature. It re-runs the final production gate against the cumulative baseline after APH.42. Release mode must still fail closed without an explicit HTTPS `/api/security` base. The final smoke matrix now also covers Complete via Camera/Gallery, Skip with/without optional photo, signed evidence retrieval/refresh, validation failures, and ambiguous-network refresh-before-retry behavior.

Final closure requires automated targeted/full tests, debug + release compile, and real Android/backend ID/EN smoke. See `docs/PRODUCTION_READINESS.md`.

First SEC.16 runner evidence: APH.42 + SEC.16 targeted regression passed (27 tests); analyzer then stopped on one `use_null_aware_elements` info in the optional Complete-checkpoint notes collection. Hotfix v1 is code-style/serialization-neutral and the full runner must be repeated.

## SEC.16 Real-Device Smoke Remediation

Automated validation completed successfully, but real-device smoke found production/runtime presentation defects. SEC.16 therefore remains open.

Remediation A removes behavior that does not require a new backend contract:

```text
Home KPI dummy values                 REMOVED / HIDDEN
Notification bell + fake badge        HIDDEN
Coming Soon / inactive module cards   HIDDEN
Manual Verify seeded recent searches  REMOVED
Android system Back                    APP-INTERNAL BACK FLOW
```

The production Home and More surfaces now expose only the contracted software-active modules: Visitor Verification, Patrol Management, Incident Reporting, Emergency SOS, and Package Receiving. Operational KPIs stay hidden until a complete backend dashboard payload contract is available; no value is manufactured locally. Manual recent searches are session-only and created only from actual successful user search requests.

At the Remediation A boundary, the following were deliberately blocked pending the complete backend handoff and were not changed by Remediation A:

```text
Package Receiving decoder mismatch: Package field unit must be an object
Visitor QR real-backend verification mismatch
```

No endpoint, payload field, or decoder compatibility rule is invented for those two blockers.


### Remediation B — Full Security API handoff alignment

The current-source handoff dated 20 Aug 2026 closes the two contract-dependent real-device blockers without inventing endpoints:

- Home Visitor KPI is loaded from `/api/security/dashboard`;
- valid QR uses `/visitor-access/validate` and the full Visitor payload already returned by that endpoint;
- Package decoding uses only the documented top-level/nested Resident property-unit object copies;
- current deployment base for smoke is `https://airaai.my.id/admin/api/security`;
- notification UI stays hidden because the current 39-route Security contract contains no notification route;
- Access Control/Vehicle/hardware concepts stay hidden/out of production.

SEC.16 closes only after revalidation + real-device/backend smoke are green.

SEC.16 validation hotfix v2 is test-only: after 45 targeted tests and analyzer passed, the full widget regression exposed `Package Receiving` below the default 800x600 test viewport. The Back-navigation test now uses `ensureVisible` before tapping that Home module. SEC.16 remains open pending full runner + real-device smoke.

SEC.16 remains open for real-device QR remediation. No new scope is introduced;
the Visitor QR endpoint remains `/visitor-access/validate` with exact raw access
code. Final closure requires successful real QR validation/check-in on Android.

SEC.16 remains open for Visitor runtime closure. Backend capability flags are now authoritative for Check-In/Check-Out; a future Approved visit no longer exposes a false-positive Check-In CTA.

SEC.16 remains open. Manual Visitor lookup is database-backed, but Check-In transport recovery and real QR pass decodability require re-smoke before final closure. No new endpoint or QR payload format is introduced.

SEC.16 remains open for real-device re-smoke after resolving a shared `IoSecurityApiClient` JSON POST header-order defect that caused authenticated POST actions to surface `NETWORK_ERROR` while GET remained healthy.


## SEC.17 — UI & Runtime Corrective Round 1

Active corrective checkpoint. This is not a production/final-closure milestone.

Scope:

```text
Incident Detail CTA layout cleanup
Hide ACTIVE module badges
Patrol checkpoint multipart Content-Length hardening
Patrol field-level validation error visibility
```

Further production decisions remain user-controlled.


SEC.17 corrective scope extended with the 26 Aug 2026 Package Collection
Recipient handoff: Resident/Others pickup selection, required free-text name for
Others, and separate pickup-recipient vs Security-processor display semantics.

SEC.17 corrective work includes compatibility for historical Package collection records created before recipient semantics were persisted. New `collected_by.type` remains canonical; legacy Security actor payloads are never shown as pickup recipient.

SEC.17 package corrective work aligned to Collection API Contract V2: Picked Up By Type + Picked Up By are separate from Processed By, and legacy Collected rows with missing recipient can be enriched through the same collect endpoint.
