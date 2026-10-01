import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import 'widgets/concept_widgets.dart';

class EmergencyResponseConceptScreen extends StatelessWidget {
  const EmergencyResponseConceptScreen({
    required this.onBackHome,
    super.key,
  });

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: l10n.emergencyResponse,
        onBack: onBackHome,
      ),
      children: [
        ConceptNotice(message: l10n.emergencyConceptNotice),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          decoration: BoxDecoration(
            color: SecurityColors.dangerSoft,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(color: SecurityColors.danger.withAlpha(100)),
          ),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: SecurityColors.danger,
                  borderRadius: BorderRadius.circular(SecurityRadius.sm),
                ),
                child: Text(
                  l10n.emergency,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        letterSpacing: .6,
                      ),
                ),
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Text(
                l10n.pressHoldThreeSeconds,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: SecuritySpacing.lg),
              const _SosConceptButton(),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                l10n.conceptOnlyDisabled,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        ConceptSectionTitle(title: l10n.emergencyContacts),
        ConceptCard(
          child: Column(
            children: [
              _EmergencyContactRow(
                label: l10n.securityCenter,
                number: '+62 21 1234 5678',
              ),
              const Divider(height: 1),
              _EmergencyContactRow(
                label: l10n.paramedic,
                number: '+62 21 8765 4321',
              ),
              const Divider(height: 1),
              _EmergencyContactRow(
                label: l10n.fireDepartment,
                number: '+62 21 1122 3344',
              ),
              const Divider(height: 1),
              _EmergencyContactRow(
                label: l10n.police,
                number: '+62 21 1100 9988',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SosConceptButton extends StatelessWidget {
  const _SosConceptButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SecurityColors.danger.withAlpha(18),
            ),
          ),
          Container(
            width: 98,
            height: 98,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SecurityColors.danger.withAlpha(35),
            ),
          ),
          Container(
            key: const Key('emergencySosConceptButton'),
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SecurityColors.danger,
              border: Border.all(color: Colors.white, width: 5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44E34949),
                  blurRadius: 18,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Text(
              context.l10n.sos,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactRow extends StatelessWidget {
  const _EmergencyContactRow({
    required this.label,
    required this.number,
  });

  final String label;
  final String number;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SecuritySpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: SecurityColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          Text(number, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(width: SecuritySpacing.xs),
          const Icon(
            Icons.phone_outlined,
            size: 17,
            color: SecurityColors.textMuted,
          ),
        ],
      ),
    );
  }
}
