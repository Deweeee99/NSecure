import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import 'widgets/concept_widgets.dart';

class VehicleManagementConceptScreen extends StatelessWidget {
  const VehicleManagementConceptScreen({
    required this.onBackHome,
    super.key,
  });

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: l10n.vehicleManagement,
        onBack: onBackHome,
      ),
      children: [
        ConceptNotice(message: l10n.vehicleConceptNotice),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: l10n.searchPlateNumber,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.filter_alt_outlined),
          ),
        ),
        ConceptCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'B 1234 ABC',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  ConceptPill(
                    label: l10n.registeredStatus,
                    foreground: SecurityColors.success,
                    background: SecurityColors.successSoft,
                  ),
                ],
              ),
              const SizedBox(height: SecuritySpacing.xs),
              ConceptInfoRow(label: l10n.vehicleType, value: l10n.vehicleSuv),
              ConceptInfoRow(label: l10n.ownerVisitor, value: 'Alexandra Smith'),
              ConceptInfoRow(label: l10n.residentUnitLabel, value: l10n.unit12A),
              ConceptInfoRow(
                label: l10n.registration,
                value: l10n.registered,
                valueColor: SecurityColors.success,
              ),
              ConceptInfoRow(
                label: l10n.parkingAccess,
                value: l10n.inside,
                valueColor: SecurityColors.success,
              ),
              ConceptInfoRow(
                label: l10n.lastEntry,
                value: '15 May 2024 • 07:52 AM',
              ),
              ConceptInfoRow(label: l10n.lastExit, value: '-'),
            ],
          ),
        ),
        ConceptSectionTitle(
          title: l10n.recentVehicleAccess,
          trailing: Text(
            l10n.viewAll,
            style: const TextStyle(
              color: SecurityColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ConceptCard(
          padding: const EdgeInsets.all(SecuritySpacing.sm),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: SecurityColors.primarySoft,
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                ),
                child: const Icon(
                  Icons.directions_car_outlined,
                  color: SecurityColors.primary,
                ),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'D 5678 DEF',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SecurityColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'John Michael Doe • ${l10n.visitorRole}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '15 May 2024 • 05:12 PM',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                    ),
                  ],
                ),
              ),
              ConceptPill(
                label: l10n.exitedStatus,
                foreground: SecurityColors.success,
                background: SecurityColors.successSoft,
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                color: SecurityColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
