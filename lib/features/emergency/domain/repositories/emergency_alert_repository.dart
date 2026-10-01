import '../models/emergency_alert_models.dart';

enum EmergencyRepositoryFailureCode {
  notFound,
  alreadyTaken,
  alreadyResolved,
  notAcknowledged,
  assignedToOther,
  validation,
  unauthorized,
  forbidden,
  network,
  unknown,
}

class EmergencyRepositoryException implements Exception {
  const EmergencyRepositoryException(
    this.code, {
    this.message,
    this.fieldErrors = const <String, dynamic>{},
  });

  final EmergencyRepositoryFailureCode code;
  final String? message;
  final Map<String, dynamic> fieldErrors;

  @override
  String toString() {
    return 'EmergencyRepositoryException(${code.name}): ${message ?? 'no detail'}';
  }
}

abstract interface class EmergencyAlertRepository {
  Future<List<EmergencyAlert>> activeAlerts();

  Future<List<EmergencyAlert>> unresolvedAlerts();

  Future<List<EmergencyAlert>> history();

  Future<EmergencyAlert?> findById(int emergencyAlertId);

  Future<EmergencyAlert> acknowledge(int emergencyAlertId);

  Future<EmergencyAlert> resolve(
    int emergencyAlertId, {
    String? notes,
  });
}
