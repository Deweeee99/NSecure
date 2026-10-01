import 'package:nsecure/core/bootstrap/app_dependencies.dart';
import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/features/emergency/data/api/api_emergency_alert_repository.dart';
import 'package:nsecure/features/incident/data/api/api_incident_repository.dart';
import 'package:nsecure/features/package/data/api/api_security_package_repository.dart';
import 'package:nsecure/features/patrol/data/api/api_patrol_repository.dart';
import 'package:nsecure/features/patrol/domain/models/patrol_models.dart';
import 'package:nsecure/features/security/data/api/api_security_auth_repository.dart';
import 'package:nsecure/features/security/data/api/api_security_dashboard_repository.dart';
import 'package:nsecure/features/visitor/data/api/api_visitor_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SEC.16 cumulative production readiness', () {
    test('release composition still wires every active software module', () {
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

    test(
      'shared production client preserves localization and multipart seams',
      () {
        final client = IoSecurityApiClient(
          baseUrl: 'https://security.example.test/api/security',
        );

        expect(client, isA<SecurityApiClient>());
        expect(client, isA<SecurityApiLocalization>());
        expect(client, isA<SecurityMultipartApiClient>());

        client.requestLanguageCode = 'id-ID';
        expect(client.requestLanguageCode, 'id');
        client.requestLanguageCode = 'en-US';
        expect(client.requestLanguageCode, 'en');
        client.requestLanguageCode = 'fr';
        expect(client.requestLanguageCode, 'en');
      },
    );

    test(
      'APH.42 photo input contract remains bounded to supported images',
      () {
        expect(
          PatrolPhotoInput.allowedMimeTypes,
          equals(<String>{'image/jpeg', 'image/png', 'image/webp'}),
        );
        expect(PatrolPhotoInput.maxFileSizeBytes, 5 * 1024 * 1024);
      },
    );
  });
}
