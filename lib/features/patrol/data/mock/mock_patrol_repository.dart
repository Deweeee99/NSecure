import '../../domain/models/patrol_models.dart';
import '../../domain/repositories/patrol_repository.dart';

class MockPatrolRepository implements PatrolRepository {
  MockPatrolRepository({this.actorName = 'Security Team'})
      : _sessions = <int, PatrolSession>{
          for (final session in _seed(actorName)) session.patrolSessionId: session,
        };

  final String actorName;
  final Map<int, PatrolSession> _sessions;

  static final DateTime _startedAt = DateTime.parse('2026-08-12T20:02:14+07:00');
  static final DateTime _checkpointAt = DateTime.parse('2026-08-12T20:07:00+07:00');
  static final DateTime _completedAt = DateTime.parse('2026-08-12T20:45:00+07:00');

  @override
  Future<PatrolDashboard> dashboard() async {
    final sessions = _sessions.values.toList(growable: false);
    final scheduled = sessions
        .where((session) => session.status == PatrolSessionStatus.scheduled)
        .length;
    final inProgress = sessions
        .where((session) => session.status == PatrolSessionStatus.inProgress)
        .length;
    final completedToday = sessions
        .where((session) => session.status == PatrolSessionStatus.completed)
        .length;
    final cancelledToday = sessions
        .where((session) => session.status == PatrolSessionStatus.cancelled)
        .length;
    final next = sessions
            .where(
              (session) => session.status == PatrolSessionStatus.inProgress,
            )
            .firstOrNull ??
        sessions
            .where(
              (session) => session.status == PatrolSessionStatus.scheduled,
            )
            .firstOrNull;

    return PatrolDashboard(
      scheduled: scheduled,
      inProgress: inProgress,
      completedToday: completedToday,
      cancelledToday: cancelledToday,
      nextPatrol: next,
    );
  }

  @override
  Future<List<PatrolSession>> assignedSessions({
    PatrolSessionStatus? status,
    DateTime? date,
  }) async {
    final values = _sessions.values.where((session) {
      if (status != null && session.status != status) return false;
      if (date != null) {
        final local = session.scheduledStartAt.toLocal();
        if (local.year != date.year ||
            local.month != date.month ||
            local.day != date.day) {
          return false;
        }
      }
      return session.status != PatrolSessionStatus.cancelled || status != null;
    }).toList()
      ..sort(
        (a, b) => b.scheduledStartAt.compareTo(a.scheduledStartAt),
      );
    return values.map(_withoutCheckpoints).toList(growable: false);
  }

  @override
  Future<PatrolSession?> findById(int patrolSessionId) async {
    return _sessions[patrolSessionId];
  }

  @override
  Future<PatrolSession> startPatrol(int patrolSessionId) async {
    final session = _requireSession(patrolSessionId);
    if (session.status == PatrolSessionStatus.inProgress) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.alreadyStarted,
      );
    }
    if (session.status == PatrolSessionStatus.completed) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.alreadyCompleted,
      );
    }
    if (session.status == PatrolSessionStatus.cancelled) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.cancelled,
      );
    }
    if (!session.canStart || session.status != PatrolSessionStatus.scheduled) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.invalidState,
      );
    }

    final checkpoints = session.checkpoints
        .map(
          (checkpoint) => checkpoint.status == PatrolCheckpointStatus.pending
              ? checkpoint.copyWith(canComplete: true, canSkip: true)
              : checkpoint,
        )
        .toList(growable: false);
    final updated = session.copyWith(
      status: PatrolSessionStatus.inProgress,
      startedAt: _startedAt,
      canStart: false,
      canComplete: session.checkpointSummary.pending == 0,
      checkpoints: checkpoints,
    );
    _sessions[patrolSessionId] = updated;
    return updated;
  }

  @override
  Future<PatrolSession> completeCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required PatrolPhotoInput photo,
    String? notes,
  }) async {
    _validatePhoto(photo);
    final trimmedNotes = notes?.trim();
    if (trimmedNotes != null && trimmedNotes.length > 2000) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
      );
    }
    return _processCheckpoint(
      patrolSessionId,
      checkpointVisitId,
      PatrolCheckpointStatus.completed,
      notes: trimmedNotes,
      photoEvidence: _mockPhotoEvidence(photo, checkpointVisitId),
    );
  }

  @override
  Future<PatrolSession> skipCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required String reason,
    PatrolPhotoInput? photo,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty || trimmed.length > 2000) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
      );
    }
    if (photo != null) _validatePhoto(photo);
    return _processCheckpoint(
      patrolSessionId,
      checkpointVisitId,
      PatrolCheckpointStatus.skipped,
      notes: trimmed,
      photoEvidence:
          photo == null ? null : _mockPhotoEvidence(photo, checkpointVisitId),
    );
  }

  Future<void> markCheckpointIssueFromIncident(int checkpointVisitId) async {
    for (final session in _sessions.values.toList(growable: false)) {
      final hasCheckpoint = session.checkpoints.any(
        (checkpoint) => checkpoint.visitId == checkpointVisitId,
      );
      if (!hasCheckpoint) continue;
      await _processCheckpoint(
        session.patrolSessionId,
        checkpointVisitId,
        PatrolCheckpointStatus.issue,
        notes: 'Incident reported from Patrol.',
      );
      return;
    }
    throw const PatrolRepositoryException(
      PatrolRepositoryFailureCode.checkpointNotFound,
    );
  }

  @override
  Future<PatrolSession> completePatrol(
    int patrolSessionId, {
    String? notes,
  }) async {
    final session = _requireSession(patrolSessionId);
    if (session.status == PatrolSessionStatus.completed) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.alreadyCompleted,
      );
    }
    if (session.status != PatrolSessionStatus.inProgress) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.invalidState,
      );
    }
    if (session.checkpointSummary.pending > 0) {
      throw PatrolRepositoryException(
        PatrolRepositoryFailureCode.checkpointsPending,
        pendingCount: session.checkpointSummary.pending,
      );
    }

    final trimmedNotes = notes?.trim();
    final updated = session.copyWith(
      status: PatrolSessionStatus.completed,
      completedAt: _completedAt,
      notes: trimmedNotes != null && trimmedNotes.isNotEmpty
          ? trimmedNotes
          : session.notes,
      canComplete: false,
    );
    _sessions[patrolSessionId] = updated;
    return updated;
  }

  @override
  Future<List<PatrolSession>> history({PatrolSessionStatus? status}) async {
    if (status != null &&
        status != PatrolSessionStatus.completed &&
        status != PatrolSessionStatus.cancelled) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
      );
    }
    final values = _sessions.values
        .where(
          (session) =>
              (session.status == PatrolSessionStatus.completed ||
                  session.status == PatrolSessionStatus.cancelled) &&
              (status == null || session.status == status),
        )
        .toList()
      ..sort((a, b) => b.scheduledStartAt.compareTo(a.scheduledStartAt));
    return values.map(_withoutCheckpoints).toList(growable: false);
  }

  Future<PatrolSession> _processCheckpoint(
    int patrolSessionId,
    int checkpointVisitId,
    PatrolCheckpointStatus newStatus, {
    String? notes,
    PatrolCheckpointPhotoEvidence? photoEvidence,
  }) async {
    final session = _requireSession(patrolSessionId);
    if (session.status != PatrolSessionStatus.inProgress) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.notInProgress,
      );
    }

    final index = session.checkpoints.indexWhere(
      (checkpoint) => checkpoint.visitId == checkpointVisitId,
    );
    if (index < 0) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.checkpointNotFound,
      );
    }
    final checkpoint = session.checkpoints[index];
    if (checkpoint.status != PatrolCheckpointStatus.pending) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.checkpointAlreadyProcessed,
      );
    }

    final checkpoints = [...session.checkpoints];
    checkpoints[index] = checkpoint.copyWith(
      status: newStatus,
      checkedAt: _checkpointAt,
      checkedBy: PatrolPartyRef(id: 12, name: actorName),
      notes: notes?.trim(),
      photoEvidence: photoEvidence,
      canComplete: false,
      canSkip: false,
    );
    final summary = _summarize(checkpoints);
    final updated = session.copyWith(
      checkpointSummary: summary,
      canComplete: summary.pending == 0,
      checkpoints: checkpoints,
    );
    _sessions[patrolSessionId] = updated;
    return updated;
  }

  static void _validatePhoto(PatrolPhotoInput photo) {
    if (!PatrolPhotoInput.allowedMimeTypes.contains(
          photo.mimeType.trim().toLowerCase(),
        ) ||
        photo.fileSize <= 0 ||
        photo.fileSize > PatrolPhotoInput.maxFileSizeBytes) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.validation,
      );
    }
  }

  static PatrolCheckpointPhotoEvidence _mockPhotoEvidence(
    PatrolPhotoInput photo,
    int checkpointVisitId,
  ) {
    return PatrolCheckpointPhotoEvidence(
      url: 'mock://patrol-checkpoint/$checkpointVisitId/photo',
      originalName: photo.originalName,
      mimeType: photo.mimeType,
      fileSize: photo.fileSize,
      uploadedAt: _checkpointAt,
    );
  }

  PatrolSession _requireSession(int id) {
    final session = _sessions[id];
    if (session == null) {
      throw const PatrolRepositoryException(
        PatrolRepositoryFailureCode.patrolNotFound,
      );
    }
    return session;
  }

  static PatrolSession _withoutCheckpoints(PatrolSession session) {
    return session.copyWith(checkpoints: const <PatrolCheckpointVisit>[]);
  }

  static PatrolCheckpointSummary _summarize(
    List<PatrolCheckpointVisit> checkpoints,
  ) {
    int count(PatrolCheckpointStatus status) =>
        checkpoints.where((checkpoint) => checkpoint.status == status).length;
    return PatrolCheckpointSummary(
      total: checkpoints.length,
      pending: count(PatrolCheckpointStatus.pending),
      completed: count(PatrolCheckpointStatus.completed),
      skipped: count(PatrolCheckpointStatus.skipped),
      issue: count(PatrolCheckpointStatus.issue),
    );
  }

  static List<PatrolSession> _seed(String actorName) {
    const property = PatrolPropertyRef(
      id: 1,
      code: 'SITE-A',
      name: 'Aparthub Residence',
    );
    const officer = PatrolPartyRef(id: 12, name: 'Security Team');
    const route = PatrolRouteRef(
      id: 4,
      code: 'NIGHT-A',
      name: 'Tower A — Night Patrol',
      description: 'Night perimeter patrol.',
      expectedDurationMinutes: 45,
    );
    final checkpoints = <PatrolCheckpointVisit>[
      PatrolCheckpointVisit(
        visitId: 101,
        checkpointId: 8,
        code: 'CP-01',
        name: 'Main Lobby',
        locationLabel: 'Ground Floor',
        sequence: 1,
        status: PatrolCheckpointStatus.completed,
        checkedAt: _checkpointAt,
        checkedBy: PatrolPartyRef(id: 12, name: actorName),
        notes: 'Area clear.',
        photoEvidence: PatrolCheckpointPhotoEvidence(
          url: 'mock://patrol-checkpoint/101/photo',
          originalName: 'main-lobby.jpg',
          mimeType: 'image/jpeg',
          fileSize: 245760,
          uploadedAt: _checkpointAt,
        ),
        canComplete: false,
        canSkip: false,
      ),
      const PatrolCheckpointVisit(
        visitId: 102,
        checkpointId: 9,
        code: 'CP-02',
        name: 'Lift Lobby — Floor 1',
        locationLabel: 'Tower A',
        sequence: 2,
        status: PatrolCheckpointStatus.pending,
        canComplete: true,
        canSkip: true,
      ),
      const PatrolCheckpointVisit(
        visitId: 103,
        checkpointId: 10,
        code: 'CP-03',
        name: 'Parking Area P1',
        locationLabel: 'Basement 1',
        sequence: 3,
        status: PatrolCheckpointStatus.pending,
        canComplete: true,
        canSkip: true,
      ),
      const PatrolCheckpointVisit(
        visitId: 104,
        checkpointId: 11,
        code: 'CP-04',
        name: 'Rooftop Access',
        locationLabel: 'Roof',
        sequence: 4,
        status: PatrolCheckpointStatus.pending,
        canComplete: true,
        canSkip: true,
      ),
    ];
    return <PatrolSession>[
      PatrolSession(
        patrolSessionId: 41,
        sessionNumber: 'PAT-20260812-000041',
        status: PatrolSessionStatus.inProgress,
        property: property,
        route: route,
        officer: officer,
        scheduledStartAt: DateTime.parse('2026-08-12T20:00:00+07:00'),
        startedAt: DateTime.parse('2026-08-12T20:02:14+07:00'),
        notes: 'Night shift.',
        checkpointSummary: const PatrolCheckpointSummary(
          total: 4,
          pending: 3,
          completed: 1,
          skipped: 0,
          issue: 0,
        ),
        canStart: false,
        canComplete: false,
        checkpoints: checkpoints,
      ),
      PatrolSession(
        patrolSessionId: 42,
        sessionNumber: 'PAT-20260812-000042',
        status: PatrolSessionStatus.scheduled,
        property: property,
        route: const PatrolRouteRef(
          id: 5,
          code: 'LATE-A',
          name: 'Tower A — Late Patrol',
          description: 'Late-shift common area patrol.',
          expectedDurationMinutes: 30,
        ),
        officer: PatrolPartyRef(id: 12, name: actorName),
        scheduledStartAt: DateTime.parse('2026-08-12T23:00:00+07:00'),
        checkpointSummary: const PatrolCheckpointSummary(
          total: 2,
          pending: 2,
          completed: 0,
          skipped: 0,
          issue: 0,
        ),
        canStart: true,
        canComplete: false,
        checkpoints: const <PatrolCheckpointVisit>[
          PatrolCheckpointVisit(
            visitId: 201,
            checkpointId: 12,
            code: 'CP-05',
            name: 'Fitness Center',
            locationLabel: 'Level 3',
            sequence: 1,
            status: PatrolCheckpointStatus.pending,
            canComplete: false,
            canSkip: false,
          ),
          PatrolCheckpointVisit(
            visitId: 202,
            checkpointId: 13,
            code: 'CP-06',
            name: 'Service Corridor',
            locationLabel: 'Level 2',
            sequence: 2,
            status: PatrolCheckpointStatus.pending,
            canComplete: false,
            canSkip: false,
          ),
        ],
      ),
      PatrolSession(
        patrolSessionId: 40,
        sessionNumber: 'PAT-20260812-000040',
        status: PatrolSessionStatus.completed,
        property: property,
        route: route,
        officer: PatrolPartyRef(id: 12, name: actorName),
        scheduledStartAt: DateTime.parse('2026-08-12T18:00:00+07:00'),
        startedAt: DateTime.parse('2026-08-12T18:01:00+07:00'),
        completedAt: DateTime.parse('2026-08-12T18:43:00+07:00'),
        checkpointSummary: const PatrolCheckpointSummary(
          total: 4,
          pending: 0,
          completed: 4,
          skipped: 0,
          issue: 0,
        ),
        canStart: false,
        canComplete: false,
      ),
    ];
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
