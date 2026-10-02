# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-05 adds an operational History overview for the mock-first Task Response flow. Completed dispatch tasks are removed from Active Tasks and retained in-memory for the current app session with their task identity, completion time, and deterministic MVP evidence filename. The History tab now opens this operational overview first and keeps the existing Visitor Verification History available as a dedicated entry.

This milestone still does not introduce a task backend contract or persistence. Existing Patrol, Visitor, Incident, Emergency, Package, and Visitor History behavior remain available. NS-MOB-02 mock-first behavior remains unchanged, and the legacy `/api/security/...` integration is still available as an optional compatibility mode.

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
