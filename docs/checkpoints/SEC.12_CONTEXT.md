# SEC.12 Context — Emergency SOS Resident → Security

Status: **DONE**

Date opened: 14 Aug 2026

## Objective

Implement the APH.37 Security Mobile side of the software-only Resident SOS lifecycle while preserving the cumulative green Visitor + Patrol + Incident + ID/EN baseline.

```text
Resident taps SOS
→ durable backend alert is Open
→ Security Mobile persistent modal reads /emergency-alerts/active
→ first Security acknowledges/takes alert
→ alert leaves active modal queue for everyone
→ owner Security resolves
```

## Locked Input Baseline

SEC.1 through SEC.11A are green/DONE. Preserve all prior API, Android, localization, and cross-module behavior.

## Canonical Contract

Statuses remain exact:

```text
Open
Acknowledged
Resolved
```

Stable Security codes remain exact:

```text
EMERGENCY_ALERT_NOT_FOUND
EMERGENCY_ALREADY_TAKEN
EMERGENCY_ALREADY_RESOLVED
EMERGENCY_NOT_ACKNOWLEDGED
EMERGENCY_ASSIGNED_TO_OTHER
VALIDATION_ERROR
UNAUTHENTICATED
FORBIDDEN
SERVER_ERROR
```

Flutter branches on code/status, never localized backend `message`.

## Implemented Architecture

```text
EmergencyAlertRepository
├── ApiEmergencyAlertRepository
│   └── shared SecurityApiClient
└── MockEmergencyAlertRepository

SecurityAppShell
├── refresh active queue on creation/login
├── refresh on app resume
├── 15s foreground polling in API mode
├── refresh after acknowledge/resolve
└── persistent EmergencyAlertOverlay for first Open alert
```

API mode enables foreground polling. Mock mode performs the initial deterministic read but does not keep a periodic timer running, keeping widget tests stable.

## Persistent Modal Rule

`GET /api/security/emergency-alerts/active` is the only modal source of truth.

- only `Open` alerts appear in the modal queue;
- modal cannot be dismissed locally;
- acknowledge is the only operational action that removes that alert from the queue;
- first authorized Security wins server ownership atomically;
- `EMERGENCY_ALREADY_TAKEN`, resolved/not-found races trigger a queue refresh;
- a known Open alert is not silently removed merely because a foreground network refresh fails.

## Operational Emergency Screen

The previous Emergency concept card is promoted to an operational module. It provides:

- unresolved `Open + Acknowledged` list;
- resolved history;
- alert detail;
- acknowledge/take for `Open`;
- resolve only for `Acknowledged && taken_by_me`;
- optional resolution notes;
- backend-owned timestamps/actor fields displayed read-only.

## Localization

APH.35C/APH.37 runtime rules remain active:

```text
Accept-Language: id|en
Content-Language: id|en
fallback: en
```

UI labels use the catalog mapping:

```text
Open          → Terbuka / Open
Acknowledged  → Diambil Security / Acknowledged
Resolved      → Selesai / Resolved
```

## Explicit Deferrals

SEC.12 does not implement or imply:

- panic-button hardware;
- GPS/location proof;
- CCTV/NVR automation;
- external siren/alarm panel;
- Firebase/APNs push provider;
- automatic Incident creation;
- automatic Service Request creation.

## APH.38 Queue

Backend APH.38 also contracts Security Package Receiving through the existing Package Center / `resident_packages` domain. That frontend integration is deliberately isolated to SEC.13.

Do not create a Security-only package table/domain.

## Files Changed / Added

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/features/emergency/**
lib/features/security/data/mock/security_home_mock_data.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/api_emergency_alert_repository_test.dart
test/mock_emergency_alert_repository_test.dart
test/app_dependencies_test.dart
test/widget_test.dart
docs/API_CONTRACT_EMERGENCY_SOS_V1.md
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/API_CONTRACT_SECURITY_PACKAGE_V1.md
docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json
docs/postman/Aparthub_Emergency_SOS_V1.postman_collection.json
docs/postman/Aparthub_Security_Package_V1.postman_collection.json
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/SEC.12_CONTEXT.md
```


## Validation Attempt 1 — 18 Aug 2026

Result:

```text
flutter analyze           ✅ No issues found
flutter test              ❌ 2 widget assertions
flutter build apk --debug ✅ Built app-debug.apk
```

The two failures were test expectation/viewport drift introduced by promoting Emergency from concept to operational:

- Home test still expected the old label `Emergency Response`; the operational module is now `Emergency SOS`.
- More/catalog test counted four `ACTIVE` chips before the lazy `ListView` mounted the fourth active Emergency card.

Validation hotfix v1 is test-only: update the label expectation and scroll to `Emergency SOS` before asserting the active module. No production API, Emergency lifecycle, polling, localization, repository, Android, or dependency behavior changes.

## Validation Closure

User confirmed validation hotfix v1 green on 18 Aug 2026. SEC.12 is locked `DONE`.

```text
flutter analyze           ✅
flutter test              ✅
flutter build apk --debug ✅
```

## Next Checkpoint

After SEC.12 green:

```text
SEC.13 — Security Package Receiving → Package Center
```

SEC.13 uses APH.38 endpoints and the existing Package Center source of truth.

## New Chat Bootstrap

```text
Continue Aparthub Security Flutter from SEC.12.

Locked cumulative baseline:
- SEC.1 through SEC.11A are DONE.
- Visitor Verification, Patrol Management and Incident Reporting are API-integrated.
- Patrol checkpoint -> Incident cross-module flow is green.
- ID/EN localization sends Accept-Language and reads Content-Language; canonical values/error codes remain exact.
- Android baseline remains flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, kotlin.incremental=false.

Current checkpoint:
SEC.12 — Emergency SOS Resident -> Security.

Implemented:
- EmergencyAlertRepository with API/mock implementations.
- GET /emergency-alerts/active is the persistent modal source of truth.
- Refresh on app shell creation/login, app resume, after mutations, and every 15 seconds while foreground in API mode.
- Open -> Acknowledged -> Resolved canonical lifecycle.
- First acknowledge wins; owner-only resolve; branch on stable EMERGENCY_* code.
- Operational unresolved/history/detail Emergency screen.
- Bahasa Indonesia + English labels aligned to APH.37/APH.38 catalog.
- No panic hardware, GPS, CCTV, push provider, external alarm, or automatic Incident creation.

Run:
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug

If all green, lock SEC.12 DONE and proceed SEC.13 Security Package Receiving -> existing Package Center / resident_packages using APH.38. Do not create parallel Security package persistence.
```
