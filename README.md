# NSecure

NSecure is the standalone Flutter mobile application for security operations, extracted from the former Aparthub Security mobile codebase.

## Current phase

NS-MOB-01 focuses only on standalone product identity. Existing application flows and the legacy `/api/security/...` integration are intentionally preserved for compatibility during this phase.

Backend decoupling and mock-first standalone operation are planned for NS-MOB-02.

## Development

This project is pinned to Flutter 3.47.5 through FVM.

```powershell
fvm flutter pub get
fvm flutter gen-l10n
fvm flutter analyze
fvm flutter test
fvm flutter build apk --debug
```
