# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-04 adds a mock-first Task Response MVP on top of the active tasks introduced in NS-MOB-03. In default mock mode, an active task now opens an in-memory response lifecycle: accept the task, head to the location, arrive, start handling, attach deterministic MVP evidence, and complete the task. Completed tasks are removed from the current in-memory Active Tasks list.

This milestone does not introduce a task backend contract or persistence. Existing Patrol, Visitor, Incident, Emergency, and Package modules remain unchanged and available through Quick Actions. NS-MOB-02 mock-first behavior remains unchanged, and the legacy `/api/security/...` integration is still available as an optional compatibility mode.

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
