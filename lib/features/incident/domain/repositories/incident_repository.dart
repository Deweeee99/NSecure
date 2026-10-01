import '../models/incident_models.dart';

enum IncidentRepositoryFailureCode {
  incidentNotFound,
  patrolCheckpointNotFound,
  patrolNotInProgress,
  patrolCheckpointAlreadyProcessed,
  alreadyAcknowledged,
  alreadyInProgress,
  alreadyResolved,
  closed,
  cancelled,
  invalidState,
  validation,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class IncidentRepositoryException implements Exception {
  const IncidentRepositoryException(
    this.code, {
    this.message,
    this.fieldErrors = const <String, dynamic>{},
  });

  final IncidentRepositoryFailureCode code;
  final String? message;
  final Map<String, dynamic> fieldErrors;

  @override
  String toString() {
    return 'IncidentRepositoryException(${code.name}): ${message ?? 'no detail'}';
  }
}

abstract interface class IncidentRepository {
  Future<IncidentDashboard> dashboard();

  Future<List<IncidentRecord>> incidents({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  });

  Future<List<IncidentRecord>> history({
    IncidentScope scope = IncidentScope.mine,
    IncidentStatus? status,
    IncidentSeverity? severity,
    String? query,
  });

  Future<IncidentRecord?> findById(int incidentId);

  Future<void> createIncident(IncidentCreateInput input);

  Future<IncidentRecord> acknowledge(
    int incidentId, {
    String? notes,
  });

  Future<IncidentRecord> start(
    int incidentId, {
    String? notes,
  });

  Future<IncidentRecord> resolve(
    int incidentId, {
    required String notes,
  });

  Future<IncidentRecord> addNote(
    int incidentId, {
    required String notes,
  });
}
