import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/visitor_visit.dart';
import '../widgets/visitor_formatters.dart';
import '../widgets/visitor_status_chip.dart';

class VisitorSearchResultsScreen extends StatelessWidget {
  const VisitorSearchResultsScreen({
    required this.query,
    required this.results,
    required this.resultOriginLabel,
    required this.onBack,
    required this.onVisitorSelected,
    super.key,
  });

  final String query;
  final List<VisitorVisit> results;
  final String resultOriginLabel;
  final VoidCallback onBack;
  final ValueChanged<VisitorVisit> onVisitorSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _ResultsHeader(onBack: onBack),
          Expanded(
            child: results.isEmpty
                ? _EmptyResults(query: query, onBack: onBack)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      SecuritySpacing.md,
                      SecuritySpacing.md,
                      SecuritySpacing.md,
                      SecuritySpacing.xl,
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${results.length} ${results.length == 1 ? context.l10n.result : context.l10n.results}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: SecurityColors.textSecondary,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: SecurityColors.primarySoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              resultOriginLabel,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: SecurityColors.primary,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SecuritySpacing.sm),
                      for (final visit in results) ...[
                        _VisitorResultCard(
                          visit: visit,
                          onTap: () => onVisitorSelected(visit),
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      color: SecurityColors.surface,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: context.l10n.back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              context.l10n.searchResults,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(context.l10n.advancedFiltersDeferred)),
                );
            },
            tooltip: context.l10n.filters,
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
    );
  }
}

class _VisitorResultCard extends StatelessWidget {
  const _VisitorResultCard({
    required this.visit,
    required this.onTap,
  });

  final VisitorVisit visit;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.visitorName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          visit.visitCode,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: SecurityColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: SecuritySpacing.sm),
                  VisitorStatusChip(status: visit.status),
                ],
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Text(
                '${visit.residentName} • ${VisitorFormatters.unitAndTower(context, unitName: visit.unitName, towerName: visit.towerName)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: SecurityColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${VisitorFormatters.date(context, visit.scheduledAt)} • ${VisitorFormatters.time(context, visit.validFrom)} – ${VisitorFormatters.time(context, visit.validUntil)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: SecurityColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.query,
    required this.onBack,
  });

  final String query;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(SecuritySpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: SecurityColors.primarySoft,
                  borderRadius: BorderRadius.circular(SecurityRadius.lg),
                ),
                child: const Icon(
                  Icons.person_search_outlined,
                  color: SecurityColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(height: SecuritySpacing.lg),
              Text(
                context.l10n.visitorNotFound,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                '${context.l10n.noVisitorMatchPrefix} “$query”. ${context.l10n.noVisitorMatchSuffix}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: SecuritySpacing.lg),
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(context.l10n.backToVerification),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
