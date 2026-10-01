# SEC.13 Context — Security Package Receiving → Package Center

Status: **DONE**

Date opened: 18 Aug 2026

## Objective

Implement the APH.38 Security Mobile package workflow as an additional operational channel into the existing Package Center domain.

```text
Package arrives
→ Security searches Resident / Unit
→ Security registers package
→ backend creates existing resident_packages row
→ Web Admin Package Center + Resident Mobile see the same record
→ Security or Web Admin can mark it Collected
```

## Locked Input Baseline

SEC.1 through SEC.12 are green/DONE. Preserve Visitor, Patrol, Incident, Emergency SOS, Android readiness, and ID/EN runtime localization behavior.

## Canonical Backend Contract

Base Security routes:

```text
GET  /api/security/packages/residents/search
GET  /api/security/packages
POST /api/security/packages
GET  /api/security/packages/{residentPackage}
POST /api/security/packages/{residentPackage}/collect
```

Canonical package status values remain exact:

```text
Ready for Pickup
Collected
Expired
```

Stable package machine codes remain exact:

```text
PACKAGE_CENTER_UNAVAILABLE
PACKAGE_RESIDENT_NOT_FOUND
PACKAGE_NOT_FOUND
VALIDATION_ERROR
UNAUTHENTICATED
FORBIDDEN
```

Flutter branches on stable code/status and never localized backend `message`.

## Persistence Boundary

SEC.13 does not introduce Security-specific package persistence. Backend APH.38 writes to existing:

```text
resident_packages
```

The Flutter app never sends/manufactures:

```text
package_no
property_id
unit_id
status
received_by_user_id
received_at
collected_by_user_id
collected_at
```

`property_id` is only an optional lookup/list selector among already-authorized properties; receive resolves property/unit from the selected Resident on the server.

## Implemented Architecture

```text
PackageManagementScreen
        ↓
SecurityPackageRepository
   ├── MockSecurityPackageRepository
   └── ApiSecurityPackageRepository
             ↓
       SecurityApiClient
       shared Sanctum + locale
```

The repository supports:

- active Resident/Unit lookup;
- package list with status/search/property filters;
- package detail;
- receive/register package;
- idempotent collect package.

API list pagination is consumed safely up to a bounded page count. Unknown canonical package statuses fail closed rather than being coerced.

## Operational UI

Package Receiving is now ACTIVE on Home and More.

Dashboard:

- Package Center source-of-truth notice;
- package search;
- All / Ready for Pickup / Collected / Expired filters;
- receive package CTA;
- package list and detail.

Receive workflow:

- search Resident by name/mobile/email/unit/tower;
- select authorized active Resident/Unit;
- required courier;
- optional tracking number, sender, description, storage location, notes;
- submit only documented client-owned fields.

Detail workflow:

- server-owned package number/status/context/timestamps/actors are read-only;
- only `Ready for Pickup` exposes `Mark Collected`;
- optional collection notes;
- already `Collected` is treated as durable/idempotent state.

## Localization

APH.35C / APH.38 rules remain active:

```text
Accept-Language: id|en
Content-Language: id|en
fallback: en
```

Display mapping:

```text
Ready for Pickup → Siap Diambil / Ready for Pickup
Collected        → Sudah Diambil / Collected
Expired          → Kedaluwarsa / Expired
```

Canonical wire values are never translated.

## Deliberate Deferrals / Limitations

SEC.13 does not implement or imply:

- courier API integrations;
- barcode scanner hardware;
- dedicated package scanner;
- package photo/evidence upload;
- smart lockers;
- Firebase/APNs push provider;
- automatic notification timestamps;
- proof-of-handover hardware;
- a parallel Security package table/domain.

`notified_at` remains backend/Package Center-owned and is only displayed when provided.

## Backend Dependencies

Canonical source documents:

```text
docs/API_CONTRACT_SECURITY_PACKAGE_V1.md
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json
docs/postman/Aparthub_Security_Package_V1.postman_collection.json
docs/backend/APH.38_CONTEXT.md
```

Backend APH.38 was supplied as implementation/regression-pending. Mobile validation does not claim backend production regression status.

## Files Changed / Added

```text
lib/app.dart
lib/core/bootstrap/app_dependencies.dart
lib/features/package/**
lib/features/security/data/mock/security_home_mock_data.dart
lib/features/security/presentation/home/security_home_screen.dart
lib/features/security/presentation/concepts/security_module_catalog_screen.dart
lib/features/security/presentation/shell/security_app_shell.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/api_security_package_repository_test.dart
test/mock_security_package_repository_test.dart
test/app_dependencies_test.dart
test/widget_test.dart
docs/backend/APH.38_CONTEXT.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/SECURITY_MOBILE_PRD.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/DESIGN_SYSTEM.md
docs/checkpoints/SEC.12_CONTEXT.md
docs/checkpoints/SEC.13_CONTEXT.md
```

## Validation Attempt 1 — 18 Aug 2026

```text
flutter analyze           ✅ No issues found
flutter test              ❌ 1 widget-test helper failure
flutter build apk --debug ✅ Built app-debug.apk
```

Failing test:

```text
Package Receiving registers and collects through Package Center flow
```

Failure:

```text
Bad state: No element
WidgetController.scrollUntilVisible / dragUntilVisible
```

Root cause is test-only. The Package receive screen uses a lazy `ListView`; the existing test called `scrollUntilVisible()` with `find.byType(Scrollable).last`, and that generic scrollable finder did not resolve while `packageCourierField` was still unmounted. This does not indicate a repository/API/UI production failure.

Validation hotfix v1 changes only `test/widget_test.dart` to use a bounded `_dragListUntilMounted()` helper against the active Package `ListView`. It is applied both before entering the courier field and before entering collection notes so both lazy fields follow the same deterministic test strategy. No production source, API contract, localization, dependency, or Package Center behavior changes.

## Validation Evidence / Gate

Container environment does not include Flutter/Dart, so the automated Flutter gate must be executed in the project environment.

```powershell
cd E:\aparthub_security
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
```

The user confirmed the SEC.13 validation hotfix v1 full gate green on 18 Aug 2026. SEC.13 is locked `DONE`.

## Validation Closure — 18 Aug 2026

The user confirmed the post-hotfix full Flutter gate green:

```text
flutter analyze           ✅
flutter test              ✅
flutter build apk --debug ✅
```

SEC.13 is locked `DONE`. Package Receiving is part of the cumulative green software baseline.

## Next Checkpoint

After SEC.13 automated gate is green:

```text
SEC.14 — Final Production Readiness / Security Mobile Closure
```

SEC.14 should focus on final cross-module real-device/backend smoke and production readiness, not invent new product scope.

## New Chat Bootstrap

```text
Continue Aparthub Security Flutter from SEC.13.

Locked cumulative baseline:
- SEC.1 through SEC.12 are DONE.
- Visitor Verification, Patrol Management, Incident Reporting, and Emergency SOS are operational/API-integrated.
- Patrol checkpoint -> Incident linked flow is green.
- ID/EN runtime localization sends Accept-Language and reads Content-Language; canonical statuses/error codes stay exact.
- Android baseline remains flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, kotlin.incremental=false.
- Emergency uses /emergency-alerts/active as durable persistent modal source of truth.

Current checkpoint:
SEC.13 — Security Package Receiving -> existing Package Center / resident_packages.

Implemented:
- SecurityPackageRepository with API/mock implementations.
- Resident/Unit lookup through GET /packages/residents/search.
- Package list/filter/search/detail.
- Receive through POST /packages with resident_id + documented client-owned fields only.
- Collect through POST /packages/{id}/collect with optional collection_notes.
- Canonical statuses exact Ready for Pickup / Collected / Expired.
- Stable PACKAGE_* code mapping; never branch on localized message.
- Package Receiving ACTIVE on Home/More.
- ID/EN package labels aligned to APH.38 catalog.
- No parallel package persistence, barcode hardware, package photo, smart locker, or push provider.

Run:
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug

If all green, lock SEC.13 DONE and proceed SEC.14 Final Production Readiness / Security Mobile Closure.
```
