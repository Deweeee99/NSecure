# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-02 makes the application mock-first and backend-independent for the MVP. NSecure runs with deterministic local mock repositories when no API base URL is supplied, including release builds.

The legacy `/api/security/...` integration remains available as an optional compatibility mode. It is no longer a required dependency for running the NSecure MVP.

## Runtime modes

Default standalone MVP mode:

```powershell
fvm flutter run
```

Optional legacy API compatibility mode:

```powershell
fvm flutter run --dart-define=SECURITY_API_BASE_URL=https://<host>/api/security
```

When an API URL is supplied, existing validation remains in place: the URL must end with `/api/security`, and release API mode requires HTTPS.

## Development

This project is pinned to Flutter 3.47.5 through FVM.

```powershell
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
```

Historical Aparthub handoff/checkpoint documents are retained as donor-contract references and may describe the former release guardrail that required an API URL.
