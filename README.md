# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-06 adds a Task Detail step for generic mock dispatch work before the existing Task Response lifecycle. The detail view exposes the task ID, location, priority, source, creation time, current status, and handling instruction, then hands the officer into the established response workflow. Patrol, Visitor, and Incident Active Tasks still open their domain-specific modules directly.

Task metadata remains mock/in-memory for this MVP and does not introduce a task backend contract or persistence. The NS-MOB-05 operational History flow remains unchanged, NS-MOB-02 mock-first behavior remains the default, and the legacy `/api/security/...` integration is still available as an optional compatibility mode.

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
