import 'package:aparthub_security/core/bootstrap/app_dependencies.dart';
import 'package:aparthub_security/features/emergency/data/api/api_emergency_alert_repository.dart';
import 'package:aparthub_security/features/incident/data/api/api_incident_repository.dart';
import 'package:aparthub_security/features/package/data/api/api_security_package_repository.dart';
import 'package:aparthub_security/features/patrol/data/api/api_patrol_repository.dart';
import 'package:aparthub_security/features/security/data/api/api_security_auth_repository.dart';
import 'package:aparthub_security/features/security/data/api/api_security_dashboard_repository.dart';
import 'package:aparthub_security/features/visitor/data/api/api_visitor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SEC.14 production runtime configuration', () {
    test('debug without API base keeps deterministic mock mode', () {
      final dependencies = AppDependencies.fromRuntimeConfig(
        baseUrl: '',
        isReleaseBuild: false,
      );

      expect(dependencies.usesApi, isFalse);
      expect(dependencies.enableDeviceQrScanner, isFalse);
      expect(dependencies.enableEmergencyForegroundPolling, isFalse);
    });

    test('release cannot fall back to mock mode', () {
      expect(
        () => AppDependencies.fromRuntimeConfig(
          baseUrl: '',
          isReleaseBuild: true,
        ),
        throwsStateError,
      );
    });

    test('configured API base must end with canonical /api/security prefix', () {
      expect(
        () => AppDependencies.fromRuntimeConfig(
          baseUrl: 'https://security.example.test/api',
          isReleaseBuild: true,
        ),
        throwsArgumentError,
      );
    });

    test('release rejects non-HTTPS Security API base', () {
      expect(
        () => AppDependencies.fromRuntimeConfig(
          baseUrl: 'http://security.example.test/api/security',
          isReleaseBuild: true,
        ),
        throwsArgumentError,
      );
    });

    test('release API composition wires every contracted software module', () {
      final dependencies = AppDependencies.fromRuntimeConfig(
        baseUrl: 'https://security.example.test/api/security',
        isReleaseBuild: true,
      );

      expect(dependencies.usesApi, isTrue);
      expect(
        dependencies.securityAuthRepository,
        isA<ApiSecurityAuthRepository>(),
      );
      expect(
        dependencies.securityDashboardRepository,
        isA<ApiSecurityDashboardRepository>(),
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
      expect(dependencies.apiLocalization, isNotNull);
      expect(dependencies.enableDeviceQrScanner, isTrue);
      expect(dependencies.enableEmergencyForegroundPolling, isTrue);
    });
  });
}
