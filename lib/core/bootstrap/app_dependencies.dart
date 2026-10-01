import '../network/security_api_client.dart';
import '../session/security_session_store.dart';
import '../../features/security/data/api/api_security_auth_repository.dart';
import '../../features/emergency/data/api/api_emergency_alert_repository.dart';
import '../../features/emergency/data/mock/mock_emergency_alert_repository.dart';
import '../../features/emergency/domain/repositories/emergency_alert_repository.dart';
import '../../features/incident/data/api/api_incident_repository.dart';
import '../../features/incident/data/mock/mock_incident_repository.dart';
import '../../features/incident/domain/repositories/incident_repository.dart';
import '../../features/patrol/data/api/api_patrol_repository.dart';
import '../../features/patrol/data/mock/mock_patrol_repository.dart';
import '../../features/patrol/domain/repositories/patrol_repository.dart';
import '../../features/package/data/api/api_security_package_repository.dart';
import '../../features/package/data/mock/mock_security_package_repository.dart';
import '../../features/package/domain/repositories/security_package_repository.dart';
import '../../features/security/data/api/api_security_dashboard_repository.dart';
import '../../features/security/data/mock/security_home_mock_data.dart';
import '../../features/security/domain/repositories/security_auth_repository.dart';
import '../../features/security/domain/repositories/security_dashboard_repository.dart';
import '../../features/visitor/data/api/api_visitor_repository.dart';
import '../../features/visitor/data/mock/mock_visitor_repository.dart';
import '../../features/visitor/domain/repositories/visitor_repository.dart';

class AppDependencies {
  const AppDependencies({
    required this.visitorRepository,
    required this.patrolRepository,
    required this.incidentRepository,
    required this.emergencyAlertRepository,
    required this.securityPackageRepository,
    this.securityAuthRepository,
    this.securityDashboardRepository,
    this.apiLocalization,
    this.enableDeviceQrScanner = false,
    this.enableEmergencyForegroundPolling = false,
  });

  final VisitorRepository visitorRepository;
  final PatrolRepository patrolRepository;
  final IncidentRepository incidentRepository;
  final EmergencyAlertRepository emergencyAlertRepository;
  final SecurityPackageRepository securityPackageRepository;
  final SecurityAuthRepository? securityAuthRepository;
  final SecurityDashboardRepository? securityDashboardRepository;
  final SecurityApiLocalization? apiLocalization;
  final bool enableDeviceQrScanner;
  final bool enableEmergencyForegroundPolling;

  bool get usesApi => securityAuthRepository != null;

  void setApiLanguageCode(String languageCode) {
    apiLocalization?.requestLanguageCode = languageCode;
  }

  factory AppDependencies.mock() {
    final actorName = SecurityHomeMockData.user.name;
    final patrolRepository = MockPatrolRepository(actorName: actorName);
    return AppDependencies(
      visitorRepository: MockVisitorRepository(actorName: actorName),
      patrolRepository: patrolRepository,
      incidentRepository: MockIncidentRepository(
        actorName: actorName,
        onPatrolIncidentCreated:
            patrolRepository.markCheckpointIssueFromIncident,
      ),
      emergencyAlertRepository: MockEmergencyAlertRepository(
        actorName: actorName,
      ),
      securityPackageRepository: MockSecurityPackageRepository(
        actorName: actorName,
      ),
    );
  }

  factory AppDependencies.api({
    required String baseUrl,
    SecuritySessionStore? sessionStore,
  }) {
    final client = IoSecurityApiClient(baseUrl: baseUrl);
    return AppDependencies(
      visitorRepository: ApiVisitorRepository(client),
      patrolRepository: ApiPatrolRepository(client),
      incidentRepository: ApiIncidentRepository(client),
      emergencyAlertRepository: ApiEmergencyAlertRepository(client),
      securityPackageRepository: ApiSecurityPackageRepository(client),
      securityDashboardRepository: ApiSecurityDashboardRepository(client),
      apiLocalization: client,
      securityAuthRepository: ApiSecurityAuthRepository(
        client,
        sessionStore: sessionStore,
      ),
      enableDeviceQrScanner: true,
      enableEmergencyForegroundPolling: true,
    );
  }

  factory AppDependencies.fromEnvironment() {
    const baseUrl = String.fromEnvironment('SECURITY_API_BASE_URL');
    const isReleaseBuild = bool.fromEnvironment('dart.vm.product');

    return AppDependencies.fromRuntimeConfig(
      baseUrl: baseUrl,
      isReleaseBuild: isReleaseBuild,
    );
  }

  factory AppDependencies.fromRuntimeConfig({
    required String baseUrl,
    required bool isReleaseBuild,
    SecuritySessionStore? sessionStore,
  }) {
    final normalizedBaseUrl = baseUrl.trim();

    if (normalizedBaseUrl.isEmpty) {
      if (isReleaseBuild) {
        throw StateError(
          'SECURITY_API_BASE_URL is required for release builds. '
          'Mock mode is intentionally disabled in release.',
        );
      }
      return AppDependencies.mock();
    }

    final uri = Uri.tryParse(normalizedBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'SECURITY_API_BASE_URL must be an absolute URL',
      );
    }

    final normalizedPath = uri.path.endsWith('/')
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (!normalizedPath.endsWith('/api/security')) {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'SECURITY_API_BASE_URL must end with /api/security',
      );
    }

    if (isReleaseBuild && uri.scheme != 'https') {
      throw ArgumentError.value(
        baseUrl,
        'baseUrl',
        'release builds require an HTTPS SECURITY_API_BASE_URL',
      );
    }

    return AppDependencies.api(
      baseUrl: normalizedBaseUrl,
      sessionStore: sessionStore,
    );
  }
}
