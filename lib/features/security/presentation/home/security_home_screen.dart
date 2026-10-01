import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/module_preview.dart';
import '../../domain/models/security_dashboard.dart';
import '../../domain/models/security_module_registry.dart';
import '../../domain/models/security_user.dart';

class SecurityHomeScreen extends StatelessWidget {
  const SecurityHomeScreen({
    required this.onOpenVisitorVerification,
    required this.onOpenPatrolManagement,
    required this.onOpenIncidentReporting,
    required this.onOpenEmergencyResponse,
    required this.onOpenPackageReceiving,
    required this.user,
    this.dashboard,
    this.dashboardLoading = false,
    this.dashboardErrorMessage,
    this.onRetryDashboard,
    this.onLogout,
    super.key,
  });

  final VoidCallback onOpenVisitorVerification;
  final VoidCallback onOpenPatrolManagement;
  final VoidCallback onOpenIncidentReporting;
  final VoidCallback onOpenEmergencyResponse;
  final VoidCallback onOpenPackageReceiving;
  final SecurityUser user;
  final SecurityDashboardSnapshot? dashboard;
  final bool dashboardLoading;
  final String? dashboardErrorMessage;
  final VoidCallback? onRetryDashboard;
  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    final modules = SecurityModuleRegistry.activeModules;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          SecuritySpacing.md,
          SecuritySpacing.xs,
          SecuritySpacing.md,
          SecuritySpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SecurityHomeHeader(onLogout: onLogout),
            const SizedBox(height: SecuritySpacing.lg),
            Text(
              context.l10n.goodMorning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Flexible(
                  child: Text(
                    user.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: SecuritySpacing.xs),
                const Icon(
                  Icons.verified_user_rounded,
                  size: 18,
                  color: SecurityColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${user.postName} • ${user.propertyName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textSecondary,
                  ),
            ),
            const SizedBox(height: SecuritySpacing.xl),
            if (dashboard != null || dashboardLoading || dashboardErrorMessage != null) ...[
              Text(
                context.l10n.todaysOverview,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              if (dashboardLoading && dashboard == null)
                const _DashboardLoadingCard()
              else if (dashboard != null)
                _OverviewRow(summary: dashboard!)
              else
                _DashboardErrorCard(
                  message: dashboardErrorMessage!,
                  onRetry: onRetryDashboard,
                ),
              const SizedBox(height: SecuritySpacing.xl),
            ],
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.securityModules,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  context.l10n.platform,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: SecurityColors.textMuted,
                      ),
                ),
              ],
            ),
            const SizedBox(height: SecuritySpacing.sm),
            GridView.builder(
              itemCount: modules.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: SecuritySpacing.sm,
                mainAxisSpacing: SecuritySpacing.sm,
                childAspectRatio: 1.55,
              ),
              itemBuilder: (context, index) {
                final module = modules[index];
                return _ModuleCard(
                  module: module,
                  onTap: () => _handleModuleTap(module),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleModuleTap(ModulePreview module) {
    switch (module.key) {
      case 'visitor_verification':
        onOpenVisitorVerification();
      case 'patrol_management':
        onOpenPatrolManagement();
      case 'incident_reporting':
        onOpenIncidentReporting();
      case 'emergency_response':
        onOpenEmergencyResponse();
      case 'package_receiving':
        onOpenPackageReceiving();
    }
  }
}

class _SecurityHomeHeader extends StatelessWidget {
  const _SecurityHomeHeader({this.onLogout});

  final Future<void> Function()? onLogout;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: onLogout == null ? context.l10n.menu : context.l10n.logout,
            onPressed: onLogout == null ? null : () => onLogout!(),
            icon: Icon(
              onLogout == null ? Icons.menu_rounded : Icons.logout_rounded,
            ),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              context.l10n.appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}


class _OverviewRow extends StatelessWidget {
  const _OverviewRow({required this.summary});

  final SecurityDashboardSnapshot summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OverviewCard(
            key: const Key('dashboardTotalVisitors'),
            value: summary.totalVisitors,
            label: context.l10n.todaysVisitors,
            valueColor: SecurityColors.primary,
          ),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: _OverviewCard(
            key: const Key('dashboardCheckedIn'),
            value: summary.checkedIn,
            label: context.l10n.checkedIn,
            valueColor: SecurityColors.success,
          ),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: _OverviewCard(
            key: const Key('dashboardCheckedOut'),
            value: summary.checkedOut,
            label: context.l10n.checkedOut,
            valueColor: SecurityColors.primary,
          ),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: _OverviewCard(
            key: const Key('dashboardApprovedArrivals'),
            value: summary.approvedArrivals,
            label: context.l10n.pendingArrivals,
            valueColor: SecurityColors.warning,
          ),
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.value,
    required this.label,
    required this.valueColor,
    super.key,
  });

  final int value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.symmetric(
        horizontal: SecuritySpacing.xs,
        vertical: SecuritySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
        boxShadow: SecurityShadows.soft,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: valueColor,
                  fontSize: 19,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoadingCard extends StatelessWidget {
  const _DashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: const CircularProgressIndicator(),
    );
  }
}

class _DashboardErrorCard extends StatelessWidget {
  const _DashboardErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: SecurityColors.textMuted),
          const SizedBox(width: SecuritySpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.onTap,
  });

  final ModulePreview module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(SecuritySpacing.sm),
          decoration: BoxDecoration(
            color: SecurityColors.primary,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(color: SecurityColors.primary),
            boxShadow: SecurityShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(36),
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                ),
                child: Icon(
                  _moduleIcon(module.key),
                  size: 19,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                _moduleTitle(context, module.key),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _moduleTitle(BuildContext context, String key) => switch (key) {
      'visitor_verification' => context.l10n.visitorVerification,
      'patrol_management' => context.l10n.patrolManagement,
      'incident_reporting' => context.l10n.incidentReporting,
      'emergency_response' => context.l10n.emergencyResponse,
      'package_receiving' => context.l10n.packageReceiving,
      _ => key,
    };

IconData _moduleIcon(String key) => switch (key) {
      'visitor_verification' => Icons.qr_code_scanner_rounded,
      'patrol_management' => Icons.shield_outlined,
      'incident_reporting' => Icons.assignment_late_outlined,
      'emergency_response' => Icons.warning_amber_rounded,
      'package_receiving' => Icons.inventory_2_outlined,
      _ => Icons.grid_view_rounded,
    };
