import 'package:nsecure/features/patrol/data/mock/mock_patrol_repository.dart';
import 'package:nsecure/features/patrol/domain/models/patrol_models.dart';
import 'package:nsecure/features/patrol/domain/repositories/patrol_repository.dart';
import 'package:flutter_test/flutter_test.dart';

const PatrolPhotoInput _validPhoto = PatrolPhotoInput(
  path: '/tmp/checkpoint.jpg',
  originalName: 'checkpoint.jpg',
  mimeType: 'image/jpeg',
  fileSize: 123456,
);

void main() {
  group('MockPatrolRepository', () {
    test('exposes deterministic assigned patrol dashboard', () async {
      final repository = MockPatrolRepository();

      final dashboard = await repository.dashboard();
      final sessions = await repository.assignedSessions();

      expect(dashboard.inProgress, 1);
      expect(dashboard.scheduled, 1);
      expect(dashboard.nextPatrol?.patrolSessionId, 41);
      expect(sessions, isNotEmpty);
    });

    test('starts Scheduled patrol using backend-style authoritative state', () async {
      final repository = MockPatrolRepository(actorName: 'Officer Demo');

      final session = await repository.startPatrol(42);

      expect(session.status, PatrolSessionStatus.inProgress);
      expect(session.startedAt, isNotNull);
      expect(session.canStart, isFalse);
      expect(session.checkpoints.every((checkpoint) => checkpoint.canComplete), isTrue);
    });

    test('processes checkpoint then enables patrol completion when none pending', () async {
      final repository = MockPatrolRepository();

      await repository.completeCheckpoint(41, 102, photo: _validPhoto);
      await repository.skipCheckpoint(41, 103, reason: 'Area inaccessible');
      final session = await repository.completeCheckpoint(
        41,
        104,
        photo: _validPhoto,
      );

      expect(session.checkpointSummary.pending, 0);
      expect(session.checkpointSummary.completed, 3);
      expect(session.checkpointSummary.skipped, 1);
      expect(session.canComplete, isTrue);
      expect(
        session.checkpoints.singleWhere((item) => item.visitId == 104).photoEvidence,
        isNotNull,
      );
    });

    test('skip accepts optional photo evidence while keeping reason mandatory', () async {
      final repository = MockPatrolRepository();

      final session = await repository.skipCheckpoint(
        41,
        102,
        reason: 'Area inaccessible',
        photo: _validPhoto,
      );
      final checkpoint = session.checkpoints.singleWhere(
        (item) => item.visitId == 102,
      );

      expect(checkpoint.status, PatrolCheckpointStatus.skipped);
      expect(checkpoint.photoEvidence?.originalName, 'checkpoint.jpg');
    });

    test('incident linkage marks a Pending checkpoint as Issue', () async {
      final repository = MockPatrolRepository(actorName: 'Officer Demo');

      await repository.markCheckpointIssueFromIncident(102);
      final session = await repository.findById(41);
      final checkpoint = session!.checkpoints.singleWhere(
        (item) => item.visitId == 102,
      );

      expect(checkpoint.status, PatrolCheckpointStatus.issue);
      expect(checkpoint.checkedAt, isNotNull);
      expect(checkpoint.checkedBy?.name, 'Officer Demo');
      expect(checkpoint.canComplete, isFalse);
      expect(checkpoint.canSkip, isFalse);
      expect(session.checkpointSummary.issue, 1);
      expect(session.checkpointSummary.pending, 2);
    });

    test('skip rejects an empty reason', () async {
      final repository = MockPatrolRepository();

      await expectLater(
        repository.skipCheckpoint(41, 102, reason: '  '),
        throwsA(
          isA<PatrolRepositoryException>().having(
            (error) => error.code,
            'code',
            PatrolRepositoryFailureCode.validation,
          ),
        ),
      );
    });

    test('patrol cannot complete while Pending checkpoints remain', () async {
      final repository = MockPatrolRepository();

      await expectLater(
        repository.completePatrol(41),
        throwsA(
          isA<PatrolRepositoryException>()
              .having(
                (error) => error.code,
                'code',
                PatrolRepositoryFailureCode.checkpointsPending,
              )
              .having((error) => error.pendingCount, 'pendingCount', 3),
        ),
      );
    });
  });
}
