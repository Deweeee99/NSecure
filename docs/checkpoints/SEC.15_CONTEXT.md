# SEC.15 Context — APH.42 Security Patrol Checkpoint Photo Evidence

Updated: 2026-08-18

## Status

```text
SEC.15 — APH.42 Security Patrol Checkpoint Photo Evidence
DONE
```

## Objective / Scope

Integrate the confirmed APH.42 backend contract into the existing Flutter Patrol flow without changing backend routes, canonical wire values, authorization semantics, or unrelated Security Mobile modules.

Scope:

```text
Patrol Detail additive photo_evidence decoding
Complete Checkpoint — required photo + optional notes via multipart/form-data
Skip Checkpoint — required notes + optional photo; JSON without photo, multipart with photo
Camera / Gallery source chooser
Selected-photo preview + Remove / Retake / Change
Existing checkpoint photo proof display
Temporary signed URL consumption from backend payload only
ID / EN presentation strings
Targeted repository / transport / widget regression coverage
```

Backend remains the source of truth for status, timestamps, actor, scope, and signed photo URLs.

## Backend Contract Locked

Base remains:

```text
/api/security
```

Existing Patrol routes are reused exactly:

```text
GET  /api/security/patrol/sessions/{patrol_session_id}
POST /api/security/patrol/checkpoint-visits/{visit_id}/complete
POST /api/security/patrol/checkpoint-visits/{visit_id}/skip
```

Mutation identity is always `visit_id`; `checkpoint_id` is never used in the mutation path.

Canonical Patrol statuses remain exact:

```text
Scheduled
In Progress
Completed
Cancelled
```

Canonical checkpoint visit statuses remain exact:

```text
Pending
Completed
Skipped
Issue
```

## Implementation

### Domain model

Added `PatrolCheckpointPhotoEvidence` for the additive `photo_evidence` object and `PatrolPhotoInput` for local upload metadata. Maximum accepted size is 5 MB and accepted MIME types are exactly:

```text
image/jpeg
image/png
image/webp
```

### API decoder

`PatrolApiDecoder.decodeCheckpoint()` now accepts:

```text
photo_evidence = object | null
```

The client reads only backend-returned fields:

```text
url
original_name
mime_type
file_size
uploaded_at
```

No `photo_path` is expected or synthesized.

### Multipart transport

The existing `IoSecurityApiClient` now also implements a narrow `SecurityMultipartApiClient` capability. Multipart requests preserve the existing:

```text
Authorization: Bearer <token>
Accept: application/json
Accept-Language: id | en
Content-Language response tracking
```

No new API endpoint was added.

### Complete Checkpoint

Repository contract now requires `PatrolPhotoInput` for `completeCheckpoint()`.

The API implementation posts to the existing exact route:

```text
/patrol/checkpoint-visits/{visit_id}/complete
```

Multipart fields:

```text
photo = required
notes = optional
```

The Flutter client does not send status, checked_at, officer/actor IDs, property IDs, or checkpoint_id. After a successful mutation, the repository refreshes Patrol Detail through the existing session detail endpoint so the UI uses canonical backend state and refreshed signed URL data.

### Skip Checkpoint

`skipCheckpoint()` keeps notes mandatory.

Without a photo it uses the existing JSON request:

```json
{"notes":"..."}
```

With a photo it switches to multipart using the same existing skip route and sends only:

```text
notes
photo
```

### Flutter UX

Complete flow:

```text
Pending checkpoint
→ Complete
→ Camera / Gallery
→ Preview
→ Remove / Retake / Change
→ optional notes
→ multipart submit
→ success
→ refreshed Patrol Detail
→ Completed + photo evidence
```

Skip flow:

```text
Pending checkpoint
→ Skip
→ mandatory reason
→ optional Camera / Gallery photo
→ JSON or multipart submit
→ success
→ refreshed Patrol Detail
```

Existing photo evidence is rendered from `checkpoint.photo_evidence.url`. The signed URL is neither persisted as a permanent reference nor reconstructed from an internal storage path. Patrol Detail is pull-to-refresh capable so an expired signed URL can be replaced by a fresh backend response.

A network ambiguity message explicitly instructs the officer to refresh Patrol Detail before retrying a checkpoint mutation. The client does not automatically retry mutation requests.

### Localization

Added ID/EN client strings for photo requirements, camera/gallery selection, preview actions, validation, signed-link refresh guidance, and ambiguous-network refresh guidance. Canonical backend values remain untranslated.

### Native picker setup

Added `image_picker` as the camera/gallery bridge. iOS usage descriptions were added for camera and photo library access. Existing Android camera permission remains intact; no Patrol-specific hardware integration is introduced.

## Files Changed / Created

```text
ios/Runner/Info.plist
pubspec.yaml
lib/core/network/security_api_client.dart
lib/features/patrol/domain/models/patrol_models.dart
lib/features/patrol/domain/repositories/patrol_repository.dart
lib/features/patrol/data/api/patrol_api_decoder.dart
lib/features/patrol/data/api/api_patrol_repository.dart
lib/features/patrol/data/mock/mock_patrol_repository.dart
lib/features/patrol/presentation/patrol_management_screen.dart
lib/features/patrol/presentation/services/patrol_photo_picker.dart
lib/l10n/app_en.arb
lib/l10n/app_id.arb
test/security_api_localization_test.dart
test/api_patrol_repository_test.dart
test/mock_patrol_repository_test.dart
test/patrol_photo_evidence_widget_test.dart
docs/checkpoints/SEC.15_CONTEXT.md
```

Generated localization Dart files are deliberately not patched; `flutter gen-l10n` regenerates them from the ARB source.

## Deliberate Deferrals / Exclusions

APH.42 does not activate or add:

```text
GPS checkpoint proof
QR checkpoint scanning
NFC
RFID
beacon proof
device registry
scan-token proof
public photo storage
custom file-path construction
new backend endpoints
automatic mutation retry
```

Photo evidence is the current checkpoint proof.

## Known Limitations

- Selected camera images are temporary local files until uploaded; Flutter does not treat the local path as durable evidence.
- Android low-memory `image_picker.retrieveLostData()` recovery is not promoted into a new application-level recovery workflow in this checkpoint. Normal camera/gallery selection and upload are covered; lifecycle-destruction recovery remains a narrowly scoped follow-up only if field testing demonstrates it is needed.
- Signed photo URLs can expire by design. The UI instructs the officer to refresh Patrol Detail rather than storing or rebuilding the URL.

## Backend Dependencies

Required backend state is the confirmed APH.42 implementation:

```text
Patrol Detail exposes photo_evidence object|null
Complete requires multipart photo
Skip requires notes and optionally accepts multipart photo
private evidence is exposed only via backend temporary signed URL
server owns status / checked_at / officer_user_id
```

Stable errors consumed through the existing Patrol error mapping include:

```text
VALIDATION_ERROR
PATROL_CHECKPOINT_NOT_FOUND
PATROL_NOT_IN_PROGRESS
PATROL_CHECKPOINT_ALREADY_PROCESSED
FORBIDDEN
```

## Validation Evidence / Gate

Static checks performed in the patch workspace:

```text
ARB JSON parse                       PASS
Info.plist XML parse                 PASS
endpoint inventory audit             PASS — no new Patrol endpoint
visit_id mutation-path audit         PASS
changed-file ZIP integrity           REQUIRED before handoff
```

The execution environment used to prepare this patch does not contain Flutter/Dart, so executable Flutter validation must be run in the real project after applying the patch.

Targeted gate:

```powershell
flutter pub get
flutter gen-l10n

flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
```

Full gate:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

Because this checkpoint adds a native camera/gallery plugin, release compile should also be rechecked after the full gate is green:

```powershell
flutter build apk --release `
  --dart-define=SECURITY_API_BASE_URL=https://example.invalid/api/security
```

`example.invalid` is compile-only. Runtime smoke must use the real Security API host.

SEC.15 was locked DONE after the user confirmed the targeted suite, analyzer, full regression, and debug APK gate green on 19 Aug 2026.

## Next Checkpoint

No automatic SEC.16 product scope is opened by this checkpoint.

After SEC.15 automated regression is green, perform real-device / real-backend smoke for:

```text
Complete — Camera photo
Complete — Gallery photo
Complete — invalid/oversized validation
Skip — required reason without photo
Skip — reason + optional photo
existing Completed/Skipped evidence rendering
expired signed URL → Patrol Detail refresh
network timeout ambiguity → refresh before retry
ID / EN
```

Only then lock APH.42 Flutter integration as DONE.

## New Chat Bootstrap

```text
Project: Aparthub Security Mobile Flutter
Current checkpoint: SEC.15 — APH.42 Security Patrol Checkpoint Photo Evidence
Status: IMPLEMENTED / VALIDATION PENDING

Backend APH.42 is already GREEN and is source of truth.
Do not invent endpoints.
Base remains /api/security.
Use visit_id, never checkpoint_id, for complete/skip mutation paths.
Complete requires multipart photo; notes optional.
Skip requires notes; photo optional; JSON without photo and multipart with photo.
Patrol Detail photo_evidence.url is a temporary signed URL; never construct/persist a permanent path.
Canonical Patrol/checkpoint statuses and stable error codes remain exact.
Camera + Gallery + preview/remove/retake/change are implemented with image_picker.
No GPS/QR/NFC/RFID/beacon/device-registry proof.

Patch executable gate still required:
flutter pub get
flutter gen-l10n
flutter test targeted files
flutter analyze
flutter test
flutter build apk --debug
release APK compile

If any gate is red, fix only the concrete blocker from the latest cumulative SEC.15 state and keep SEC.15 VALIDATION PENDING.
```

## Validation hotfix v1 — 2026-08-18

First targeted validation exposed two implementation-test blockers while APH.42 remained the backend source of truth:

- `ApiPatrolRepository` correctly feature-detected `SecurityMultipartApiClient`, but the local variable retained static type `SecurityApiClient`; Dart therefore could not resolve `postMultipart`. The hotfix performs an explicit cast only after the runtime capability guard. No API route or request shape changed.
- `patrol_photo_evidence_widget_test.dart` used `pumpAndSettle()` after a successful mutation. The resulting Completed checkpoint intentionally renders `photo_evidence.url` through a remote image stream, so the test could wait for settlement until its 10-minute timeout. The hotfix uses bounded frame pumping for this deterministic UI assertion instead; production signed-URL rendering is unchanged.

Revalidation gate remains:

```powershell
flutter pub get
flutter gen-l10n
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
flutter analyze
flutter test
flutter build apk --debug
```

SEC.15 stays **IMPLEMENTED / VALIDATION PENDING** until this gate is green.

## Validation hotfix v2 — 2026-08-18

Revalidation after hotfix v1 confirmed the multipart static-typing compile blocker is fixed: the targeted suite now compiles and progresses to the Patrol photo widget flow. One blocker remains:

```text
Complete checkpoint chooses photo, previews it, and renders proof after refresh
TimeoutException after 0:10:00
```

The v1 change bounded only the post-submit phase, but the same test still contained earlier `pumpAndSettle()` calls around dashboard load, route navigation, photo-source sheet, and preview dialog transitions. This test exercises multiple nested async UI surfaces (route state, bottom sheet, picker future, dialog, image preview), so waiting for global scheduler settlement is unnecessarily broad and can stall even when the exact UI state required by the assertion is already available.

Hotfix v2 is test-only. It removes every `pumpAndSettle()` from this APH.42 widget flow and replaces them with bounded, state-specific waits:

```text
wait until patrolNextSessionCard is mounted
bounded frames after route navigation
wait until Camera/Gallery source sheet is mounted
wait until checkpointEvidencePreview is mounted
wait until evidence submit dialog is gone
bounded frames, then scroll only until checkpointPhotoEvidence-102 is mounted
```

This does not change production camera/gallery behavior, repository mutations, signed URL handling, backend routes, payloads, or canonical state. It only makes the widget regression deterministic and guarantees failure is reported within bounded frames instead of consuming the global 10-minute test timeout.

Revalidation remains:

```powershell
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
```

If targeted is green, continue with:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

SEC.15 remains **IMPLEMENTED / VALIDATION PENDING** until the complete gate is green.

## Validation hotfix v3 — 2026-08-18

Revalidation after hotfix v2 still timed out at the global 10-minute test timeout with no bounded-wait assertion firing. This proves the remaining stall is not caused solely by `pumpAndSettle()` or the previous lazy-scroll helper.

Hotfix v3 remains **test-only** and further isolates the widget regression from Windows/file-cache and broad seeded-state effects:

```text
temporary image create/delete     removed
broad MockPatrolRepository seed   replaced with one-session deterministic fake
multi-checkpoint scrolling        removed
remote evidence image             not used by the fake (`mock://` evidence URL)
static checked-in PNG fixture     test/fixtures/patrol_checkpoint.png
surface size                      fixed large enough for the one checkpoint
widget test timeout               45 seconds for fast, actionable failure
```

The focused fake repository records the exact `checkpointVisitId`, photo input, and notes received from the real `PatrolManagementScreen`, then returns a canonical Completed checkpoint with `photoEvidence`. This still validates the UI integration boundary while leaving production repository/API behavior to the existing `api_patrol_repository_test.dart` and `mock_patrol_repository_test.dart` coverage.

No production Dart, endpoint, payload, signed-URL behavior, image-picker implementation, localization, dependency, or backend contract changes are included in v3.

Targeted revalidation:

```powershell
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
```

If green, continue immediately with:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

SEC.15 remains **IMPLEMENTED / VALIDATION PENDING** until all gates are green.


## Validation hotfix v4 — 2026-08-18

Revalidation after hotfix v3 still timed out at the intentionally shortened 45-second widget-test timeout. The compile blocker remains fixed and the failure is isolated to the single Complete-checkpoint UI regression. Because v3 already reduced the repository to one deterministic session/checkpoint and removed remote evidence rendering, the remaining asynchronous surface is the **local `Image.file` preview decode** inside the evidence dialog.

Hotfix v4 introduces a narrow presentation test seam only:

```text
PatrolManagementScreen.photoPreviewBuilder
```

Production behavior is unchanged when the builder is omitted: the dialog still renders the selected local file through the existing `Image.file(...)` path. Widget tests inject a synchronous placeholder preview instead, while still verifying that the exact selected `PatrolPhotoInput` reaches both the preview boundary and `completeCheckpoint(... visit_id ...)`.

This avoids coupling a navigation/repository widget regression to Flutter's asynchronous file-image codec/cache on Windows. It does **not** alter camera/gallery selection, image validation, multipart upload, visit-id usage, backend status ownership, signed URL retrieval, or any APH.42 endpoint.

Files changed by v4:

```text
lib/features/patrol/presentation/patrol_management_screen.dart
test/patrol_photo_evidence_widget_test.dart
docs/checkpoints/SEC.15_CONTEXT.md
```

Targeted revalidation remains:

```powershell
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
```

If targeted is green, continue with:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

SEC.15 remains **IMPLEMENTED / VALIDATION PENDING** until all gates are green.


## Validation hotfix v5 — 2026-08-19

Revalidation after hotfix v4 no longer timed out blindly; Flutter emitted a precise hit-test warning for the Camera source tile:

```text
patrolPhotoSourceCamera center = Offset(600.0, 1876.0)
root render view = Size(1200.0, 1800.0)
```

The source tile was already **mounted** but the modal bottom-sheet entrance animation had not yet moved it inside the render-view bounds. The immediate `tester.tap(cameraSource)` therefore missed the tile, the picker was never invoked, and `checkpointEvidencePreview` could never appear.

Hotfix v5 is test-only. It adds a bounded `_pumpUntilHitTestable(...)` helper and waits until the exact Camera tile is hit-testable before tapping it. This validates the same production bottom sheet without changing Patrol UI, picker behavior, API/repository code, multipart payloads, or APH.42 contract.

Targeted revalidation:

```powershell
flutter test `
  test/security_api_localization_test.dart `
  test/api_patrol_repository_test.dart `
  test/mock_patrol_repository_test.dart `
  test/patrol_photo_evidence_widget_test.dart
```

If targeted is green:

```powershell
flutter analyze
flutter test
flutter build apk --debug
```

SEC.15 remains **IMPLEMENTED / VALIDATION PENDING** until the complete gate is green.


## Closure — 2026-08-19

The user confirmed the latest cumulative SEC.15 validation gate fully green after hotfix v5 and the local Flutter/Dart SDK environment was corrected. SEC.15 is therefore locked `DONE`.

Confirmed closure evidence for the SEC.15 implementation gate:

```text
targeted APH.42 tests    PASS
flutter analyze          PASS
flutter test             PASS
flutter build apk --debug PASS
```

Release compilation and real Android/backend smoke are intentionally carried into SEC.16 because APH.42 arrived after the earlier SEC.14 final-readiness implementation. No backend route or product scope is changed by that revalidation checkpoint.
