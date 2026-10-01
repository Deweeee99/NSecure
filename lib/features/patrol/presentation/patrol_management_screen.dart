import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/theme/security_tokens.dart';
import '../domain/models/patrol_models.dart';
import '../domain/repositories/patrol_repository.dart';
import 'services/patrol_photo_picker.dart';

class PatrolManagementScreen extends StatefulWidget {
  const PatrolManagementScreen({
    required this.repository,
    required this.onBackHome,
    this.onReportIncident,
    this.onSessionExpired,
    this.photoPicker,
    this.photoPreviewBuilder,
    super.key,
  });

  final PatrolRepository repository;
  final VoidCallback onBackHome;
  final void Function(
    PatrolSession session,
    PatrolCheckpointVisit checkpoint,
  )? onReportIncident;
  final Future<void> Function()? onSessionExpired;
  final PatrolPhotoPicker? photoPicker;
  final Widget Function(BuildContext context, PatrolPhotoInput photo)?
      photoPreviewBuilder;

  @override
  State<PatrolManagementScreen> createState() => _PatrolManagementScreenState();
}

enum _PatrolView { dashboard, detail, history }

class _PatrolManagementScreenState extends State<PatrolManagementScreen> {
  _PatrolView _view = _PatrolView.dashboard;
  _PatrolView _detailReturnView = _PatrolView.dashboard;
  PatrolDashboard? _dashboard;
  List<PatrolSession> _sessions = const <PatrolSession>[];
  List<PatrolSession> _history = const <PatrolSession>[];
  PatrolSession? _selectedSession;
  int? _selectedSessionId;
  PatrolSessionStatus? _historyFilter;
  bool _loading = true;
  bool _mutating = false;
  String? _errorMessage;
  PatrolPhotoPicker? _ownedPhotoPicker;

  PatrolPhotoPicker get _photoPicker =>
      widget.photoPicker ?? (_ownedPhotoPicker ??= ImagePickerPatrolPhotoPicker());

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _PatrolView.dashboard => _buildDashboard(context),
      _PatrolView.detail => _buildDetail(context),
      _PatrolView.history => _buildHistory(context),
    };
  }

  Widget _buildDashboard(BuildContext context) {
    final dashboard = _dashboard;
    final nextPatrol = dashboard?.nextPatrol;
    return _PatrolScaffold(
      header: _PatrolHeader(
        title: context.l10n.patrolManagement,
        onBack: widget.onBackHome,
        trailing: IconButton(
          key: const Key('patrolHistoryButton'),
          tooltip: context.l10n.patrolHistory,
          onPressed: _loading ? null : _openHistory,
          icon: const Icon(Icons.history_rounded),
        ),
      ),
      child: _loading && dashboard == null
          ? _PatrolLoading(label: context.l10n.loadingAssignedPatrols)
          : _errorMessage != null && dashboard == null
              ? _PatrolErrorState(
                  message: _errorMessage!,
                  onRetry: _loadDashboard,
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      SecuritySpacing.md,
                      SecuritySpacing.xs,
                      SecuritySpacing.md,
                      SecuritySpacing.xl,
                    ),
                    children: [
                      Text(
                        context.l10n.patrolDashboard,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.patrolDashboardDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      if (_errorMessage != null)
                        _InlineMessage(
                          message: _errorMessage!,
                          icon: Icons.error_outline_rounded,
                        ),
                      if (_errorMessage != null)
                        const SizedBox(height: SecuritySpacing.sm),
                      if (dashboard != null) _DashboardMetrics(dashboard: dashboard),
                      const SizedBox(height: SecuritySpacing.md),
                      if (nextPatrol != null) ...[
                        Text(
                          nextPatrol.status == PatrolSessionStatus.inProgress
                              ? context.l10n.activePatrol
                              : context.l10n.nextPatrol,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                        _PatrolSessionCard(
                          key: const Key('patrolNextSessionCard'),
                          session: nextPatrol,
                          prominent: true,
                          onTap: () => _openSession(nextPatrol.patrolSessionId),
                        ),
                        const SizedBox(height: SecuritySpacing.lg),
                      ],
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.assignedPatrols,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_sessions.length} ${context.l10n.sessions}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: SecuritySpacing.sm),
                      if (_sessions.isEmpty)
                        _PatrolEmptyState(
                          icon: Icons.route_outlined,
                          title: context.l10n.noAssignedPatrols,
                          message: context.l10n.noAssignedPatrolsMessage,
                        )
                      else
                        ..._sessions.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: SecuritySpacing.sm,
                            ),
                            child: _PatrolSessionCard(
                              session: session,
                              onTap: () => _openSession(session.patrolSessionId),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final session = _selectedSession;
    final footer = session == null ? null : _buildDetailFooter(context, session);
    return _PatrolScaffold(
      header: _PatrolHeader(
        title: context.l10n.patrolRoute,
        onBack: _returnFromDetail,
      ),
      footer: footer,
      child: _loading && session == null
          ? _PatrolLoading(label: context.l10n.loadingPatrolRoute)
          : _errorMessage != null && session == null
              ? _PatrolErrorState(
                  message: _errorMessage!,
                  onRetry: _retrySelectedSession,
                )
              : session == null
                  ? _PatrolEmptyState(
                      icon: Icons.route_outlined,
                      title: context.l10n.patrolUnavailable,
                      message: context.l10n.patrolCouldNotLoad,
                    )
                  : RefreshIndicator(
                      onRefresh: _retrySelectedSession,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          SecuritySpacing.md,
                          SecuritySpacing.xs,
                          SecuritySpacing.md,
                          SecuritySpacing.xl,
                        ),
                        children: [
                        if (_errorMessage != null) ...[
                          _InlineMessage(
                            message: _errorMessage!,
                            icon: Icons.error_outline_rounded,
                          ),
                          const SizedBox(height: SecuritySpacing.sm),
                        ],
                        _PatrolDetailSummary(session: session),
                        const SizedBox(height: SecuritySpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                context.l10n.routeCheckpoints,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              '${session.checkpointSummary.terminal}/${session.checkpointSummary.total}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: SecurityColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                        if (session.checkpoints.isEmpty)
                          _PatrolEmptyState(
                            icon: Icons.flag_outlined,
                            title: context.l10n.noCheckpoints,
                            message: context.l10n.noCheckpointsMessage,
                          )
                        else
                          ...session.checkpoints.map(
                            (checkpoint) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: SecuritySpacing.sm,
                              ),
                              child: _PatrolCheckpointCard(
                                checkpoint: checkpoint,
                                mutating: _mutating,
                                onComplete: checkpoint.canComplete
                                    ? () => _completeCheckpoint(checkpoint)
                                    : null,
                                onSkip: checkpoint.canSkip
                                    ? () => _skipCheckpoint(checkpoint)
                                    : null,
                                onReportIncident:
                                    session.status == PatrolSessionStatus.inProgress &&
                                            checkpoint.status == PatrolCheckpointStatus.pending &&
                                            widget.onReportIncident != null
                                        ? () => widget.onReportIncident!(
                                              session,
                                              checkpoint,
                                            )
                                        : null,
                              ),
                            ),
                          ),
                        const SizedBox(height: SecuritySpacing.sm),
                        _InlineMessage(
                          message: context.l10n.patrolHardwareNotice,
                          icon: Icons.info_outline_rounded,
                        ),
                      ],
                    ),
                  ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final visibleHistory = _historyFilter == null
        ? _history
        : _history
            .where((session) => session.status == _historyFilter)
            .toList(growable: false);
    return _PatrolScaffold(
      header: _PatrolHeader(
        title: context.l10n.patrolHistory,
        onBack: _returnDashboard,
      ),
      child: _loading && _history.isEmpty
          ? _PatrolLoading(label: context.l10n.loadingPatrolHistory)
          : _errorMessage != null && _history.isEmpty
              ? _PatrolErrorState(
                  message: _errorMessage!,
                  onRetry: _loadHistory,
                )
              : RefreshIndicator(
                  onRefresh: _loadHistory,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(
                      SecuritySpacing.md,
                      SecuritySpacing.xs,
                      SecuritySpacing.md,
                      SecuritySpacing.xl,
                    ),
                    children: [
                      Text(
                        context.l10n.completedPatrolActivity,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.completedPatrolActivityDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      Wrap(
                        spacing: SecuritySpacing.xs,
                        children: [
                          _HistoryFilterChip(
                            label: context.l10n.all,
                            selected: _historyFilter == null,
                            onSelected: () => setState(() => _historyFilter = null),
                          ),
                          _HistoryFilterChip(
                            label: context.l10n.completed,
                            selected: _historyFilter == PatrolSessionStatus.completed,
                            onSelected: () => setState(
                              () => _historyFilter = PatrolSessionStatus.completed,
                            ),
                          ),
                          _HistoryFilterChip(
                            label: context.l10n.cancelled,
                            selected: _historyFilter == PatrolSessionStatus.cancelled,
                            onSelected: () => setState(
                              () => _historyFilter = PatrolSessionStatus.cancelled,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      if (_errorMessage != null) ...[
                        _InlineMessage(
                          message: _errorMessage!,
                          icon: Icons.error_outline_rounded,
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                      ],
                      if (visibleHistory.isEmpty)
                        _PatrolEmptyState(
                          icon: Icons.history_rounded,
                          title: context.l10n.noPatrolHistory,
                          message: context.l10n.noPatrolHistoryMessage,
                        )
                      else
                        ...visibleHistory.map(
                          (session) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: SecuritySpacing.sm,
                            ),
                            child: _PatrolSessionCard(
                              session: session,
                              onTap: () => _openSession(
                                session.patrolSessionId,
                                returnTo: _PatrolView.history,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget? _buildDetailFooter(BuildContext context, PatrolSession session) {
    if (session.status == PatrolSessionStatus.scheduled && session.canStart) {
      return _PatrolFooter(
        child: FilledButton.icon(
          key: const Key('startPatrolButton'),
          onPressed: _mutating ? null : () => _startPatrol(session),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(_mutating ? context.l10n.startingPatrol : context.l10n.startPatrol),
        ),
      );
    }

    if (session.status == PatrolSessionStatus.inProgress) {
      return _PatrolFooter(
        child: FilledButton.icon(
          key: const Key('completePatrolButton'),
          onPressed:
              !_mutating && session.canComplete ? () => _completePatrol(session) : null,
          icon: const Icon(Icons.flag_rounded),
          label: Text(
            session.canComplete
                ? (_mutating ? context.l10n.updatingPatrol : context.l10n.completePatrol)
                : '${context.l10n.completePendingCheckpointsPrefix} ${session.checkpointSummary.pending} ${context.l10n.completePendingCheckpointsSuffix}',
          ),
        ),
      );
    }

    return null;
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final values = await Future.wait<dynamic>([
        widget.repository.dashboard(),
        widget.repository.assignedSessions(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = values[0] as PatrolDashboard;
        _sessions = values[1] as List<PatrolSession>;
        _loading = false;
      });
    } on PatrolRepositoryException catch (error) {
      await _handleFailure(error, () {
        _loading = false;
        _errorMessage = _patrolFailureMessage(context, error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = context.l10n.patrolDataLoadFailed;
      });
    }
  }

  Future<void> _openSession(
    int patrolSessionId, {
    _PatrolView returnTo = _PatrolView.dashboard,
  }) async {
    setState(() {
      _view = _PatrolView.detail;
      _detailReturnView = returnTo;
      _selectedSession = null;
      _selectedSessionId = patrolSessionId;
      _loading = true;
      _errorMessage = null;
    });
    await _loadSelectedSession(patrolSessionId);
  }

  Future<void> _loadSelectedSession(int patrolSessionId) async {
    try {
      final session = await widget.repository.findById(patrolSessionId);
      if (!mounted) return;
      setState(() {
        _selectedSession = session;
        _loading = false;
        if (session == null) _errorMessage = context.l10n.patrolNotFound;
      });
    } on PatrolRepositoryException catch (error) {
      await _handleFailure(error, () {
        _loading = false;
        _errorMessage = _patrolFailureMessage(context, error);
      });
    }
  }

  Future<void> _retrySelectedSession() async {
    final id = _selectedSessionId;
    if (id == null) {
      _returnDashboard();
      return;
    }
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    await _loadSelectedSession(id);
  }

  Future<void> _openHistory() async {
    setState(() {
      _view = _PatrolView.history;
      _loading = true;
      _errorMessage = null;
    });
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await widget.repository.history();
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
        _errorMessage = null;
      });
    } on PatrolRepositoryException catch (error) {
      await _handleFailure(error, () {
        _loading = false;
        _errorMessage = _patrolFailureMessage(context, error);
      });
    }
  }

  void _returnFromDetail() {
    if (_detailReturnView == _PatrolView.history) {
      setState(() {
        _view = _PatrolView.history;
        _selectedSession = null;
        _selectedSessionId = null;
        _errorMessage = null;
        _loading = false;
      });
      return;
    }
    _returnDashboard();
  }

  void _returnDashboard() {
    setState(() {
      _view = _PatrolView.dashboard;
      _detailReturnView = _PatrolView.dashboard;
      _selectedSession = null;
      _selectedSessionId = null;
      _errorMessage = null;
      _loading = false;
    });
    _loadDashboard();
  }

  Future<void> _startPatrol(PatrolSession session) async {
    await _runMutation(
      () => widget.repository.startPatrol(session.patrolSessionId),
      successMessage: context.l10n.patrolStarted,
    );
  }

  Future<void> _completeCheckpoint(PatrolCheckpointVisit checkpoint) async {
    final photo = await _chooseCheckpointPhoto();
    if (photo == null || !mounted) return;

    final submission = await showDialog<_CheckpointEvidenceSubmission>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CheckpointEvidenceDialog(
        title: context.l10n.markComplete,
        photoPicker: _photoPicker,
        initialPhoto: photo,
        photoPreviewBuilder: widget.photoPreviewBuilder,
        photoRequired: true,
        notesRequired: false,
        submitLabel: context.l10n.markComplete,
      ),
    );
    if (submission == null || submission.photo == null || !mounted) return;

    final session = _selectedSession;
    if (session == null) return;
    await _runMutation(
      () => widget.repository.completeCheckpoint(
        session.patrolSessionId,
        checkpoint.visitId,
        photo: submission.photo!,
        notes: submission.notes,
      ),
      successMessage: '${checkpoint.name} ${context.l10n.checkpointCompleted}',
      networkFailureMessage: context.l10n.checkpointMutationNetworkHint,
    );
  }

  Future<void> _skipCheckpoint(PatrolCheckpointVisit checkpoint) async {
    final submission = await showDialog<_CheckpointEvidenceSubmission>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CheckpointEvidenceDialog(
        title: context.l10n.skipCheckpoint,
        photoPicker: _photoPicker,
        photoPreviewBuilder: widget.photoPreviewBuilder,
        photoRequired: false,
        notesRequired: true,
        submitLabel: context.l10n.skipCheckpoint,
      ),
    );
    if (submission == null || !mounted) return;
    final reason = submission.notes?.trim() ?? '';
    if (reason.isEmpty) return;

    final session = _selectedSession;
    if (session == null) return;
    await _runMutation(
      () => widget.repository.skipCheckpoint(
        session.patrolSessionId,
        checkpoint.visitId,
        reason: reason,
        photo: submission.photo,
      ),
      successMessage: '${checkpoint.name} ${context.l10n.checkpointSkipped}',
      networkFailureMessage: context.l10n.checkpointMutationNetworkHint,
    );
  }

  Future<PatrolPhotoInput?> _chooseCheckpointPhoto() async {
    final source = await showModalBottomSheet<PatrolPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              key: const Key('patrolPhotoSourceCamera'),
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.takeCheckpointPhoto),
              onTap: () => Navigator.of(sheetContext).pop(
                PatrolPhotoSource.camera,
              ),
            ),
            ListTile(
              key: const Key('patrolPhotoSourceGallery'),
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.chooseCheckpointPhoto),
              onTap: () => Navigator.of(sheetContext).pop(
                PatrolPhotoSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return null;

    try {
      return await _photoPicker.pick(source);
    } on PatrolPhotoSelectionException catch (error) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_photoSelectionFailureMessage(context, error))),
      );
      return null;
    }
  }

  Future<void> _completePatrol(PatrolSession session) async {
    final notes = await _showNotesDialog(
      title: context.l10n.completePatrol,
      label: context.l10n.completionNotesOptional,
      required: false,
      actionLabel: context.l10n.completePatrol,
    );
    if (!mounted || notes == null) return;
    await _runMutation(
      () => widget.repository.completePatrol(
        session.patrolSessionId,
        notes: notes.isEmpty ? null : notes,
      ),
      successMessage: context.l10n.patrolCompleted,
    );
  }

  Future<void> _runMutation(
    Future<PatrolSession> Function() action, {
    required String successMessage,
    String? networkFailureMessage,
  }) async {
    setState(() {
      _mutating = true;
      _errorMessage = null;
    });
    try {
      final updated = await action();
      if (!mounted) return;
      setState(() {
        _selectedSession = updated;
        _mutating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } on PatrolRepositoryException catch (error) {
      await _handleFailure(error, () {
        _mutating = false;
        _errorMessage = error.code == PatrolRepositoryFailureCode.network &&
                networkFailureMessage != null
            ? networkFailureMessage
            : _patrolFailureMessage(context, error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _errorMessage = context.l10n.patrolActionFailed;
      });
    }
  }

  Future<String?> _showNotesDialog({
    required String title,
    required String label,
    required bool required,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    String? validationMessage;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            key: Key(required ? 'patrolRequiredNotesInput' : 'patrolOptionalNotesInput'),
            controller: controller,
            minLines: 2,
            maxLines: 5,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: label,
              errorText: validationMessage,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (required && value.isEmpty) {
                  setDialogState(() {
                    validationMessage = context.l10n.reasonRequired;
                  });
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _handleFailure(
    PatrolRepositoryException error,
    VoidCallback applyLocalState,
  ) async {
    if (error.code == PatrolRepositoryFailureCode.unauthorized) {
      final callback = widget.onSessionExpired;
      if (callback != null) {
        await callback();
        return;
      }
    }
    if (!mounted) return;
    setState(applyLocalState);
  }
}

class _PatrolScaffold extends StatelessWidget {
  const _PatrolScaffold({
    required this.header,
    required this.child,
    this.footer,
  });

  final Widget header;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final footer = this.footer;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SecuritySpacing.xs),
            child: header,
          ),
          Expanded(child: child),
          ?footer,
        ],
      ),
    );
  }
}

class _PatrolHeader extends StatelessWidget {
  const _PatrolHeader({
    required this.title,
    required this.onBack,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          IconButton(
            tooltip: context.l10n.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          SizedBox(width: 48, child: trailing),
        ],
      ),
    );
  }
}

class _DashboardMetrics extends StatelessWidget {
  const _DashboardMetrics({required this.dashboard});

  final PatrolDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            value: dashboard.scheduled,
            label: context.l10n.scheduled,
            foreground: SecurityColors.primary,
          ),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: _MetricCard(
            value: dashboard.inProgress,
            label: context.l10n.inProgress,
            foreground: SecurityColors.warning,
          ),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: _MetricCard(
            value: dashboard.completedToday,
            label: context.l10n.doneToday,
            foreground: SecurityColors.success,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.foreground,
  });

  final int value;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SecuritySpacing.xs,
        vertical: SecuritySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
        boxShadow: SecurityShadows.soft,
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: foreground,
                ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _PatrolSessionCard extends StatelessWidget {
  const _PatrolSessionCard({
    required this.session,
    required this.onTap,
    this.prominent = false,
    super.key,
  });

  final PatrolSession session;
  final VoidCallback onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final progress = session.checkpointSummary.progress;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(SecuritySpacing.md),
          decoration: BoxDecoration(
            color: prominent ? SecurityColors.primarySoft : SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(
              color: prominent ? SecurityColors.primary.withAlpha(70) : SecurityColors.border,
            ),
            boxShadow: SecurityShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: prominent ? SecurityColors.primary : SecurityColors.primarySoft,
                      borderRadius: BorderRadius.circular(SecurityRadius.md),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: prominent ? Colors.white : SecurityColors.primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: SecuritySpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.route.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: SecurityColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          session.sessionNumber,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _PatrolStatusPill(status: session.status),
                ],
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.apartment_outlined,
                    size: 15,
                    color: SecurityColors.textMuted,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      session.property.name,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  Text(
                    _formatPatrolDateTime(context, session.scheduledStartAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: SecuritySpacing.sm),
              Row(
                children: [
                  Text(
                    '${session.checkpointSummary.terminal}/${session.checkpointSummary.total} ${context.l10n.checkpoints}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${(progress * 100).round()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SecurityColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: const BorderRadius.all(Radius.circular(99)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatrolDetailSummary extends StatelessWidget {
  const _PatrolDetailSummary({required this.session});

  final PatrolSession session;

  @override
  Widget build(BuildContext context) {
    final progress = session.checkpointSummary.progress;
    final startedAt = session.startedAt;
    final completedAt = session.completedAt;
    final sessionNotes = session.notes;
    return Container(
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
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: SecurityColors.primarySoft,
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                ),
                child: const Icon(
                  Icons.route_outlined,
                  color: SecurityColors.primary,
                ),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.route.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.sessionNumber,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _PatrolStatusPill(status: session.status),
            ],
          ),
          const SizedBox(height: SecuritySpacing.md),
          _InfoRow(label: context.l10n.property, value: session.property.name),
          _InfoRow(label: context.l10n.officer, value: session.officer.name),
          _InfoRow(
            label: context.l10n.scheduled,
            value: _formatPatrolDateTime(context, session.scheduledStartAt),
          ),
          _InfoRow(
            label: context.l10n.duration,
            value: '${session.route.expectedDurationMinutes} ${context.l10n.minutesShort}',
          ),
          if (startedAt != null)
            _InfoRow(
              label: context.l10n.started,
              value: _formatPatrolDateTime(context, startedAt),
            ),
          if (completedAt != null)
            _InfoRow(
              label: context.l10n.completed,
              value: _formatPatrolDateTime(context, completedAt),
            ),
          if (sessionNotes != null)
            _InfoRow(label: context.l10n.notes, value: sessionNotes),
          const SizedBox(height: SecuritySpacing.sm),
          Row(
            children: [
              Text(
                context.l10n.progress,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: SecurityColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: const BorderRadius.all(Radius.circular(99)),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          Row(
            children: [
              Expanded(
                child: _CheckpointMetric(
                  value: session.checkpointSummary.completed,
                  label: context.l10n.completed,
                  foreground: SecurityColors.success,
                ),
              ),
              Expanded(
                child: _CheckpointMetric(
                  value: session.checkpointSummary.pending,
                  label: context.l10n.pending,
                  foreground: SecurityColors.warning,
                ),
              ),
              Expanded(
                child: _CheckpointMetric(
                  value: session.checkpointSummary.skipped,
                  label: context.l10n.skipped,
                  foreground: SecurityColors.textSecondary,
                ),
              ),
              Expanded(
                child: _CheckpointMetric(
                  value: session.checkpointSummary.issue,
                  label: context.l10n.issue,
                  foreground: SecurityColors.danger,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckpointMetric extends StatelessWidget {
  const _CheckpointMetric({
    required this.value,
    required this.label,
    required this.foreground,
  });

  final int value;
  final String label;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 9),
        ),
      ],
    );
  }
}

class _CheckpointEvidenceSubmission {
  const _CheckpointEvidenceSubmission({required this.notes, required this.photo});

  final String? notes;
  final PatrolPhotoInput? photo;
}

class _CheckpointEvidenceDialog extends StatefulWidget {
  const _CheckpointEvidenceDialog({
    required this.title,
    required this.photoPicker,
    required this.photoRequired,
    required this.notesRequired,
    required this.submitLabel,
    this.initialPhoto,
    this.photoPreviewBuilder,
  });

  final String title;
  final PatrolPhotoPicker photoPicker;
  final bool photoRequired;
  final bool notesRequired;
  final String submitLabel;
  final PatrolPhotoInput? initialPhoto;
  final Widget Function(BuildContext context, PatrolPhotoInput photo)?
      photoPreviewBuilder;

  @override
  State<_CheckpointEvidenceDialog> createState() =>
      _CheckpointEvidenceDialogState();
}

class _CheckpointEvidenceDialogState extends State<_CheckpointEvidenceDialog> {
  final TextEditingController _notesController = TextEditingController();
  PatrolPhotoInput? _photo;
  bool _picking = false;
  String? _photoError;
  String? _notesError;

  @override
  void initState() {
    super.initState();
    _photo = widget.initialPhoto;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photo = _photo;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.photoRequired
                    ? context.l10n.checkpointPhotoRequired
                    : context.l10n.checkpointPhotoOptional,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              if (photo == null)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    key: const Key('checkpointEvidenceAddPhoto'),
                    onPressed: _picking ? null : _chooseSource,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(context.l10n.addCheckpointPhoto),
                  ),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: KeyedSubtree(
                      key: const Key('checkpointEvidencePreview'),
                      child: widget.photoPreviewBuilder?.call(context, photo) ??
                          Image.file(
                            File(photo.path),
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: SecurityColors.surfaceMuted,
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  SecuritySpacing.md,
                                ),
                                child: Text(
                                  context.l10n.checkpointPhotoUnavailable,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: SecuritySpacing.xs),
                Text(
                  '${photo.originalName} • ${_formatPhotoSize(photo.fileSize)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: SecuritySpacing.xs),
                Wrap(
                  spacing: SecuritySpacing.xs,
                  runSpacing: SecuritySpacing.xs,
                  children: [
                    TextButton.icon(
                      key: const Key('checkpointEvidenceRemovePhoto'),
                      onPressed: _picking
                          ? null
                          : () => setState(() {
                                _photo = null;
                                _photoError = null;
                              }),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: Text(context.l10n.removeCheckpointPhoto),
                    ),
                    TextButton.icon(
                      key: const Key('checkpointEvidenceRetakePhoto'),
                      onPressed: _picking
                          ? null
                          : () => _pick(PatrolPhotoSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(context.l10n.retakeCheckpointPhoto),
                    ),
                    TextButton.icon(
                      key: const Key('checkpointEvidenceChangePhoto'),
                      onPressed: _picking ? null : _chooseSource,
                      icon: const Icon(Icons.swap_horiz_rounded),
                      label: Text(context.l10n.changeCheckpointPhoto),
                    ),
                  ],
                ),
              ],
              if (_picking) ...[
                const SizedBox(height: SecuritySpacing.xs),
                const LinearProgressIndicator(),
              ],
              if (_photoError != null) ...[
                const SizedBox(height: SecuritySpacing.xs),
                Text(
                  _photoError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SecurityColors.danger,
                      ),
                ),
              ],
              const SizedBox(height: SecuritySpacing.sm),
              TextField(
                key: const Key('checkpointEvidenceNotesField'),
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  labelText: widget.notesRequired
                      ? context.l10n.checkpointSkipReason
                      : context.l10n.checkpointNotesOptional,
                  errorText: _notesError,
                ),
                onChanged: (_) {
                  if (_notesError != null) setState(() => _notesError = null);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _picking ? null : () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          key: const Key('checkpointEvidenceSubmit'),
          onPressed: _picking ? null : _submit,
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<PatrolPhotoSource>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.takeCheckpointPhoto),
              onTap: () => Navigator.of(sheetContext).pop(
                PatrolPhotoSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.chooseCheckpointPhoto),
              onTap: () => Navigator.of(sheetContext).pop(
                PatrolPhotoSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _pick(source);
  }

  Future<void> _pick(PatrolPhotoSource source) async {
    setState(() {
      _picking = true;
      _photoError = null;
    });
    try {
      final selected = await widget.photoPicker.pick(source);
      if (!mounted) return;
      setState(() {
        if (selected != null) _photo = selected;
        _picking = false;
      });
    } on PatrolPhotoSelectionException catch (error) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _photoError = _photoSelectionFailureMessage(context, error);
      });
    }
  }

  void _submit() {
    final notes = _notesController.text.trim();
    var invalid = false;
    if (widget.photoRequired && _photo == null) {
      _photoError = context.l10n.checkpointPhotoRequired;
      invalid = true;
    }
    if (widget.notesRequired && notes.isEmpty) {
      _notesError = context.l10n.reasonRequired;
      invalid = true;
    }
    if (invalid) {
      setState(() {});
      return;
    }

    Navigator.of(context).pop(
      _CheckpointEvidenceSubmission(
        notes: notes.isEmpty ? null : notes,
        photo: _photo,
      ),
    );
  }
}

class _CheckpointPhotoEvidenceCard extends StatelessWidget {
  const _CheckpointPhotoEvidenceCard({
    required this.visitId,
    required this.evidence,
  });

  final int visitId;
  final PatrolCheckpointPhotoEvidence evidence;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(evidence.url);
    final isRemote = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    return Container(
      key: Key('checkpointPhotoEvidence-$visitId'),
      padding: const EdgeInsets.all(SecuritySpacing.xs),
      decoration: BoxDecoration(
        color: SecurityColors.surfaceMuted,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, size: 18),
              const SizedBox(width: SecuritySpacing.xs),
              Expanded(
                child: Text(
                  context.l10n.checkpointPhotoEvidence,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: SecuritySpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(SecurityRadius.sm),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: isRemote
                  ? Image.network(
                      evidence.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _PhotoEvidenceUnavailable(),
                    )
                  : Container(
                      color: SecurityColors.surface,
                      alignment: Alignment.center,
                      child: const Icon(Icons.photo_outlined, size: 42),
                    ),
            ),
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            '${evidence.originalName} • ${_formatPhotoSize(evidence.fileSize)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: SecurityColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '${context.l10n.checkpointPhotoUploadedAt}: ${_formatPatrolDateTime(context, evidence.uploadedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            context.l10n.checkpointPhotoSignedUrlHint,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PhotoEvidenceUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: SecurityColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined),
          const SizedBox(height: 4),
          Text(
            context.l10n.checkpointPhotoRefreshHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PatrolCheckpointCard extends StatelessWidget {
  const _PatrolCheckpointCard({
    required this.checkpoint,
    required this.mutating,
    this.onComplete,
    this.onSkip,
    this.onReportIncident,
  });

  final PatrolCheckpointVisit checkpoint;
  final bool mutating;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final VoidCallback? onReportIncident;

  @override
  Widget build(BuildContext context) {
    final colors = _checkpointColors(checkpoint.status);
    final checkedAt = checkpoint.checkedAt;
    final checkedBy = checkpoint.checkedBy;
    final notes = checkpoint.notes;
    final photoEvidence = checkpoint.photoEvidence;
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
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
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.$2,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${checkpoint.sequence}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colors.$1,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      checkpoint.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SecurityColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [checkpoint.code, checkpoint.locationLabel]
                          .whereType<String>()
                          .join(' • '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _CheckpointStatusPill(status: checkpoint.status),
            ],
          ),
          if (checkedAt != null || checkedBy != null) ...[
            const SizedBox(height: SecuritySpacing.sm),
            const Divider(height: 1),
            const SizedBox(height: SecuritySpacing.xs),
            if (checkedAt != null)
              _InfoRow(
                label: context.l10n.checkedAt,
                value: _formatPatrolDateTime(context, checkedAt),
              ),
            if (checkedBy != null)
              _InfoRow(label: context.l10n.officer, value: checkedBy.name),
          ],
          if (notes != null) ...[
            const SizedBox(height: SecuritySpacing.xs),
            Text(
              notes,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textSecondary,
                  ),
            ),
          ],
          if (photoEvidence != null) ...[
            const SizedBox(height: SecuritySpacing.sm),
            _CheckpointPhotoEvidenceCard(
              visitId: checkpoint.visitId,
              evidence: photoEvidence,
            ),
          ],
          if (onReportIncident != null) ...[
            const SizedBox(height: SecuritySpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: Key('reportCheckpointIssueButton-${checkpoint.visitId}'),
                onPressed: mutating ? null : onReportIncident,
                icon: const Icon(Icons.report_problem_outlined),
                label: Text(context.l10n.reportCheckpointIssue),
              ),
            ),
          ],
          if (onComplete != null || onSkip != null) ...[
            const SizedBox(height: SecuritySpacing.xs),
            Row(
              children: [
                if (onSkip != null)
                  Expanded(
                    child: OutlinedButton(
                      key: Key('skipCheckpointButton-${checkpoint.visitId}'),
                      onPressed: mutating ? null : onSkip,
                      child: Text(context.l10n.skip),
                    ),
                  ),
                if (onSkip != null && onComplete != null)
                  const SizedBox(width: SecuritySpacing.xs),
                if (onComplete != null)
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      key: Key('completeCheckpointButton-${checkpoint.visitId}'),
                      onPressed: mutating ? null : onComplete,
                      child: Text(context.l10n.markComplete),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatrolStatusPill extends StatelessWidget {
  const _PatrolStatusPill({required this.status});

  final PatrolSessionStatus status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      PatrolSessionStatus.scheduled => (
          context.l10n.scheduledStatus,
          SecurityColors.info,
          SecurityColors.infoSoft,
        ),
      PatrolSessionStatus.inProgress => (
          context.l10n.inProgressStatus,
          SecurityColors.warning,
          SecurityColors.warningSoft,
        ),
      PatrolSessionStatus.completed => (
          context.l10n.completedStatus,
          SecurityColors.success,
          SecurityColors.successSoft,
        ),
      PatrolSessionStatus.cancelled => (
          context.l10n.cancelledUpperStatus,
          SecurityColors.textSecondary,
          SecurityColors.surfaceMuted,
        ),
    };
    return _StatusPill(label: config.$1, foreground: config.$2, background: config.$3);
  }
}

class _CheckpointStatusPill extends StatelessWidget {
  const _CheckpointStatusPill({required this.status});

  final PatrolCheckpointStatus status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      PatrolCheckpointStatus.pending => (
          context.l10n.pendingUpperStatus,
          SecurityColors.warning,
          SecurityColors.warningSoft,
        ),
      PatrolCheckpointStatus.completed => (
          context.l10n.completedStatus,
          SecurityColors.success,
          SecurityColors.successSoft,
        ),
      PatrolCheckpointStatus.skipped => (
          context.l10n.skippedUpperStatus,
          SecurityColors.textSecondary,
          SecurityColors.surfaceMuted,
        ),
      PatrolCheckpointStatus.issue => (
          context.l10n.issueUpperStatus,
          SecurityColors.danger,
          SecurityColors.dangerSoft,
        ),
    };
    return _StatusPill(label: config.$1, foreground: config.$2, background: config.$3);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _PatrolFooter extends StatelessWidget {
  const _PatrolFooter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        SecuritySpacing.md,
        SecuritySpacing.xs,
        SecuritySpacing.md,
        SecuritySpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: SecurityColors.surface,
        border: Border(top: BorderSide(color: SecurityColors.border)),
      ),
      child: child,
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  const _HistoryFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _PatrolLoading extends StatelessWidget {
  const _PatrolLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: SecuritySpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _PatrolErrorState extends StatelessWidget {
  const _PatrolErrorState({required this.message, required this.onRetry});

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
              Icons.cloud_off_rounded,
              size: 44,
              color: SecurityColors.textMuted,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            Text(
              context.l10n.patrolUnavailable,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SecuritySpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: SecuritySpacing.md),
            FilledButton.icon(
              key: const Key('patrolRetryButton'),
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

class _PatrolEmptyState extends StatelessWidget {
  const _PatrolEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.xl),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: SecurityColors.textMuted),
          const SizedBox(height: SecuritySpacing.sm),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message, required this.icon});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.primarySoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.primary.withAlpha(40)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: SecurityColors.primary),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
(Color, Color) _checkpointColors(PatrolCheckpointStatus status) {
  return switch (status) {
    PatrolCheckpointStatus.pending => (
        SecurityColors.warning,
        SecurityColors.warningSoft,
      ),
    PatrolCheckpointStatus.completed => (
        SecurityColors.success,
        SecurityColors.successSoft,
      ),
    PatrolCheckpointStatus.skipped => (
        SecurityColors.textSecondary,
        SecurityColors.surfaceMuted,
      ),
    PatrolCheckpointStatus.issue => (
        SecurityColors.danger,
        SecurityColors.dangerSoft,
      ),
  };
}


String _photoSelectionFailureMessage(
  BuildContext context,
  PatrolPhotoSelectionException error,
) {
  return switch (error.code) {
    PatrolPhotoSelectionFailureCode.unsupportedType =>
      context.l10n.checkpointPhotoUnsupportedType,
    PatrolPhotoSelectionFailureCode.tooLarge =>
      context.l10n.checkpointPhotoTooLarge,
    PatrolPhotoSelectionFailureCode.unavailable =>
      context.l10n.checkpointPhotoUnavailable,
  };
}

String _formatPhotoSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) return '${kb.toStringAsFixed(kb >= 100 ? 0 : 1)} KB';
  final mb = kb / 1024;
  return '${mb.toStringAsFixed(mb >= 10 ? 1 : 2)} MB';
}

String _patrolFailureMessage(
  BuildContext context,
  PatrolRepositoryException error,
) {
  final l10n = context.l10n;
  final backendMessage = error.message?.trim();
  return switch (error.code) {
    PatrolRepositoryFailureCode.patrolNotFound => l10n.patrolFailureNotFound,
    PatrolRepositoryFailureCode.checkpointNotFound =>
      l10n.patrolFailureCheckpointNotFound,
    PatrolRepositoryFailureCode.alreadyStarted =>
      l10n.patrolFailureAlreadyStarted,
    PatrolRepositoryFailureCode.alreadyCompleted =>
      l10n.patrolFailureAlreadyCompleted,
    PatrolRepositoryFailureCode.cancelled => l10n.patrolFailureCancelled,
    PatrolRepositoryFailureCode.invalidState =>
      backendMessage ?? l10n.patrolFailureInvalidState,
    PatrolRepositoryFailureCode.notInProgress =>
      l10n.patrolFailureNotInProgress,
    PatrolRepositoryFailureCode.checkpointInvalidState =>
      l10n.patrolFailureCheckpointInvalidState,
    PatrolRepositoryFailureCode.checkpointAlreadyProcessed =>
      l10n.patrolFailureCheckpointAlreadyProcessed,
    PatrolRepositoryFailureCode.checkpointsPending => error.pendingCount == null
        ? l10n.patrolFailureCheckpointsPending
        : '${error.pendingCount} ${l10n.patrolFailureCheckpointsStillPendingSuffix}',
    PatrolRepositoryFailureCode.validation =>
      backendMessage ?? l10n.patrolFailureValidation,
    PatrolRepositoryFailureCode.unauthorized =>
      l10n.patrolFailureUnauthorized,
    PatrolRepositoryFailureCode.forbidden => l10n.patrolFailureForbidden,
    PatrolRepositoryFailureCode.network => l10n.patrolFailureNetwork,
    PatrolRepositoryFailureCode.unknown =>
      backendMessage ?? l10n.patrolFailureUnknown,
  };
}

String _formatPatrolDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date • $time';
}

