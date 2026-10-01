import 'package:aparthub_security/core/bootstrap/app_dependencies.dart';
import 'package:aparthub_security/features/security/data/api/api_security_auth_repository.dart';
import 'package:aparthub_security/features/security/data/api/api_security_dashboard_repository.dart';
import 'package:aparthub_security/features/emergency/data/api/api_emergency_alert_repository.dart';
import 'package:aparthub_security/features/emergency/data/mock/mock_emergency_alert_repository.dart';
import 'package:aparthub_security/features/incident/data/api/api_incident_repository.dart';
import 'package:aparthub_security/features/incident/data/mock/mock_incident_repository.dart';
import 'package:aparthub_security/features/incident/domain/models/incident_models.dart';
import 'package:aparthub_security/features/patrol/data/api/api_patrol_repository.dart';
import 'package:aparthub_security/features/patrol/data/mock/mock_patrol_repository.dart';
import 'package:aparthub_security/features/patrol/domain/models/patrol_models.dart';
import 'package:aparthub_security/features/package/data/api/api_security_package_repository.dart';
import 'package:aparthub_security/features/package/data/mock/mock_security_package_repository.dart';
import 'package:aparthub_security/features/visitor/data/api/api_visitor_repository.dart';
import 'package:aparthub_security/features/visitor/data/mock/mock_visitor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mock composition remains available for deterministic tests and demo', () {
    final dependencies = AppDependencies.mock();

    expect(dependencies.visitorRepository, isA<MockVisitorRepository>());
    expect(dependencies.patrolRepository, isA<MockPatrolRepository>());
    expect(dependencies.incidentRepository, isA<MockIncidentRepository>());
    expect(
      dependencies.emergencyAlertRepository,
      isA<MockEmergencyAlertRepository>(),
    );
    expect(
      dependencies.securityPackageRepository,
      isA<MockSecurityPackageRepository>(),
    );
    expect(dependencies.securityAuthRepository, isNull);
    expect(dependencies.securityDashboardRepository, isNull);
    expect(dependencies.usesApi, isFalse);
    expect(dependencies.enableDeviceQrScanner, isFalse);
    expect(dependencies.enableEmergencyForegroundPolling, isFalse);
  });

  test('mock composition preserves Patrol to Incident side effects', () async {
    final dependencies = AppDependencies.mock();

    await dependencies.incidentRepository.createIncident(
      const IncidentCreateInput(
        propertyId: 1,
        patrolCheckpointVisitId: 102,
        title: 'Checkpoint issue',
        description: 'Issue found while patrolling.',
        category: 'Safety',
        severity: IncidentSeverity.high,
      ),
    );

    final patrol = await dependencies.patrolRepository.findById(41);
    final checkpoint = patrol!.checkpoints.singleWhere(
      (item) => item.visitId == 102,
    );
    expect(checkpoint.status, PatrolCheckpointStatus.issue);
  });

  test('api composition wires auth visitor patrol and incident repositories to one API seam', () {
    final dependencies = AppDependencies.api(
      baseUrl: 'https://example.test/api/security',
    );

    expect(dependencies.visitorRepository, isA<ApiVisitorRepository>());
    expect(dependencies.patrolRepository, isA<ApiPatrolRepository>());
    expect(dependencies.incidentRepository, isA<ApiIncidentRepository>());
    expect(
      dependencies.emergencyAlertRepository,
      isA<ApiEmergencyAlertRepository>(),
    );
    expect(
      dependencies.securityPackageRepository,
      isA<ApiSecurityPackageRepository>(),
    );
    expect(
      dependencies.securityAuthRepository,
      isA<ApiSecurityAuthRepository>(),
    );
    expect(
      dependencies.securityDashboardRepository,
      isA<ApiSecurityDashboardRepository>(),
    );
    expect(dependencies.usesApi, isTrue);
    expect(dependencies.apiLocalization, isNotNull);
    dependencies.setApiLanguageCode('id');
    expect(dependencies.apiLocalization?.requestLanguageCode, 'id');
    expect(dependencies.enableDeviceQrScanner, isTrue);
    expect(dependencies.enableEmergencyForegroundPolling, isTrue);
  });
}
