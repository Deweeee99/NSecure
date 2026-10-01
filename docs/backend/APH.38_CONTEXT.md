# APH.38 Context — Security Package Receiving → Package Center

Updated: 2026-08-14

## Status

```text
APH.38 — Security Package Receiving → Package Center
IMPLEMENTED — LOCAL REGRESSION PENDING
```

APH.37 Emergency SOS targeted + full regression were confirmed green and are locked DONE.

## Goal

Use Security Mobile as an additional operational channel for the existing Package Center lifecycle:

```text
Package arrives
→ Security searches Resident / Unit
→ Security registers package
→ existing resident_packages row is created
→ Web Admin Package Center sees the same record
→ Resident Mobile can read the same record
→ Security or Web Admin can mark it Collected
```

No parallel Security package domain is introduced.

## Persistence

Existing table only:

```text
resident_packages
```

Existing canonical statuses remain exact:

```text
Ready for Pickup
Collected
Expired
```

No migration is required by APH.38.

## Security API

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

Detailed contract:

```text
docs/API_CONTRACT_SECURITY_PACKAGE_V1.md
```

## Authorization

Base Security authorization remains:

```text
active authenticated User
+ security-management permission
+ explicit SecurityPropertyScope property assignment
+ effective security-management entitlement
```

Package operations additionally require effective `package-center` entitlement on the property.

Security mutations use:

```text
security-management:create → receive package
security-management:update → collect package
```

No web `CurrentProperty` session is used by the Security API.

## Audit

Security receiving reuses the existing events:

```text
package.registered
package.collected
```

with audit metadata:

```text
source = security-mobile
```

`received_by_user_id` / `collected_by_user_id` point to the authenticated Security user.

## Localization

APH.38 extends APH.35C/APH.37 ID/EN catalogs.

Stable Security package error codes:

```text
PACKAGE_CENTER_UNAVAILABLE
PACKAGE_RESIDENT_NOT_FOUND
PACKAGE_NOT_FOUND
```

Canonical package statuses and machine codes are never translated.

## Files introduced / changed

```text
app/Http/Controllers/Api/ResidentPackageController.php
app/Http/Controllers/Api/SecurityPackageController.php
app/Services/SecurityOperations/SecurityPackageMobileService.php
routes/api.php
lang/en/api.php
lang/id/api.php
tests/Feature/SecurityPackageReceivingApiFeatureTest.php
docs/API_CONTRACT_SECURITY_PACKAGE_V1.md
docs/API_CONTRACT_SECURITY_PLATFORM_V1.md
docs/API_CONTRACT_SECURITY_MOBILE_V1.md
docs/API_CONTRACT_RESIDENT_V1.md
docs/APARTHUB_MOBILE_LOCALIZATION_CATALOG.json
docs/MOBILE_LOCALIZATION_HANDOFF.md
docs/CROSS_APP_INTEGRATION_MATRIX.md
docs/ARCHITECTURE.md
docs/DECISIONS.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/checkpoints/APH.37_CONTEXT.md
docs/checkpoints/APH.38_CONTEXT.md
docs/postman/Aparthub_Security_Package_V1.postman_collection.json
```

## Validation gate

No migration is required.

Targeted:

```powershell
php artisan optimize:clear

php artisan test --compact `
  tests\Feature\SecurityPackageReceivingApiFeatureTest.php `
  tests\Feature\PackageCenterFeatureTest.php `
  tests\Feature\SecurityMobileIntegrationContractTest.php `
  tests\Feature\ApiLocalizationFeatureTest.php
```

If targeted is green:

```powershell
php artisan test --compact
```

## Locked boundary

APH.38 does not implement courier integrations, barcode hardware, package photo capture, push providers, smart lockers, or automatic proof-of-handover hardware.

## Next

After targeted + full regression are green:

```text
APH.38 ✅ DONE
APH.39 ▶ Final Cross-App Regression SOS + Package
```
