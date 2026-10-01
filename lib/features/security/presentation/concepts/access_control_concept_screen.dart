import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import 'widgets/concept_widgets.dart';

class AccessControlConceptScreen extends StatelessWidget {
  const AccessControlConceptScreen({
    required this.onBackHome,
    super.key,
  });

  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: l10n.accessControl,
        onBack: onBackHome,
      ),
      children: [
        ConceptNotice(message: l10n.accessConceptNotice),
        const _AccessTabs(),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: l10n.searchNameUnitIdentifier,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: const Icon(Icons.tune_rounded),
          ),
        ),
        _AccessPersonCard(
          name: 'Alexandra Smith',
          subtitle: l10n.unit12A,
          active: true,
        ),
        _AccessPersonCard(
          name: 'John Michael Doe',
          subtitle: l10n.visitorRole,
          active: false,
        ),
        _AccessPersonCard(
          name: 'PT Clean Facility',
          subtitle: l10n.vendors,
          active: true,
        ),
      ],
    );
  }
}

class _AccessTabs extends StatelessWidget {
  const _AccessTabs();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _AccessTab(label: l10n.residents, selected: true)),
          Expanded(child: _AccessTab(label: l10n.visitors)),
          Expanded(child: _AccessTab(label: l10n.vendors)),
        ],
      ),
    );
  }
}

class _AccessTab extends StatelessWidget {
  const _AccessTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: selected ? SecurityColors.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(SecurityRadius.sm),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected
                  ? SecurityColors.primary
                  : SecurityColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AccessPersonCard extends StatelessWidget {
  const _AccessPersonCard({
    required this.name,
    required this.subtitle,
    required this.active,
  });

  final String name;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = active ? l10n.activeStatus : l10n.inactiveStatus;

    return ConceptCard(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: SecurityColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: SecurityColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: SecuritySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: SecurityColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  l10n.accessStatus,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              ConceptPill(
                label: status.toUpperCase(),
                foreground:
                    active ? SecurityColors.success : SecurityColors.danger,
                background: active
                    ? SecurityColors.successSoft
                    : SecurityColors.dangerSoft,
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: active
                      ? SecurityColors.successSoft
                      : SecurityColors.dangerSoft,
                  borderRadius: BorderRadius.circular(SecurityRadius.sm),
                ),
                child: Icon(
                  active ? Icons.lock_open_rounded : Icons.lock_rounded,
                  color: active ? SecurityColors.success : SecurityColors.danger,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
