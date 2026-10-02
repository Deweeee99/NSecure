import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/security_task_preview.dart';

class SecurityTaskDetailScreen extends StatelessWidget {
  const SecurityTaskDetailScreen({
    required this.task,
    required this.onBackHome,
    required this.onRespond,
    super.key,
  });

  final SecurityTaskPreview task;
  final VoidCallback onBackHome;
  final VoidCallback onRespond;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('taskDetailBackButton'),
          onPressed: onBackHome,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.l10n.taskDetailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TaskSummaryCard(task: task),
              const SizedBox(height: SecuritySpacing.lg),
              Text(
                context.l10n.taskDetailInformation,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              _TaskMetadataCard(task: task),
              const SizedBox(height: SecuritySpacing.lg),
              Text(
                context.l10n.taskDetailInstruction,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(SecuritySpacing.md),
                decoration: BoxDecoration(
                  color: SecurityColors.surface,
                  borderRadius: BorderRadius.circular(SecurityRadius.lg),
                  border: Border.all(color: SecurityColors.border),
                ),
                child: Text(
                  context.l10n.taskDispatchInstruction,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: SecuritySpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('taskDetailRespondButton'),
                  onPressed: onRespond,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: Text(context.l10n.taskDetailRespondAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  const _TaskSummaryCard({required this.task});

  final SecurityTaskPreview task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
                child: Text(
                  context.l10n.taskDispatchTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _PriorityChip(priority: task.priority),
            ],
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            task.location ?? context.l10n.taskDetailUnknownValue,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: SecurityColors.textSecondary,
                ),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 18,
                color: SecurityColors.textMuted,
              ),
              const SizedBox(width: SecuritySpacing.xs),
              Text(
                task.id,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskMetadataCard extends StatelessWidget {
  const _TaskMetadataCard({required this.task});

  final SecurityTaskPreview task;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          _MetadataRow(
            icon: Icons.location_on_outlined,
            label: context.l10n.taskDetailLocation,
            value: task.location ?? context.l10n.taskDetailUnknownValue,
          ),
          const Divider(height: SecuritySpacing.lg),
          _MetadataRow(
            icon: Icons.flag_outlined,
            label: context.l10n.taskDetailPriority,
            value: _priorityLabel(context, task.priority),
          ),
          const Divider(height: SecuritySpacing.lg),
          _MetadataRow(
            icon: Icons.hub_outlined,
            label: context.l10n.taskDetailSource,
            value: task.source ?? context.l10n.taskDetailUnknownValue,
          ),
          const Divider(height: SecuritySpacing.lg),
          _MetadataRow(
            icon: Icons.schedule_outlined,
            label: context.l10n.taskDetailCreatedAt,
            value: task.createdAtLabel ?? context.l10n.taskDetailUnknownValue,
          ),
          const Divider(height: SecuritySpacing.lg),
          _MetadataRow(
            icon: Icons.pending_actions_outlined,
            label: context.l10n.taskDetailStatus,
            value: context.l10n.taskDetailStatusAwaitingResponse,
          ),
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: SecurityColors.textMuted),
        const SizedBox(width: SecuritySpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final SecurityTaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final highPriority = priority == SecurityTaskPriority.high ||
        priority == SecurityTaskPriority.critical;
    final color = highPriority ? SecurityColors.danger : SecurityColors.info;
    final softColor =
        highPriority ? SecurityColors.dangerSoft : SecurityColors.infoSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SecuritySpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _priorityLabel(context, priority),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

String _priorityLabel(BuildContext context, SecurityTaskPriority priority) =>
    switch (priority) {
      SecurityTaskPriority.normal => context.l10n.taskPriorityNormal,
      SecurityTaskPriority.high => context.l10n.taskPriorityHigh,
      SecurityTaskPriority.critical => context.l10n.taskPriorityCritical,
    };
