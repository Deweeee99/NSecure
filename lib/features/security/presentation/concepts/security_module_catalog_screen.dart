import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/localization/security_language_button.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/module_preview.dart';
import '../../domain/models/security_module_registry.dart';

class SecurityModuleCatalogScreen extends StatelessWidget {
  const SecurityModuleCatalogScreen({
    required this.onOpenVisitorVerification,
    required this.onOpenPatrolManagement,
    required this.onOpenIncidentReporting,
    required this.onOpenEmergencyResponse,
    required this.onOpenPackageReceiving,
    super.key,
  });

  final VoidCallback onOpenVisitorVerification;
  final VoidCallback onOpenPatrolManagement;
  final VoidCallback onOpenIncidentReporting;
  final VoidCallback onOpenEmergencyResponse;
  final VoidCallback onOpenPackageReceiving;

  @override
  Widget build(BuildContext context) {
    final modules = SecurityModuleRegistry.activeModules;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SecuritySpacing.md,
          SecuritySpacing.sm,
          SecuritySpacing.md,
          SecuritySpacing.xl,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.securityPlatform,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SecurityLanguageButton(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.platformCatalogDescription,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: SecuritySpacing.lg),
          Text(
            context.l10n.platformModules,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: SecuritySpacing.sm),
          ...modules.map(
            (module) => Padding(
              padding: const EdgeInsets.only(bottom: SecuritySpacing.sm),
              child: _CatalogModuleCard(
                module: module,
                onTap: () => _handleModuleTap(module),
              ),
            ),
          ),
        ],
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

class _CatalogModuleCard extends StatelessWidget {
  const _CatalogModuleCard({required this.module, required this.onTap});

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
          padding: const EdgeInsets.all(SecuritySpacing.md),
          decoration: BoxDecoration(
            color: SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(color: SecurityColors.border),
            boxShadow: SecurityShadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SecurityColors.primary,
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                ),
                child: Icon(
                  _moduleIcon(module.key),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _moduleTitle(context, module.key),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SecurityColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _moduleSubtitle(context, module.key),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: SecuritySpacing.xs),
              const Icon(
                Icons.chevron_right_rounded,
                color: SecurityColors.textMuted,
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

String _moduleSubtitle(BuildContext context, String key) => switch (key) {
      'visitor_verification' => context.l10n.visitorVerificationSubtitle,
      'patrol_management' => context.l10n.patrolManagementSubtitle,
      'incident_reporting' => context.l10n.incidentReportingSubtitle,
      'emergency_response' => context.l10n.emergencyResponseSubtitle,
      'package_receiving' => context.l10n.packageReceivingSubtitle,
      _ => '',
    };

IconData _moduleIcon(String key) => switch (key) {
      'visitor_verification' => Icons.qr_code_scanner_rounded,
      'patrol_management' => Icons.shield_outlined,
      'incident_reporting' => Icons.assignment_late_outlined,
      'emergency_response' => Icons.warning_amber_rounded,
      'package_receiving' => Icons.inventory_2_outlined,
      _ => Icons.grid_view_rounded,
    };
