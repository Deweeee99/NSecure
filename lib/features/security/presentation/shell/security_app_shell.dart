import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../../emergency/domain/models/emergency_alert_models.dart';
import '../../../emergency/domain/repositories/emergency_alert_repository.dart';
import '../../../emergency/presentation/emergency_alert_overlay.dart';
import '../../../emergency/presentation/emergency_management_screen.dart';
import '../../../incident/domain/models/incident_models.dart';
import '../../../incident/domain/repositories/incident_repository.dart';
import '../../../incident/presentation/incident_management_screen.dart';
import '../../../patrol/domain/models/patrol_models.dart';
import '../../../patrol/domain/repositories/patrol_repository.dart';
import '../../../patrol/presentation/patrol_management_screen.dart';
import '../../../package/domain/repositories/security_package_repository.dart';
import '../../../package/presentation/package_management_screen.dart';
import '../../../visitor/domain/repositories/visitor_repository.dart';
import '../../../visitor/presentation/history/verification_history_flow.dart';
import '../../../visitor/presentation/verification/visitor_verification_flow.dart';
import '../../data/mock/security_home_mock_data.dart';
import '../../domain/models/security_dashboard.dart';
import '../../domain/models/security_task_preview.dart';
import '../../domain/models/security_user.dart';
import '../../domain/repositories/security_dashboard_repository.dart';
import '../concepts/security_module_catalog_screen.dart';
import '../home/security_home_screen.dart';
import '../task/security_task_response_screen.dart';

class SecurityAppShell extends StatefulWidget {
  const SecurityAppShell({
    required this.visitorRepository,
    required this.patrolRepository,
    required this.incidentRepository,
    required this.emergencyAlertRepository,
    required this.securityPackageRepository,
    this.securityDashboardRepository,
    this.enableDeviceQrScanner = false,
    this.enableEmergencyForegroundPolling = false,
    this.showMockOperationalPreview = false,
    required this.securityUser,
    this.onLogout,
    super.key,
  });

  final VisitorRepository visitorRepository;
  final PatrolRepository patrolRepository;
  final IncidentRepository incidentRepository;
  final EmergencyAlertRepository emergencyAlertRepository;
  final SecurityPackageRepository securityPackageRepository;
  final SecurityDashboardRepository? securityDashboardRepository;
  final bool enableDeviceQrScanner;
  final bool enableEmergencyForegroundPolling;
  final bool showMockOperationalPreview;
  final SecurityUser securityUser;
  final Future<void> Function()? onLogout;

  @override
  State<SecurityAppShell> createState() => _SecurityAppShellState();
}

class _SecurityAppShellState extends State<SecurityAppShell>
    with WidgetsBindingObserver {
  static const _emergencyPollInterval = Duration(seconds: 15);

  int _currentIndex = 0;
  int _visitorRevision = 0;
  bool _patrolOpen = false;
  bool _incidentOpen = false;
  bool _emergencyOpen = false;
  bool _packageOpen = false;
  SecurityTaskPreview? _selectedTask;
  late List<SecurityTaskPreview> _activeTasks;
  bool _incidentReturnsToPatrol = false;
  IncidentCreateContext? _incidentCreateContext;
  int? _initialEmergencyAlertId;

  final _visitorFlowKey = GlobalKey<VisitorVerificationFlowState>();
  final _historyFlowKey = GlobalKey<VerificationHistoryFlowState>();

  Timer? _emergencyPollTimer;
  List<EmergencyAlert> _activeEmergencyAlerts = const <EmergencyAlert>[];
  bool _emergencyPolling = false;
  bool _emergencySubmitting = false;
  String? _emergencyModalError;

  SecurityDashboardSnapshot? _dashboard;
  SecurityDashboardFailureCode? _dashboardFailure;
  bool _dashboardLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeTasks = widget.showMockOperationalPreview
        ? List<SecurityTaskPreview>.of(SecurityHomeMockData.activeTasks)
        : <SecurityTaskPreview>[];
    unawaited(_refreshEmergencyAlerts());
    unawaited(_refreshDashboard());
    if (widget.enableEmergencyForegroundPolling) {
      _emergencyPollTimer = Timer.periodic(
        _emergencyPollInterval,
        (_) => unawaited(_refreshEmergencyAlerts()),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshEmergencyAlerts());
      unawaited(_refreshDashboard());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _emergencyPollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeEmergency = _activeEmergencyAlerts.isEmpty
        ? null
        : _activeEmergencyAlerts.first;

    return PopScope(
      canPop: _isAtRoot && activeEmergency == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Stack(
        children: [
          Scaffold(
            body: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeArea(),
                VisitorVerificationFlow(
                  key: _visitorFlowKey,
                  repository: widget.visitorRepository,
                  enableDeviceQrScanner: widget.enableDeviceQrScanner,
                  onBackHome: () => _selectTab(0),
                  onVisitUpdated: _markVisitorUpdated,
                  onSessionExpired: widget.onLogout,
                ),
                VerificationHistoryFlow(
                  key: _historyFlowKey,
                  repository: widget.visitorRepository,
                  refreshRevision: _visitorRevision,
                  onVisitUpdated: _markVisitorUpdated,
                  onContinueVerifying: () => _selectTab(1),
                  onSessionExpired: widget.onLogout,
                ),
                SecurityModuleCatalogScreen(
                  onOpenVisitorVerification: () => _selectTab(1),
                  onOpenPatrolManagement: _openPatrol,
                  onOpenIncidentReporting: _openIncident,
                  onOpenEmergencyResponse: () => _openEmergency(),
                  onOpenPackageReceiving: _openPackageReceiving,
                ),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: _selectTab,
              type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: context.l10n.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.qr_code_scanner),
                  activeIcon: const Icon(Icons.qr_code_scanner),
                  label: context.l10n.verify,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.history_outlined),
                  activeIcon: const Icon(Icons.history_rounded),
                  label: context.l10n.history,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.menu_rounded),
                  activeIcon: const Icon(Icons.menu_rounded),
                  label: context.l10n.more,
                ),
              ],
            ),
          ),
          if (activeEmergency != null)
            Positioned.fill(
              child: EmergencyAlertOverlay(
                alert: activeEmergency,
                isSubmitting: _emergencySubmitting,
                errorMessage: _emergencyModalError,
                onAcknowledge: () => _acknowledgeEmergency(activeEmergency),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHomeArea() {
    final selectedTask = _selectedTask;
    if (selectedTask != null) {
      return SecurityTaskResponseScreen(
        task: selectedTask,
        onBackHome: _closeTaskResponse,
        onCompleted: _completeTaskResponse,
      );
    }

    if (_emergencyOpen) {
      return EmergencyManagementScreen(
        repository: widget.emergencyAlertRepository,
        initialAlertId: _initialEmergencyAlertId,
        onBackHome: _closeEmergency,
        onActiveAlertsChanged: () => unawaited(_refreshEmergencyAlerts()),
        onSessionExpired: widget.onLogout,
      );
    }

    if (_packageOpen) {
      return PackageManagementScreen(
        repository: widget.securityPackageRepository,
        onBackHome: _closePackageReceiving,
        onSessionExpired: widget.onLogout,
      );
    }

    if (_incidentOpen) {
      return IncidentManagementScreen(
        repository: widget.incidentRepository,
        securityUser: widget.securityUser,
        initialCreateContext: _incidentCreateContext,
        onBackHome: _closeIncident,
        onSessionExpired: widget.onLogout,
      );
    }

    if (_patrolOpen) {
      return PatrolManagementScreen(
        repository: widget.patrolRepository,
        onBackHome: _closePatrol,
        onReportIncident: _openIncidentFromPatrol,
        onSessionExpired: widget.onLogout,
      );
    }

    return SecurityHomeScreen(
      user: widget.securityUser,
      activeTasks: _activeTasks,
      onOpenTaskResponse: _openTaskResponse,
      dashboard: _dashboard,
      dashboardLoading: _dashboardLoading,
      dashboardErrorMessage: _dashboardFailure == null
          ? null
          : _dashboardFailureMessage(context, _dashboardFailure!),
      onRetryDashboard: widget.securityDashboardRepository == null
          ? null
          : () => unawaited(_refreshDashboard()),
      onLogout: widget.onLogout,
      onOpenVisitorVerification: () => _selectTab(1),
      onOpenPatrolManagement: _openPatrol,
      onOpenIncidentReporting: _openIncident,
      onOpenEmergencyResponse: () => _openEmergency(),
      onOpenPackageReceiving: _openPackageReceiving,
    );
  }

  Future<void> _refreshDashboard() async {
    final repository = widget.securityDashboardRepository;
    if (repository == null || _dashboardLoading) return;

    if (mounted) {
      setState(() {
        _dashboardLoading = true;
        _dashboardFailure = null;
      });
    }

    try {
      final dashboard = await repository.load();
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _dashboardFailure = null;
      });
    } on SecurityDashboardException catch (error) {
      if (error.code == SecurityDashboardFailureCode.unauthorized) {
        final logout = widget.onLogout;
        if (logout != null) await logout();
        return;
      }
      if (!mounted) return;
      setState(() {
        _dashboard = null;
        _dashboardFailure = error.code;
      });
    } finally {
      if (mounted) setState(() => _dashboardLoading = false);
    }
  }

  Future<void> _refreshEmergencyAlerts() async {
    if (_emergencyPolling) return;
    _emergencyPolling = true;
    try {
      final alerts = await widget.emergencyAlertRepository.activeAlerts();
      if (!mounted) return;
      setState(() {
        _activeEmergencyAlerts = alerts;
        _emergencyModalError = null;
      });
    } on EmergencyRepositoryException catch (error) {
      if (error.code == EmergencyRepositoryFailureCode.unauthorized) {
        final logout = widget.onLogout;
        if (logout != null) await logout();
        return;
      }
      if (!mounted || _activeEmergencyAlerts.isEmpty) return;
      setState(() {
        _emergencyModalError = _emergencyFailureMessage(context, error);
      });
    } finally {
      _emergencyPolling = false;
    }
  }

  Future<void> _acknowledgeEmergency(EmergencyAlert alert) async {
    if (_emergencySubmitting) return;
    setState(() {
      _emergencySubmitting = true;
      _emergencyModalError = null;
    });
    try {
      await widget.emergencyAlertRepository.acknowledge(alert.emergencyAlertId);
      if (mounted) {
        setState(() {
          _activeEmergencyAlerts = _activeEmergencyAlerts
              .where(
                (item) =>
                    item.emergencyAlertId != alert.emergencyAlertId,
              )
              .toList(growable: false);
        });
      }
      await _refreshEmergencyAlerts();
    } on EmergencyRepositoryException catch (error) {
      if (error.code == EmergencyRepositoryFailureCode.unauthorized) {
        final logout = widget.onLogout;
        if (logout != null) await logout();
        return;
      }
      if (error.code == EmergencyRepositoryFailureCode.alreadyTaken ||
          error.code == EmergencyRepositoryFailureCode.alreadyResolved ||
          error.code == EmergencyRepositoryFailureCode.notFound) {
        await _refreshEmergencyAlerts();
      } else if (mounted) {
        setState(() {
          _emergencyModalError = _emergencyFailureMessage(context, error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _emergencySubmitting = false);
      }
    }
  }

  bool get _isAtRoot =>
      _currentIndex == 0 &&
      !_patrolOpen &&
      !_incidentOpen &&
      !_emergencyOpen &&
      !_packageOpen &&
      _selectedTask == null;

  void _handleSystemBack() {
    if (_activeEmergencyAlerts.isNotEmpty) return;

    if (_currentIndex == 1) {
      final handled = _visitorFlowKey.currentState?.handleSystemBack() ?? false;
      if (!handled) _selectTab(0);
      return;
    }

    if (_currentIndex == 2) {
      final handled = _historyFlowKey.currentState?.handleSystemBack() ?? false;
      if (!handled) _selectTab(0);
      return;
    }

    if (_currentIndex == 3) {
      _selectTab(0);
      return;
    }

    if (_selectedTask != null) {
      _closeTaskResponse();
      return;
    }

    if (_incidentOpen) {
      _closeIncident();
      return;
    }
    if (_patrolOpen) {
      _closePatrol();
      return;
    }
    if (_emergencyOpen) {
      _closeEmergency();
      return;
    }
    if (_packageOpen) {
      _closePackageReceiving();
    }
  }

  void _selectTab(int index) {
    if (index == 0 && _currentIndex != 0) {
      unawaited(_refreshDashboard());
    }

    if (_currentIndex == index &&
        index == 0 &&
        (_patrolOpen ||
            _incidentOpen ||
            _emergencyOpen ||
            _packageOpen ||
            _selectedTask != null)) {
      setState(_resetHomeRoutes);
      return;
    }

    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
      _resetHomeRoutes();
    });
  }

  void _resetHomeRoutes() {
    _patrolOpen = false;
    _incidentOpen = false;
    _emergencyOpen = false;
    _packageOpen = false;
    _selectedTask = null;
    _incidentReturnsToPatrol = false;
    _incidentCreateContext = null;
    _initialEmergencyAlertId = null;
  }

  void _openTaskResponse(SecurityTaskPreview task) {
    switch (task.type) {
      case SecurityTaskPreviewType.patrol:
        _openPatrol();
        return;
      case SecurityTaskPreviewType.visitor:
        _selectTab(1);
        return;
      case SecurityTaskPreviewType.incident:
        _openIncident();
        return;
      case SecurityTaskPreviewType.dispatch:
        setState(() {
          _currentIndex = 0;
          _resetHomeRoutes();
          _selectedTask = task;
        });
        return;
    }
  }

  void _closeTaskResponse() {
    setState(() {
      _currentIndex = 0;
      _selectedTask = null;
    });
  }

  void _completeTaskResponse(SecurityTaskPreview task) {
    setState(() {
      _currentIndex = 0;
      _activeTasks = _activeTasks
          .where((item) => item.id != task.id)
          .toList(growable: false);
      _selectedTask = null;
    });
  }

  void _openPatrol() {
    setState(() {
      _currentIndex = 0;
      _resetHomeRoutes();
      _patrolOpen = true;
    });
  }

  void _openIncident() {
    setState(() {
      _currentIndex = 0;
      _resetHomeRoutes();
      _incidentOpen = true;
    });
  }

  void _openEmergency({int? alertId}) {
    setState(() {
      _currentIndex = 0;
      _resetHomeRoutes();
      _emergencyOpen = true;
      _initialEmergencyAlertId = alertId;
    });
    unawaited(_refreshEmergencyAlerts());
  }

  void _openPackageReceiving() {
    setState(() {
      _currentIndex = 0;
      _resetHomeRoutes();
      _packageOpen = true;
    });
  }

  void _openIncidentFromPatrol(
    PatrolSession session,
    PatrolCheckpointVisit checkpoint,
  ) {
    setState(() {
      _currentIndex = 0;
      _patrolOpen = false;
      _incidentOpen = true;
      _emergencyOpen = false;
      _packageOpen = false;
      _incidentReturnsToPatrol = true;
      _initialEmergencyAlertId = null;
      _incidentCreateContext = IncidentCreateContext(
        propertyId: session.property.id,
        patrolCheckpointVisitId: checkpoint.visitId,
        sessionNumber: session.sessionNumber,
        checkpointName: checkpoint.name,
        location: checkpoint.locationLabel,
      );
    });
  }

  void _closeIncident() {
    setState(() {
      _currentIndex = 0;
      _incidentOpen = false;
      _patrolOpen = _incidentReturnsToPatrol;
      _incidentReturnsToPatrol = false;
      _incidentCreateContext = null;
    });
  }

  void _closePatrol() {
    setState(() {
      _currentIndex = 0;
      _patrolOpen = false;
      _incidentReturnsToPatrol = false;
      _incidentCreateContext = null;
    });
  }

  void _closeEmergency() {
    setState(() {
      _currentIndex = 0;
      _emergencyOpen = false;
      _initialEmergencyAlertId = null;
    });
  }

  void _closePackageReceiving() {
    setState(() {
      _currentIndex = 0;
      _packageOpen = false;
    });
  }

  void _markVisitorUpdated() {
    setState(() {
      _visitorRevision += 1;
    });
    unawaited(_refreshDashboard());
  }
}


String _dashboardFailureMessage(
  BuildContext context,
  SecurityDashboardFailureCode failure,
) {
  return switch (failure) {
    SecurityDashboardFailureCode.forbidden => context.l10n.dashboardUnavailable,
    SecurityDashboardFailureCode.network => context.l10n.dashboardNetworkRetry,
    SecurityDashboardFailureCode.unauthorized => context.l10n.authUnauthenticated,
    SecurityDashboardFailureCode.unknown => context.l10n.dashboardLoadFailed,
  };
}

String _emergencyFailureMessage(
  BuildContext context,
  EmergencyRepositoryException error,
) {
  return switch (error.code) {
    EmergencyRepositoryFailureCode.notFound =>
      context.l10n.emergencyFailureNotFound,
    EmergencyRepositoryFailureCode.alreadyTaken =>
      context.l10n.emergencyFailureAlreadyTaken,
    EmergencyRepositoryFailureCode.alreadyResolved =>
      context.l10n.emergencyFailureAlreadyResolved,
    EmergencyRepositoryFailureCode.notAcknowledged =>
      context.l10n.emergencyFailureNotAcknowledged,
    EmergencyRepositoryFailureCode.assignedToOther =>
      context.l10n.emergencyFailureAssignedToOther,
    EmergencyRepositoryFailureCode.validation =>
      context.l10n.emergencyFailureValidation,
    EmergencyRepositoryFailureCode.unauthorized =>
      context.l10n.authUnauthenticated,
    EmergencyRepositoryFailureCode.forbidden => context.l10n.authForbidden,
    EmergencyRepositoryFailureCode.network => context.l10n.authNetwork,
    EmergencyRepositoryFailureCode.unknown =>
      error.message?.trim().isNotEmpty == true
          ? error.message!
          : context.l10n.emergencyFailureUnknown,
  };
}
