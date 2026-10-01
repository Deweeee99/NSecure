import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/visitor_visit.dart';
import '../widgets/visitor_formatters.dart';
import '../widgets/visitor_status_chip.dart';

enum VerificationHistoryFilter {
  all,
  checkedIn,
  checkedOut,
  pending,
  expired,
}

extension VerificationHistoryFilterMatch on VerificationHistoryFilter {
  bool matches(VisitorVisit visit) => switch (this) {
        VerificationHistoryFilter.all => true,
        VerificationHistoryFilter.checkedIn =>
          visit.status == VisitorStatus.checkedIn,
        VerificationHistoryFilter.checkedOut =>
          visit.status == VisitorStatus.checkedOut,
        VerificationHistoryFilter.pending => visit.status == VisitorStatus.pending,
        VerificationHistoryFilter.expired => visit.status == VisitorStatus.expired,
      };
}


class VerificationHistoryScreen extends StatelessWidget {
  const VerificationHistoryScreen({
    required this.visits,
    required this.selectedFilter,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onFilterChanged,
    required this.onVisitorSelected,
    super.key,
  });

  final List<VisitorVisit> visits;
  final VerificationHistoryFilter selectedFilter;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;
  final ValueChanged<VerificationHistoryFilter> onFilterChanged;
  final ValueChanged<VisitorVisit> onVisitorSelected;

  @override
  Widget build(BuildContext context) {
    final filtered = visits.where(selectedFilter.matches).toList(growable: false);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const _HistoryHeader(),
          SizedBox(
            height: 48,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: SecuritySpacing.md,
                vertical: SecuritySpacing.xs,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: VerificationHistoryFilter.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final filter = VerificationHistoryFilter.values[index];
                return _FilterPill(
                  filter: filter,
                  selected: filter == selectedFilter,
                  onTap: () => onFilterChanged(filter),
                );
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? _HistoryError(
                        message: errorMessage!,
                        onRetry: onRetry,
                      )
                    : filtered.isEmpty
                        ? _EmptyHistory(filter: selectedFilter)
                        : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          SecuritySpacing.md,
                          SecuritySpacing.sm,
                          SecuritySpacing.md,
                          SecuritySpacing.xl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: SecuritySpacing.sm),
                        itemBuilder: (context, index) {
                          final visit = filtered[index];
                          return _HistoryCard(
                            visit: visit,
                            onTap: () => onVisitorSelected(visit),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: SecuritySpacing.md),
      color: SecurityColors.surface,
      alignment: Alignment.center,
      child: Text(
        context.l10n.verificationHistory,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.filter,
    required this.selected,
    required this.onTap,
  });

  final VerificationHistoryFilter filter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('historyFilter_${filter.name}'),
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? SecurityColors.primary : SecurityColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? SecurityColors.primary : SecurityColors.border,
            ),
          ),
          child: Text(
            _filterLabel(context, filter),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? Colors.white : SecurityColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.visit, required this.onTap});

  final VisitorVisit visit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activityAt = visit.checkedOutAt ?? visit.checkedInAt ?? visit.scheduledAt;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: SecurityColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  size: 20,
                  color: SecurityColors.primary,
                ),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            visit.visitorName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const SizedBox(width: SecuritySpacing.xs),
                        VisitorStatusChip(status: visit.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      visit.visitCode,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SecurityColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: SecuritySpacing.xs),
                    Text(
                      _visitContext(context, visit),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      VisitorFormatters.dateTime(context, activityAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SecurityColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: SecurityColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


String _filterLabel(BuildContext context, VerificationHistoryFilter filter) {
  final l10n = context.l10n;
  return switch (filter) {
    VerificationHistoryFilter.all => l10n.all,
    VerificationHistoryFilter.checkedIn => l10n.checkedInStatus,
    VerificationHistoryFilter.checkedOut => l10n.checkedOutStatus,
    VerificationHistoryFilter.pending => l10n.visitorStatusPending,
    VerificationHistoryFilter.expired => l10n.expiredStatus,
  };
}

String _visitContext(BuildContext context, VisitorVisit visit) {
  final location = <String>[
    if (visit.towerName != null && visit.towerName!.isNotEmpty)
      visit.towerName!,
    if (visit.unitName != null && visit.unitName!.isNotEmpty)
      '${context.l10n.unit} ${visit.unitName}',
  ].join(' • ');
  return location.isEmpty
      ? visit.residentName
      : '$location • ${visit.residentName}';
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SecuritySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 44,
              color: SecurityColors.textMuted,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            Text(
              context.l10n.historyUnavailable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SecuritySpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: SecuritySpacing.md),
            FilledButton.icon(
              key: const Key('historyRetryButton'),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.filter});

  final VerificationHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SecuritySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.history_toggle_off_rounded,
              size: 44,
              color: SecurityColors.textMuted,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            Text(
              '${context.l10n.noRecords} • ${_filterLabel(context, filter)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SecuritySpacing.xs),
            Text(
              context.l10n.historyEmptyMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
