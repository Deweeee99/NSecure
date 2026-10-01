# SEC.14 Context — Final Production Readiness / Security Mobile Closure

Status: **IMPLEMENTED / FINAL VALIDATION PENDING**

Date opened: 18 Aug 2026

## Objective

Close the contracted software-only Aparthub Security Mobile V1 without adding new product scope.

Cumulative operational baseline:

```text
Visitor Verification
Patrol Management
Incident Reporting
Emergency SOS
Package Receiving
Bahasa Indonesia + English
Sanctum Security session
Android QR camera + Manual fallback
```

## Locked Input Baseline

SEC.1 through SEC.13 are green/DONE. SEC.13 Package Receiving validation hotfix v1 was confirmed fully green by the user on 18 Aug 2026.

SEC.14 must preserve all cumulative behavior and only harden final production composition/validation.

## Implemented Production Hardening

`AppDependencies.fromEnvironment()` now delegates to testable runtime configuration rules:

```text
debug/test + empty SECURITY_API_BASE_URL → deterministic mock allowed
release + empty SECURITY_API_BASE_URL    → fail closed
configured base not ending /api/security → fail closed
release + non-HTTPS base                 → fail closed
valid release HTTPS /api/security base   → full API composition
```

Release API composition explicitly wires:

```text
Security Auth
Visitor
Patrol
Incident
Emergency SOS
Package Receiving
API localization
real QR scanner
Emergency foreground polling
```

No new dependency or state-management framework is introduced.

## Final Automated Readiness Test

New `test/sec14_production_readiness_test.dart` verifies:

- debug empty config remains deterministic mock-only;
- release cannot silently enter mock mode;
- wrong API prefix is rejected;
- non-HTTPS release API is rejected;
- valid release config wires every contracted software module to its API repository and enables production runtime capabilities.

## Release Validation Utility

`tool/sec14_validate.ps1` runs:

```text
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release --dart-define=SECURITY_API_BASE_URL=<https ... /api/security>
```

Default `example.invalid` URL is compile-only and is never production connectivity evidence.

## Real Device / Backend Gate

`docs/PRODUCTION_READINESS.md` is the source of truth for final manual smoke. At minimum validate:

- login/session restore/logout/session expiry;
- ID/EN locale persistence + API negotiation;
- Visitor manual + QR + check-in/out + history;
- Patrol start/checkpoints/complete/history;
- Patrol → Incident linked checkpoint `Issue` flow;
- Incident create/detail/timeline/ack/start/resolve/note/history;
- persistent Emergency Open modal, first-wins acknowledge, owner resolve;
- Package Resident lookup/receive/detail/collect and Package Center source-of-truth visibility;
- controlled network/timeout/401/403 behavior.

SEC.14 is not `DONE` on automated Flutter green alone. Real Android + real backend smoke must also be green.

## Explicit Non-Goals / Hardware Boundary

SEC.14 does not activate or imply:

```text
panic-button hardware
GPS proof-of-presence
CCTV/NVR automation
external siren/alarm
push provider
ANPR/LPR/barrier
RFID/NFC/BLE proof
Device Registry / telemetry
dedicated package/QR scanner hardware
package photo evidence
smart lockers
proof-of-handover hardware
```

Access Control and Vehicle Management remain HOLD/concept.

## Known Non-Blocking Technical Debt

The current `mobile_scanner` Kotlin Gradle Plugin warning is future-compatibility debt, not a current build blocker. Preserve the green Android baseline during SEC.14:

```text
flutter_secure_storage 10.3.1
mobile_scanner 7.4.0
kotlin.incremental=false
```

Do not upgrade toolchain/dependencies solely to silence the warning during final closure.

## Files Changed / Added

```text
lib/core/bootstrap/app_dependencies.dart
test/sec14_production_readiness_test.dart
tool/sec14_validate.ps1
docs/PRODUCTION_READINESS.md
docs/ROADMAP.md
docs/CHECKPOINTS.md
docs/SECURITY_MOBILE_PRD.md
docs/ARCHITECTURE.md
docs/FRONTEND_SPEC.md
docs/checkpoints/SEC.13_CONTEXT.md
docs/checkpoints/SEC.14_CONTEXT.md
```

## Validation Gate

Automated:

```powershell
cd E:\aparthub_security
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File .\tool\sec14_validate.ps1
```

After automated green, run real-device/backend smoke with the actual HTTPS API host.

## Closure Rule

Only mark SEC.14 `DONE` when:

```text
automated Flutter gate ✅
release compile ✅
real Android smoke ✅
real backend smoke ✅
ID/EN smoke ✅
```

## Next

After SEC.14 closure there is no automatic SEC.15 product checkpoint. New Security scope must come from a new explicit backend/product/hardware contract.

## New Chat Bootstrap

```text
Continue Aparthub Security Flutter from SEC.14.

Locked cumulative baseline:
- SEC.1 through SEC.13 are DONE.
- Operational software modules: Visitor Verification, Patrol Management, Incident Reporting, Emergency SOS, Package Receiving.
- ID/EN runtime localization sends Accept-Language and reads Content-Language; canonical statuses/error codes remain exact.
- Android baseline: flutter_secure_storage 10.3.1, mobile_scanner 7.4.0, kotlin.incremental=false.
- Emergency uses /emergency-alerts/active as durable modal source of truth.
- Package Receiving writes to existing Package Center / resident_packages; no parallel package domain.

Current checkpoint:
SEC.14 — Final Production Readiness / Security Mobile Closure.

Implemented:
- AppDependencies runtime config hardening.
- Release cannot fall back to mock.
- Production API base must end /api/security and release requires HTTPS.
- sec14 production-readiness tests.
- tool/sec14_validate.ps1 automated validation runner.
- docs/PRODUCTION_READINESS.md final real-device/backend smoke matrix.

Run automated gate:
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build apk --release --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security

If automated gate is green, do not mark DONE yet. Run real Android + actual backend smoke from docs/PRODUCTION_READINESS.md. Lock SEC.14 DONE only after both automated and real smoke gates are green.
```
