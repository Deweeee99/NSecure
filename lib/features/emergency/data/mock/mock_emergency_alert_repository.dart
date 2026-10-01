import '../../domain/models/emergency_alert_models.dart';
import '../../domain/repositories/emergency_alert_repository.dart';

class MockEmergencyAlertRepository implements EmergencyAlertRepository {
  MockEmergencyAlertRepository({
    List<EmergencyAlert> initialAlerts = const <EmergencyAlert>[],
    this.actorName = 'Security Team',
  }) : _alerts = <EmergencyAlert>[
          ...initialAlerts,
        ];

  factory MockEmergencyAlertRepository.withOpenAlert({
    String actorName = 'Security Team',
  }) {
    return MockEmergencyAlertRepository(
      actorName: actorName,
      initialAlerts: <EmergencyAlert>[
        EmergencyAlert(
          emergencyAlertId: 12,
          alertCode: 'SOS-20260814-000012',
          status: EmergencyAlertStatus.open,
          message: 'Butuh bantuan segera.',
          modalRequired: true,
          takenByMe: false,
          property: const EmergencyPropertyRef(
            id: 1,
            code: 'SITE-A',
            name: 'Aparthub Residence',
          ),
          resident: const EmergencyResidentRef(
            id: 101,
            name: 'Budi Santoso',
            mobileNo: '081234567890',
          ),
          unit: const EmergencyUnitRef(
            id: 44,
            code: 'A-101',
            tower: 'Tower A',
            floor: 1,
          ),
          triggeredAt: DateTime(2026, 8, 14, 13, 15),
        ),
      ],
    );
  }

  final String actorName;
  final List<EmergencyAlert> _alerts;

  @override
  Future<List<EmergencyAlert>> activeAlerts() async {
    final alerts = _alerts
        .where((alert) => alert.status == EmergencyAlertStatus.open)
        .toList(growable: false)
      ..sort((a, b) {
        final byTime = a.triggeredAt.compareTo(b.triggeredAt);
        return byTime != 0
            ? byTime
            : a.emergencyAlertId.compareTo(b.emergencyAlertId);
      });
    return List<EmergencyAlert>.unmodifiable(alerts);
  }

  @override
  Future<List<EmergencyAlert>> unresolvedAlerts() async {
    return List<EmergencyAlert>.unmodifiable(
      _alerts.where((alert) => alert.status != EmergencyAlertStatus.resolved),
    );
  }

  @override
  Future<List<EmergencyAlert>> history() async {
    return List<EmergencyAlert>.unmodifiable(
      _alerts.where((alert) => alert.status == EmergencyAlertStatus.resolved),
    );
  }

  @override
  Future<EmergencyAlert?> findById(int emergencyAlertId) async {
    for (final alert in _alerts) {
      if (alert.emergencyAlertId == emergencyAlertId) return alert;
    }
    return null;
  }

  @override
  Future<EmergencyAlert> acknowledge(int emergencyAlertId) async {
    final index = _indexOf(emergencyAlertId);
    final alert = _alerts[index];
    if (alert.status == EmergencyAlertStatus.resolved) {
      throw const EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.alreadyResolved,
      );
    }
    if (alert.status == EmergencyAlertStatus.acknowledged) {
      return alert;
    }

    final updated = EmergencyAlert(
      emergencyAlertId: alert.emergencyAlertId,
      alertCode: alert.alertCode,
      status: EmergencyAlertStatus.acknowledged,
      message: alert.message,
      modalRequired: false,
      takenByMe: true,
      property: alert.property,
      resident: alert.resident,
      unit: alert.unit,
      triggeredAt: alert.triggeredAt,
      acknowledgedAt: DateTime(2026, 8, 14, 13, 16),
      acknowledgedBy: EmergencyActorRef(id: 22, name: actorName),
      resolvedAt: alert.resolvedAt,
      resolvedBy: alert.resolvedBy,
      resolutionNotes: alert.resolutionNotes,
    );
    _alerts[index] = updated;
    return updated;
  }

  @override
  Future<EmergencyAlert> resolve(
    int emergencyAlertId, {
    String? notes,
  }) async {
    final index = _indexOf(emergencyAlertId);
    final alert = _alerts[index];
    if (alert.status == EmergencyAlertStatus.open) {
      throw const EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.notAcknowledged,
      );
    }
    if (alert.status == EmergencyAlertStatus.resolved) return alert;
    if (!alert.takenByMe) {
      throw const EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.assignedToOther,
      );
    }

    final updated = EmergencyAlert(
      emergencyAlertId: alert.emergencyAlertId,
      alertCode: alert.alertCode,
      status: EmergencyAlertStatus.resolved,
      message: alert.message,
      modalRequired: false,
      takenByMe: true,
      property: alert.property,
      resident: alert.resident,
      unit: alert.unit,
      triggeredAt: alert.triggeredAt,
      acknowledgedAt: alert.acknowledgedAt,
      acknowledgedBy: alert.acknowledgedBy,
      resolvedAt: DateTime(2026, 8, 14, 13, 25),
      resolvedBy: EmergencyActorRef(id: 22, name: actorName),
      resolutionNotes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
    _alerts[index] = updated;
    return updated;
  }

  int _indexOf(int emergencyAlertId) {
    final index = _alerts.indexWhere(
      (alert) => alert.emergencyAlertId == emergencyAlertId,
    );
    if (index < 0) {
      throw const EmergencyRepositoryException(
        EmergencyRepositoryFailureCode.notFound,
      );
    }
    return index;
  }
}
