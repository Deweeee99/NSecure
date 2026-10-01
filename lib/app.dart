import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsecure/l10n/app_localizations.dart';

import 'core/bootstrap/app_dependencies.dart';
import 'core/localization/security_locale_controller.dart';
import 'core/theme/security_theme.dart';
import 'features/security/data/mock/security_home_mock_data.dart';
import 'features/security/presentation/auth/security_auth_gate.dart';
import 'features/security/presentation/shell/security_app_shell.dart';

class NSecureApp extends StatefulWidget {
  const NSecureApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  State<NSecureApp> createState() => _NSecureAppState();
}

class _NSecureAppState extends State<NSecureApp> {
  late final AppDependencies _dependencies;
  late final SecurityLocaleController _localeController;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies ?? AppDependencies.fromEnvironment();
    _localeController = SecurityLocaleController();
    _localeController.addListener(_syncApiLocale);
    _syncApiLocale();
    unawaited(_localeController.load());
  }

  void _syncApiLocale() {
    _dependencies.setApiLanguageCode(_localeController.effectiveLanguageCode);
  }

  @override
  void dispose() {
    _localeController.removeListener(_syncApiLocale);
    _localeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _localeController,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: SecurityTheme.light(),
        locale: _localeController.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => SecurityLocaleScope(
          controller: _localeController,
          child: child ?? const SizedBox.shrink(),
        ),
        home: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    final authRepository = _dependencies.securityAuthRepository;
    if (authRepository == null) {
      return SecurityAppShell(
        visitorRepository: _dependencies.visitorRepository,
        patrolRepository: _dependencies.patrolRepository,
        incidentRepository: _dependencies.incidentRepository,
        emergencyAlertRepository: _dependencies.emergencyAlertRepository,
        securityPackageRepository: _dependencies.securityPackageRepository,
        securityDashboardRepository: _dependencies.securityDashboardRepository,
        enableDeviceQrScanner: _dependencies.enableDeviceQrScanner,
        enableEmergencyForegroundPolling:
            _dependencies.enableEmergencyForegroundPolling,
        showMockOperationalPreview: true,
        securityUser: SecurityHomeMockData.user,
      );
    }

    return SecurityAuthGate(
      repository: authRepository,
      builder: (user, logout) => SecurityAppShell(
        visitorRepository: _dependencies.visitorRepository,
        patrolRepository: _dependencies.patrolRepository,
        incidentRepository: _dependencies.incidentRepository,
        emergencyAlertRepository: _dependencies.emergencyAlertRepository,
        securityPackageRepository: _dependencies.securityPackageRepository,
        securityDashboardRepository: _dependencies.securityDashboardRepository,
        enableDeviceQrScanner: _dependencies.enableDeviceQrScanner,
        enableEmergencyForegroundPolling:
            _dependencies.enableEmergencyForegroundPolling,
        securityUser: user,
        onLogout: logout,
      ),
    );
  }
}
