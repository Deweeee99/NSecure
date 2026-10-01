# Aparthub Security Mobile — Android Readiness

## Purpose

This document is the operational checklist for SEC.8. It covers the active Visitor Verification MVP only. Future Security modules remain presentation-only.

## 1. One-time SEC.8 project preparation

After extracting the SEC.8 patch, run:

```powershell
cd E:\aparthub_security
powershell -ExecutionPolicy Bypass -File .\tool\sec8_prepare_android.ps1
```

The script:

- adds `flutter_secure_storage:^10.3.1`;
- adds `mobile_scanner:^7.4.0`;
- disables Android application backup (`android:allowBackup="false"`) so the persisted Security bearer token is not restored through Android backup;
- declares `android.permission.INTERNET` for release/API networking;
- declares `android.permission.CAMERA` for QR capture;
- marks `android.hardware.camera.any` as `required="false"` so camera hardware is optional and Manual Verification remains a viable operational path.

The script intentionally edits the existing `pubspec.yaml`, `pubspec.lock`, and Android manifest in-place rather than shipping stale copies of generated project files.

## 2. Runtime modes

### Development / deterministic mock

When `SECURITY_API_BASE_URL` is absent in a non-release build, the app keeps deterministic mock mode:

```powershell
flutter run
```

Mock mode:

- does not open the device camera;
- keeps the deterministic QR sample path for automated/widget testing;
- does not require backend availability.

### API / device mode

```powershell
flutter run `
  --dart-define=SECURITY_API_BASE_URL=https://<host>/api/security
```

API mode enables:

- Security login;
- secure bearer-token persistence;
- session restoration through `/me`;
- real device QR camera scanning;
- Visitor Search, QR validation, Check-In, Check-Out, and History against the final Security Mobile V1 contract.

The QR payload must be forwarded exactly as detected. Do not trim, change case, wrap as JSON text, regenerate, or substitute `visit_code`.

## 3. Release safety

Release mode is fail-closed:

- `SECURITY_API_BASE_URL` is mandatory;
- mock fallback is disabled;
- the base URL must be an absolute HTTP/HTTPS URL;
- release mode requires HTTPS;
- query strings and fragments are rejected from the configured base URL.

Compile-only release check:

```powershell
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

For an actual deployment artifact, replace the example host with the real HTTPS backend host and apply the organization's Android signing process.

## 4. Session behavior

- Login token is stored only in platform secure storage, never SharedPreferences or a source file.
- Startup reads the stored token and validates it through `/security/me` before opening the operational shell.
- Invalid/forbidden restored sessions fail closed and return to login.
- Logout revokes the current Sanctum token when possible and always clears local secure storage.
- A Visitor API `UNAUTHENTICATED` result exits the operational shell and clears the local session.
- Network failures do not silently convert to auth failures.

Passwords are never persisted.

## 5. QR operational behavior

API mode uses the Android camera scanner. Manual Verify remains available at all times as the first-class fallback path.

Expected field operation:

1. Open **Verify**.
2. Camera scanner starts.
3. Scan the Resident QR credential.
4. The raw QR payload is validated by the backend.
5. Visitor result/detail is shown.
6. Check-In uses `verification_method=qr` and sends the same raw credential.

If camera access is unavailable or denied, the scanner panel shows an explicit unavailable state and the officer can continue with **Enter Code Manually**.

## 6. Network resilience

The low-level Security API client applies a finite request timeout and maps socket/TLS/timeout failures into a stable frontend network failure. Verification History provides an explicit retry state instead of failing the widget tree.

## 7. Required automated gate

```powershell
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

SEC.8 must not be locked `DONE` until all commands are green.

Recommended release compile gate:

```powershell
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

## 8. Required real-device smoke test before production

Use a reachable backend and an Android device:

- login with a permitted Security user;
- close/reopen app and verify session restoration;
- logout and verify session is removed;
- deny camera permission and confirm Manual Verify is still usable;
- allow camera permission and scan a valid QR;
- scan invalid/expired QR cases;
- manual search by `visit_code` and numeric `visit_id`;
- Approved → Check-In;
- Checked In → Check-Out;
- verify backend actor/timestamps appear in confirmation/detail;
- open History;
- disable network and verify error/retry behavior;
- invalidate/revoke token and verify app returns to login;
- confirm Patrol/Incident/Emergency/Access/Vehicle remain presentation-only.

## 9. Explicit non-goals

SEC.8 does not activate:

- Patrol API;
- Incident API;
- Emergency automation;
- Access Control hardware;
- Vehicle gate hardware;
- remote Security Dashboard counters without a final response schema;
- iOS production-readiness/signing work.

## SEC.8 validation hotfix v2 — AGP / compileSdk alignment

Validation showed the project is on Android Gradle Plugin `9.0.1` while the first SEC.8 preparation forced `compileSdk = 37`. AGP 9.0 supports up to API 36.1, so API 37 is outside this project's current Android build-tool baseline.

SEC.8 does not require an AGP/Gradle migration merely to persist the Sanctum token. The low-risk alignment is therefore:

```text
flutter_secure_storage ^10.3.1
mobile_scanner ^7.4.0
compileSdk = flutter.compileSdkVersion
```

The preparation script now applies those values and no longer forces or verifies an `android-37` platform path. Do not rerun an older SEC.8 preparation script after applying this hotfix.

