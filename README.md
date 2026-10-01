# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-03 realigns the standalone MVP home experience around day-to-day security operations. In default mock mode, Home now surfaces deterministic active-task previews for Patrol, Visitor Verification, and Incident handling, while the existing operational modules remain available as quick actions.

The task previews are local MVP data only and route into the existing operational flows; they do not introduce a new backend contract. NS-MOB-02 mock-first behavior remains unchanged, and the legacy `/api/security/...` integration is still available as an optional compatibility mode.

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
