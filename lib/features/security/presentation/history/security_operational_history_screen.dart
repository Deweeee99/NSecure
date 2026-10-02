import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/security_task_history_entry.dart';
import '../../domain/models/security_task_preview.dart';

class SecurityOperationalHistoryScreen extends StatelessWidget {
  const SecurityOperationalHistoryScreen({
    required this.completedTasks,
    required this.onOpenVisitorHistory,
    super.key,
  });

  final List<SecurityTaskHistoryEntry> completedTasks;
  final VoidCallback onOpenVisitorHistory;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: SecuritySpacing.md),
            color: SecurityColors.surface,
            alignment: Alignment.center,
            child: Text(
              context.l10n.history,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.md,
                SecuritySpacing.md,
                SecuritySpacing.xl,
              ),
              children: [
                Text(
                  context.l10n.completedTasks,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.completedTasksSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: SecuritySpacing.sm),
                if (completedTasks.isEmpty)
                  const _EmptyCompletedTasks()
                else
                  for (final entry in completedTasks) ...[
                    _CompletedTaskCard(entry: entry),
                    const SizedBox(height: SecuritySpacing.sm),
                  ],
                const SizedBox(height: SecuritySpacing.md),
                _VisitorHistoryCard(onTap: onOpenVisitorHistory),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCompletedTasks extends StatelessWidget {
  const _EmptyCompletedTasks();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.task_alt_rounded,
            color: SecurityColors.textMuted,
          ),
          const SizedBox(width: SecuritySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.noCompletedTasks,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.noCompletedTasksMessage,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletedTaskCard extends StatelessWidget {
  const _CompletedTaskCard({required this.entry});

  final SecurityTaskHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final task = entry.task;
    final material = MaterialLocalizations.of(context);
    final completedAt =
        '${material.formatMediumDate(entry.completedAt)} • '
        '${material.formatTimeOfDay(TimeOfDay.fromDateTime(entry.completedAt))}';

    return Container(
      key: Key('completedTask_${task.id}'),
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
              const Icon(
                Icons.task_alt_rounded,
                color: SecurityColors.success,
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Text(
                  _taskTitle(context, task.type),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SecurityColors.successSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  context.l10n.taskCompletedStatus,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: SecurityColors.success,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(task.id, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Text(
            _taskSubtitle(context, task.type),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            completedAt,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SecurityColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.image_outlined,
                size: 18,
                color: SecurityColors.textMuted,
              ),
              const SizedBox(width: SecuritySpacing.xs),
              Expanded(
                child: Text(
                  '${context.l10n.taskEvidenceAttached}: '
                  '${entry.evidenceFileName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VisitorHistoryCard extends StatelessWidget {
  const _VisitorHistoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const Key('openVisitorVerificationHistory'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(SecuritySpacing.md),
          decoration: BoxDecoration(
            color: SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(color: SecurityColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.people_outline_rounded,
                color: SecurityColors.primary,
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.visitorVerificationHistory,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.visitorVerificationHistorySubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
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

String _taskTitle(BuildContext context, SecurityTaskPreviewType type) =>
    switch (type) {
      SecurityTaskPreviewType.patrol => context.l10n.taskPatrolTitle,
      SecurityTaskPreviewType.visitor => context.l10n.taskVisitorTitle,
      SecurityTaskPreviewType.incident => context.l10n.taskIncidentTitle,
      SecurityTaskPreviewType.dispatch => context.l10n.taskDispatchTitle,
    };

String _taskSubtitle(BuildContext context, SecurityTaskPreviewType type) =>
    switch (type) {
      SecurityTaskPreviewType.patrol => context.l10n.taskPatrolSubtitle,
      SecurityTaskPreviewType.visitor => context.l10n.taskVisitorSubtitle,
      SecurityTaskPreviewType.incident => context.l10n.taskIncidentSubtitle,
      SecurityTaskPreviewType.dispatch => context.l10n.taskDispatchSubtitle,
    };
