# SEC.8 Context — Final Visitor Regression + Android Readiness

## Current Status

`DONE`

## Objective

Close the Visitor Verification Android baseline before activating additional operational Security modules.

## Final Locked Result

User confirmed the SEC.8 closeout green. The final cumulative baseline preserves:

- Visitor Verification API mode against `/api/security`;
- secure Sanctum bearer persistence and restore through `/me`;
- real QR camera scanning in API mode;
- deterministic scanner in mock/test mode;
- Manual Verification as first-class fallback;
- session-expiry fail-closed behavior;
- finite request timeout/network error mapping;
- Visitor History retry state;
- release URL hardening;
- Android `INTERNET` + optional `CAMERA` readiness;
- `flutter_secure_storage:^10.3.1`;
- `mobile_scanner:^7.4.0`;
- Flutter-managed `compileSdk`;
- `kotlin.incremental=false` to avoid the validated Windows C: Pub Cache ↔ E: project incremental-cache failure.

## Regression Guard

Every later checkpoint must be based on this cumulative green state. In particular, do not regress:

- SEC.4 persistent Visitor action footer;
- SEC.4 persistent confirmation footer;
- SEC.7 canonical Visitor API decoding/error mapping;
- SEC.8 Android/session/scanner fixes.

## Validation Evidence

Automated evidence immediately before closeout:

```text
flutter analyze           ✅ No issues found
flutter test              ✅ 45 tests passed
flutter build apk --debug ✅ built app-debug.apk
```

The user subsequently confirmed SEC.8 as green and approved continuation.

## Next Checkpoint

`SEC.9 — Patrol Management API Integration`

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile Flutter.
SEC.8 is DONE. Visitor Verification + Android readiness are the locked cumulative green baseline.
Next active checkpoint: SEC.9 — Patrol Management API Integration.

Read:
1. docs/checkpoints/SEC.9_CONTEXT.md
2. docs/CHECKPOINTS.md
3. docs/ROADMAP.md
4. docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
5. docs/API_CONTRACT_SECURITY_PATROL_V1.md
6. docs/ARCHITECTURE.md
7. docs/FRONTEND_SPEC.md
8. docs/DESIGN_SYSTEM.md

Preserve all SEC.8 Android/session/scanner behavior and all prior Visitor UI hotfixes. Patrol is software-only assigned patrol execution. Do not add Patrol QR/NFC/RFID/GPS/device proof or expose scan_token.
```
