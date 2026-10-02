import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/security_task_preview.dart';

enum SecurityTaskResponseStage {
  assigned,
  accepted,
  enRoute,
  arrived,
  handling,
  completed,
}

class SecurityTaskResponseScreen extends StatefulWidget {
  const SecurityTaskResponseScreen({
    required this.task,
    required this.onBackHome,
    required this.onCompleted,
    super.key,
  });

  final SecurityTaskPreview task;
  final VoidCallback onBackHome;
  final ValueChanged<SecurityTaskPreview> onCompleted;

  @override
  State<SecurityTaskResponseScreen> createState() =>
      _SecurityTaskResponseScreenState();
}

class _SecurityTaskResponseScreenState
    extends State<SecurityTaskResponseScreen> {
  SecurityTaskResponseStage _stage = SecurityTaskResponseStage.assigned;
  bool _evidenceAttached = false;

  @override
  Widget build(BuildContext context) {
    if (_stage == SecurityTaskResponseStage.completed) {
      return _TaskCompletedView(
        task: widget.task,
        onBackHome: () => widget.onCompleted(widget.task),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          key: const Key('taskResponseBackButton'),
          onPressed: widget.onBackHome,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(context.l10n.taskResponseTitle),
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
              _TaskIdentityCard(task: widget.task),
              const SizedBox(height: SecuritySpacing.lg),
              Text(
                context.l10n.taskWorkflowTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              _TaskWorkflow(stage: _stage),
              if (_stage == SecurityTaskResponseStage.handling) ...[
                const SizedBox(height: SecuritySpacing.lg),
                _EvidenceCard(
                  attached: _evidenceAttached,
                  fileName: 'evidence_${widget.task.id.toLowerCase()}.jpg',
                  onAttach: () => setState(() => _evidenceAttached = true),
                ),
              ],
              const SizedBox(height: SecuritySpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('taskPrimaryAction'),
                  onPressed: _canAdvance ? _advance : null,
                  child: Text(_primaryActionLabel(context)),
                ),
              ),
              if (_stage == SecurityTaskResponseStage.handling &&
                  !_evidenceAttached) ...[
                const SizedBox(height: SecuritySpacing.xs),
                Text(
                  context.l10n.taskEvidenceRequired,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SecurityColors.textSecondary,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool get _canAdvance =>
      _stage != SecurityTaskResponseStage.handling || _evidenceAttached;

  void _advance() {
    setState(() {
      _stage = switch (_stage) {
        SecurityTaskResponseStage.assigned => SecurityTaskResponseStage.accepted,
        SecurityTaskResponseStage.accepted => SecurityTaskResponseStage.enRoute,
        SecurityTaskResponseStage.enRoute => SecurityTaskResponseStage.arrived,
        SecurityTaskResponseStage.arrived => SecurityTaskResponseStage.handling,
        SecurityTaskResponseStage.handling => SecurityTaskResponseStage.completed,
        SecurityTaskResponseStage.completed => SecurityTaskResponseStage.completed,
      };
    });
  }

  String _primaryActionLabel(BuildContext context) => switch (_stage) {
        SecurityTaskResponseStage.assigned => context.l10n.taskActionAccept,
        SecurityTaskResponseStage.accepted => context.l10n.taskActionEnRoute,
        SecurityTaskResponseStage.enRoute => context.l10n.taskActionArrive,
        SecurityTaskResponseStage.arrived => context.l10n.taskActionHandle,
        SecurityTaskResponseStage.handling => context.l10n.taskActionComplete,
        SecurityTaskResponseStage.completed => context.l10n.taskBackToHome,
      };
}

class _TaskIdentityCard extends StatelessWidget {
  const _TaskIdentityCard({required this.task});

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
          Text(
            _taskTitle(context, task.type),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            _taskSubtitle(context, task.type),
            style: Theme.of(context).textTheme.bodyMedium,
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

class _TaskWorkflow extends StatelessWidget {
  const _TaskWorkflow({required this.stage});

  final SecurityTaskResponseStage stage;

  @override
  Widget build(BuildContext context) {
    final steps = <(SecurityTaskResponseStage, String)>[
      (SecurityTaskResponseStage.assigned, context.l10n.taskStageAssigned),
      (SecurityTaskResponseStage.accepted, context.l10n.taskStageAccepted),
      (SecurityTaskResponseStage.enRoute, context.l10n.taskStageEnRoute),
      (SecurityTaskResponseStage.arrived, context.l10n.taskStageArrived),
      (SecurityTaskResponseStage.handling, context.l10n.taskStageHandling),
    ];
    final currentIndex = stage.index;

    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            _WorkflowStep(
              label: steps[index].$2,
              complete: index < currentIndex,
              active: index == currentIndex,
            ),
            if (index != steps.length - 1)
              const Divider(height: SecuritySpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep({
    required this.label,
    required this.complete,
    required this.active,
  });

  final String label;
  final bool complete;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = complete || active
        ? SecurityColors.primary
        : SecurityColors.textMuted;
    return Row(
      children: [
        Icon(
          complete
              ? Icons.check_circle_rounded
              : active
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
          color: color,
          size: 20,
        ),
        const SizedBox(width: SecuritySpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({
    required this.attached,
    required this.fileName,
    required this.onAttach,
  });

  final bool attached;
  final String fileName;
  final VoidCallback onAttach;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.taskEvidenceTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: SecuritySpacing.xs),
          if (attached)
            Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  color: SecurityColors.success,
                ),
                const SizedBox(width: SecuritySpacing.xs),
                Expanded(child: Text(fileName)),
                const Icon(
                  Icons.check_circle_rounded,
                  color: SecurityColors.success,
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const Key('taskAttachEvidence'),
                onPressed: onAttach,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: Text(context.l10n.taskActionAttachEvidence),
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskCompletedView extends StatelessWidget {
  const _TaskCompletedView({required this.task, required this.onBackHome});

  final SecurityTaskPreview task;
  final VoidCallback onBackHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SecuritySpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: SecurityColors.success,
                size: 72,
              ),
              const SizedBox(height: SecuritySpacing.lg),
              Text(
                context.l10n.taskCompletedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                context.l10n.taskCompletedMessage(task.id),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: SecurityColors.textSecondary,
                    ),
              ),
              const SizedBox(height: SecuritySpacing.xl),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('taskBackHome'),
                  onPressed: onBackHome,
                  child: Text(context.l10n.taskBackToHome),
                ),
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
