enum PatrolSessionStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
}

enum PatrolCheckpointStatus {
  pending,
  completed,
  skipped,
  issue,
}

class PatrolPartyRef {
  const PatrolPartyRef({required this.id, required this.name});

  final int id;
  final String name;
}

class PatrolPropertyRef {
  const PatrolPropertyRef({
    required this.id,
    required this.code,
    required this.name,
  });

  final int id;
  final String code;
  final String name;
}

class PatrolRouteRef {
  const PatrolRouteRef({
    required this.id,
    required this.code,
    required this.name,
    required this.expectedDurationMinutes,
    this.description,
  });

  final int id;
  final String code;
  final String name;
  final String? description;
  final int expectedDurationMinutes;
}

class PatrolCheckpointSummary {
  const PatrolCheckpointSummary({
    required this.total,
    required this.pending,
    required this.completed,
    required this.skipped,
    required this.issue,
  });

  final int total;
  final int pending;
  final int completed;
  final int skipped;
  final int issue;

  int get terminal => completed + skipped + issue;

  double get progress {
    if (total <= 0) return 0;
    return (terminal / total).clamp(0, 1).toDouble();
  }
}


class PatrolCheckpointPhotoEvidence {
  const PatrolCheckpointPhotoEvidence({
    required this.url,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedAt,
  });

  final String url;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final DateTime uploadedAt;
}

class PatrolPhotoInput {
  const PatrolPhotoInput({
    required this.path,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
  });

  static const int maxFileSizeBytes = 5 * 1024 * 1024;
  static const Set<String> allowedMimeTypes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  final String path;
  final String originalName;
  final String mimeType;
  final int fileSize;
}

class PatrolCheckpointVisit {
  const PatrolCheckpointVisit({
    required this.visitId,
    required this.checkpointId,
    required this.code,
    required this.name,
    required this.sequence,
    required this.status,
    required this.canComplete,
    required this.canSkip,
    this.locationLabel,
    this.checkedAt,
    this.checkedBy,
    this.notes,
    this.photoEvidence,
  });

  final int visitId;
  final int checkpointId;
  final String code;
  final String name;
  final String? locationLabel;
  final int sequence;
  final PatrolCheckpointStatus status;
  final DateTime? checkedAt;
  final PatrolPartyRef? checkedBy;
  final String? notes;
  final PatrolCheckpointPhotoEvidence? photoEvidence;
  final bool canComplete;
  final bool canSkip;

  PatrolCheckpointVisit copyWith({
    PatrolCheckpointStatus? status,
    DateTime? checkedAt,
    PatrolPartyRef? checkedBy,
    String? notes,
    PatrolCheckpointPhotoEvidence? photoEvidence,
    bool? canComplete,
    bool? canSkip,
  }) {
    return PatrolCheckpointVisit(
      visitId: visitId,
      checkpointId: checkpointId,
      code: code,
      name: name,
      locationLabel: locationLabel,
      sequence: sequence,
      status: status ?? this.status,
      checkedAt: checkedAt ?? this.checkedAt,
      checkedBy: checkedBy ?? this.checkedBy,
      notes: notes ?? this.notes,
      photoEvidence: photoEvidence ?? this.photoEvidence,
      canComplete: canComplete ?? this.canComplete,
      canSkip: canSkip ?? this.canSkip,
    );
  }
}

class PatrolSession {
  const PatrolSession({
    required this.patrolSessionId,
    required this.sessionNumber,
    required this.status,
    required this.property,
    required this.route,
    required this.officer,
    required this.scheduledStartAt,
    required this.checkpointSummary,
    required this.canStart,
    required this.canComplete,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.notes,
    this.checkpoints = const <PatrolCheckpointVisit>[],
  });

  final int patrolSessionId;
  final String sessionNumber;
  final PatrolSessionStatus status;
  final PatrolPropertyRef property;
  final PatrolRouteRef route;
  final PatrolPartyRef officer;
  final DateTime scheduledStartAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final String? notes;
  final PatrolCheckpointSummary checkpointSummary;
  final bool canStart;
  final bool canComplete;
  final List<PatrolCheckpointVisit> checkpoints;

  PatrolSession copyWith({
    PatrolSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    String? notes,
    PatrolCheckpointSummary? checkpointSummary,
    bool? canStart,
    bool? canComplete,
    List<PatrolCheckpointVisit>? checkpoints,
  }) {
    return PatrolSession(
      patrolSessionId: patrolSessionId,
      sessionNumber: sessionNumber,
      status: status ?? this.status,
      property: property,
      route: route,
      officer: officer,
      scheduledStartAt: scheduledStartAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt,
      notes: notes ?? this.notes,
      checkpointSummary: checkpointSummary ?? this.checkpointSummary,
      canStart: canStart ?? this.canStart,
      canComplete: canComplete ?? this.canComplete,
      checkpoints: checkpoints ?? this.checkpoints,
    );
  }

  PatrolCheckpointVisit? get nextPendingCheckpoint {
    for (final checkpoint in checkpoints) {
      if (checkpoint.status == PatrolCheckpointStatus.pending) {
        return checkpoint;
      }
    }
    return null;
  }
}

class PatrolDashboard {
  const PatrolDashboard({
    required this.scheduled,
    required this.inProgress,
    required this.completedToday,
    required this.cancelledToday,
    this.nextPatrol,
  });

  final int scheduled;
  final int inProgress;
  final int completedToday;
  final int cancelledToday;
  final PatrolSession? nextPatrol;
}
