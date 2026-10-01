import 'package:aparthub_security/core/theme/security_theme.dart';
import 'package:aparthub_security/features/patrol/domain/models/patrol_models.dart';
import 'package:aparthub_security/features/patrol/domain/repositories/patrol_repository.dart';
import 'package:aparthub_security/features/patrol/presentation/patrol_management_screen.dart';
import 'package:aparthub_security/features/patrol/presentation/services/patrol_photo_picker.dart';
import 'package:aparthub_security/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpFrames(
  WidgetTester tester, {
  int frames = 6,
  Duration frame = const Duration(milliseconds: 50),
}) async {
  for (var index = 0; index < frames; index++) {
    await tester.pump(frame);
  }
}

Future<void> _pumpUntilMounted(
  WidgetTester tester,
  Finder target, {
  int maxFrames = 40,
  Duration frame = const Duration(milliseconds: 50),
}) async {
  for (var index = 0; index < maxFrames; index++) {
    if (target.evaluate().isNotEmpty) return;
    await tester.pump(frame);
  }
  expect(target, findsWidgets);
}


Future<void> _pumpUntilHitTestable(
  WidgetTester tester,
  Finder target, {
  int maxFrames = 40,
  Duration frame = const Duration(milliseconds: 50),
}) async {
  for (var index = 0; index < maxFrames; index++) {
    if (target.hitTestable().evaluate().isNotEmpty) return;
    await tester.pump(frame);
  }
  expect(target.hitTestable(), findsWidgets);
}

Future<void> _pumpUntilGone(
  WidgetTester tester,
  Finder target, {
  int maxFrames = 40,
  Duration frame = const Duration(milliseconds: 50),
}) async {
  for (var index = 0; index < maxFrames; index++) {
    if (target.evaluate().isEmpty) return;
    await tester.pump(frame);
  }
  expect(target, findsNothing);
}

void main() {
  testWidgets(
    'Complete checkpoint chooses photo, previews it, and renders proof after refresh',
    (tester) async {
      // Keep this regression deterministic: picker selection and preview
      // rendering are injected. The production default still renders the real
      // local file with Image.file.
      const selectedPhoto = PatrolPhotoInput(
        path: 'test://patrol-checkpoint.png',
        originalName: 'patrol_checkpoint.png',
        mimeType: 'image/png',
        fileSize: 128,
      );
      final repository = _PhotoFlowPatrolRepository();
      final picker = _FakePatrolPhotoPicker(selectedPhoto);
      PatrolPhotoInput? previewedPhoto;

      await tester.binding.setSurfaceSize(const Size(1200, 1800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

      await tester.pumpWidget(
        MaterialApp(
          theme: SecurityTheme.light(),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: PatrolManagementScreen(
            repository: repository,
            onBackHome: () {},
            photoPicker: picker,
            photoPreviewBuilder: (context, photo) {
              previewedPhoto = photo;
              return const ColoredBox(color: Colors.black12);
            },
          ),
        ),
      );

      final sessionCard = find.byKey(const Key('patrolNextSessionCard'));
      await _pumpUntilMounted(tester, sessionCard);
      await tester.tap(sessionCard);

      final completeButton = find.byKey(
        const Key('completeCheckpointButton-102'),
      );
      await _pumpUntilMounted(tester, completeButton);
      expect(completeButton, findsOneWidget);
      await tester.tap(completeButton);

      final cameraSource = find.byKey(const Key('patrolPhotoSourceCamera'));
      await _pumpUntilMounted(tester, cameraSource);
      expect(find.byKey(const Key('patrolPhotoSourceGallery')), findsOneWidget);
      // The modal bottom sheet is mounted before its entrance animation has
      // necessarily moved the tile inside the render-view bounds. Wait for
      // the exact tile to become hit-testable instead of tapping a mounted
      // but still off-screen element.
      await _pumpUntilHitTestable(tester, cameraSource);
      await tester.tap(cameraSource.hitTestable());

      final preview = find.byKey(const Key('checkpointEvidencePreview'));
      await _pumpUntilMounted(tester, preview);
      expect(preview, findsOneWidget);
      expect(
        find.byKey(const Key('checkpointEvidenceRemovePhoto')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('checkpointEvidenceRetakePhoto')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('checkpointEvidenceChangePhoto')),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('checkpointEvidenceNotesField')),
        'Area clear.',
      );
      final submitButton = find.byKey(const Key('checkpointEvidenceSubmit'));
      await tester.tap(submitButton);
      await _pumpUntilGone(tester, submitButton);
      await _pumpFrames(tester, frames: 8);

      final evidence = find.byKey(const Key('checkpointPhotoEvidence-102'));
      await _pumpUntilMounted(tester, evidence);
      expect(evidence, findsOneWidget);

      expect(picker.sources, <PatrolPhotoSource>[PatrolPhotoSource.camera]);
      expect(previewedPhoto?.path, selectedPhoto.path);
      expect(repository.completedVisitId, 102);
      expect(repository.completedPhoto?.path, selectedPhoto.path);
      expect(repository.completedNotes, 'Area clear.');
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}

class _FakePatrolPhotoPicker implements PatrolPhotoPicker {
  _FakePatrolPhotoPicker(this.photo);

  final PatrolPhotoInput photo;
  final List<PatrolPhotoSource> sources = <PatrolPhotoSource>[];

  @override
  Future<PatrolPhotoInput?> pick(PatrolPhotoSource source) async {
    sources.add(source);
    return photo;
  }
}

class _PhotoFlowPatrolRepository implements PatrolRepository {
  _PhotoFlowPatrolRepository()
      : _session = PatrolSession(
          patrolSessionId: 41,
          sessionNumber: 'PAT-APH42-TEST',
          status: PatrolSessionStatus.inProgress,
          property: const PatrolPropertyRef(
            id: 1,
            code: 'SITE-A',
            name: 'Aparthub Residence',
          ),
          route: const PatrolRouteRef(
            id: 4,
            code: 'NIGHT-A',
            name: 'Photo Evidence Patrol',
            expectedDurationMinutes: 30,
          ),
          officer: const PatrolPartyRef(id: 12, name: 'Security Officer'),
          scheduledStartAt: DateTime(2026, 8, 18, 19),
          startedAt: DateTime(2026, 8, 18, 19, 5),
          checkpointSummary: const PatrolCheckpointSummary(
            total: 1,
            pending: 1,
            completed: 0,
            skipped: 0,
            issue: 0,
          ),
          canStart: false,
          canComplete: false,
          checkpoints: const <PatrolCheckpointVisit>[
            PatrolCheckpointVisit(
              visitId: 102,
              checkpointId: 8,
              code: 'CP-01',
              name: 'Main Lobby',
              locationLabel: 'Ground Floor',
              sequence: 1,
              status: PatrolCheckpointStatus.pending,
              canComplete: true,
              canSkip: true,
            ),
          ],
        );

  PatrolSession _session;
  int? completedVisitId;
  PatrolPhotoInput? completedPhoto;
  String? completedNotes;

  @override
  Future<PatrolDashboard> dashboard() async {
    return PatrolDashboard(
      scheduled: 0,
      inProgress: 1,
      completedToday: 0,
      cancelledToday: 0,
      nextPatrol: _session,
    );
  }

  @override
  Future<List<PatrolSession>> assignedSessions({
    PatrolSessionStatus? status,
    DateTime? date,
  }) async {
    if (status != null && status != _session.status) {
      return const <PatrolSession>[];
    }
    return <PatrolSession>[_session];
  }

  @override
  Future<PatrolSession?> findById(int patrolSessionId) async {
    return patrolSessionId == _session.patrolSessionId ? _session : null;
  }

  @override
  Future<PatrolSession> completeCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required PatrolPhotoInput photo,
    String? notes,
  }) async {
    expect(patrolSessionId, _session.patrolSessionId);
    expect(checkpointVisitId, 102);

    completedVisitId = checkpointVisitId;
    completedPhoto = photo;
    completedNotes = notes;

    final checkpoint = _session.checkpoints.single.copyWith(
      status: PatrolCheckpointStatus.completed,
      checkedAt: DateTime(2026, 8, 18, 19, 10),
      checkedBy: const PatrolPartyRef(id: 12, name: 'Security Officer'),
      notes: notes,
      photoEvidence: PatrolCheckpointPhotoEvidence(
        url: 'mock://patrol-checkpoint/102/photo',
        originalName: photo.originalName,
        mimeType: photo.mimeType,
        fileSize: photo.fileSize,
        uploadedAt: DateTime(2026, 8, 18, 19, 10),
      ),
      canComplete: false,
      canSkip: false,
    );

    _session = _session.copyWith(
      checkpointSummary: const PatrolCheckpointSummary(
        total: 1,
        pending: 0,
        completed: 1,
        skipped: 0,
        issue: 0,
      ),
      canComplete: true,
      checkpoints: <PatrolCheckpointVisit>[checkpoint],
    );
    return _session;
  }

  @override
  Future<PatrolSession> skipCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required String reason,
    PatrolPhotoInput? photo,
  }) async {
    throw UnsupportedError('Not used by the Complete photo widget regression.');
  }

  @override
  Future<PatrolSession> startPatrol(int patrolSessionId) async => _session;

  @override
  Future<PatrolSession> completePatrol(
    int patrolSessionId, {
    String? notes,
  }) async {
    throw UnsupportedError('Not used by the Complete photo widget regression.');
  }

  @override
  Future<List<PatrolSession>> history({PatrolSessionStatus? status}) async {
    return const <PatrolSession>[];
  }
}
