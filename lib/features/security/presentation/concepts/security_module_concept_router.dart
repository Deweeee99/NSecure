import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import 'access_control_concept_screen.dart';
import 'emergency_response_concept_screen.dart';
import 'incident_reporting_concept_screen.dart';
import 'vehicle_management_concept_screen.dart';
import 'widgets/concept_widgets.dart';

class SecurityModuleConceptRouter extends StatelessWidget {
  const SecurityModuleConceptRouter({
    required this.moduleKey,
    required this.onBackHome,
    super.key,
  });

  final String moduleKey;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return switch (moduleKey) {
      'incident_reporting' => IncidentReportingConceptScreen(
          onBackHome: onBackHome,
        ),
      'emergency_response' => EmergencyResponseConceptScreen(
          onBackHome: onBackHome,
        ),
      'access_control' => AccessControlConceptScreen(
          onBackHome: onBackHome,
        ),
      'vehicle_management' => VehicleManagementConceptScreen(
          onBackHome: onBackHome,
        ),
      _ => _UnknownConceptScreen(onBackHome: onBackHome),
    };
  }
}

class _UnknownConceptScreen extends StatelessWidget {
  const _UnknownConceptScreen({required this.onBackHome});

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: context.l10n.securityModule,
        onBack: onBackHome,
      ),
      children: [
        const ConceptNotice(),
        ConceptCard(
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: SecurityColors.primarySoft,
                  borderRadius: BorderRadius.circular(SecurityRadius.lg),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: SecurityColors.primary,
                ),
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Text(
                context.l10n.conceptScreenUndefined,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
