import '../models/patrol_models.dart';

enum PatrolRepositoryFailureCode {
  patrolNotFound,
  checkpointNotFound,
  alreadyStarted,
  alreadyCompleted,
  cancelled,
  invalidState,
  notInProgress,
  checkpointInvalidState,
  checkpointAlreadyProcessed,
  checkpointsPending,
  validation,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class PatrolRepositoryException implements Exception {
  const PatrolRepositoryException(
    this.code, {
    this.message,
    this.pendingCount,
  });

  final PatrolRepositoryFailureCode code;
  final String? message;
  final int? pendingCount;

  @override
  String toString() {
    return 'PatrolRepositoryException(${code.name}): ${message ?? 'no detail'}';
  }
}

abstract interface class PatrolRepository {
  Future<PatrolDashboard> dashboard();

  Future<List<PatrolSession>> assignedSessions({
    PatrolSessionStatus? status,
    DateTime? date,
  });

  Future<PatrolSession?> findById(int patrolSessionId);

  Future<PatrolSession> startPatrol(int patrolSessionId);

  Future<PatrolSession> completeCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required PatrolPhotoInput photo,
    String? notes,
  });

  Future<PatrolSession> skipCheckpoint(
    int patrolSessionId,
    int checkpointVisitId, {
    required String reason,
    PatrolPhotoInput? photo,
  });

  Future<PatrolSession> completePatrol(
    int patrolSessionId, {
    String? notes,
  });

  Future<List<PatrolSession>> history({PatrolSessionStatus? status});
}
