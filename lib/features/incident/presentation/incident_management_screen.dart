import 'package:flutter/material.dart';

import '../../security/domain/models/security_user.dart';
import '../../../core/localization/app_localizations_x.dart';
import '../../../core/theme/security_tokens.dart';
import '../domain/models/incident_models.dart';
import '../domain/repositories/incident_repository.dart';

enum _IncidentView { dashboard, detail, history, create }

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({
    required this.repository,
    required this.onBackHome,
    this.securityUser,
    this.initialCreateContext,
    this.onSessionExpired,
    super.key,
  });

  final IncidentRepository repository;
  final VoidCallback onBackHome;
  final SecurityUser? securityUser;
  final IncidentCreateContext? initialCreateContext;
  final Future<void> Function()? onSessionExpired;

  @override
  State<IncidentManagementScreen> createState() =>
      _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  _IncidentView _view = _IncidentView.dashboard;
  IncidentDashboard? _dashboard;
  List<IncidentRecord> _incidents = const <IncidentRecord>[];
  List<IncidentRecord> _history = const <IncidentRecord>[];
  IncidentRecord? _selectedIncident;
  int? _selectedIncidentId;
  IncidentStatus? _historyFilter;
  IncidentSeverity _createSeverity = IncidentSeverity.medium;
  IncidentCreateContext? _createContext;
  int? _selectedPropertyId;
  bool _loading = true;
  bool _mutating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createContext = widget.initialCreateContext;
    _selectedPropertyId =
        _createContext?.propertyId ?? widget.securityUser?.defaultPropertyId;
    final initialLocation = _createContext?.location;
    if (initialLocation != null && initialLocation.trim().isNotEmpty) {
      _locationController.text = initialLocation;
    }
    if (_createContext != null) {
      _view = _IncidentView.create;
    }
    _loadDashboard();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _IncidentView.dashboard => _buildDashboard(context),
      _IncidentView.detail => _buildDetail(context),
      _IncidentView.history => _buildHistory(context),
      _IncidentView.create => _buildCreate(context),
    };
  }

  Widget _buildDashboard(BuildContext context) {
    final dashboard = _dashboard;
    return _IncidentScaffold(
      header: _IncidentHeader(
        title: context.l10n.incidentReporting,
        onBack: widget.onBackHome,
        trailing: IconButton(
          key: const Key('incidentHistoryButton'),
          tooltip: context.l10n.incidentHistory,
          onPressed: _loading ? null : _openHistory,
          icon: const Icon(Icons.history_rounded),
        ),
      ),
      child: _loading && dashboard == null
          ? _IncidentLoading(label: context.l10n.loadingIncidents)
          : _errorMessage != null && dashboard == null
              ? _IncidentErrorState(
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
                        context.l10n.incidentDashboard,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.incidentDashboardDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      _IncidentNotice(
                        message: context.l10n.incidentOperationalNotice,
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      if (_errorMessage != null) ...[
                        _IncidentNotice(
                          message: _errorMessage!,
                          danger: true,
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                      ],
                      if (dashboard != null)
                        _DashboardMetrics(dashboard: dashboard),
                      const SizedBox(height: SecuritySpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          key: const Key('reportIncidentButton'),
                          onPressed: _openCreate,
                          icon: const Icon(Icons.add_rounded),
                          label: Text(context.l10n.reportIncident),
                        ),
                      ),
                      const SizedBox(height: SecuritySpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              context.l10n.activeIncidents,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          Text(
                            '${_incidents.length}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: SecuritySpacing.sm),
                      if (_incidents.isEmpty)
                        _IncidentEmptyState(
                          icon: Icons.assignment_turned_in_outlined,
                          title: context.l10n.noActiveIncidents,
                          message: context.l10n.noActiveIncidentsMessage,
                        )
                      else
                        ..._incidents.map(
                          (incident) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: SecuritySpacing.sm,
                            ),
                            child: _IncidentCard(
                              incident: incident,
                              onTap: () => _openIncident(incident.incidentId),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final incident = _selectedIncident;
    final footer = incident == null ? null : _buildDetailFooter(context, incident);
    return _IncidentScaffold(
      header: _IncidentHeader(
        title: context.l10n.incidentDetail,
        onBack: _returnDashboard,
      ),
      footer: footer,
      child: _loading && incident == null
          ? _IncidentLoading(label: context.l10n.loadingIncidents)
          : _errorMessage != null && incident == null
              ? _IncidentErrorState(
                  message: _errorMessage!,
                  onRetry: _retrySelectedIncident,
                )
              : incident == null
                  ? _IncidentEmptyState(
                      icon: Icons.assignment_late_outlined,
                      title: context.l10n.incidentUnavailable,
                      message: context.l10n.incidentCouldNotLoad,
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(
                        SecuritySpacing.md,
                        SecuritySpacing.xs,
                        SecuritySpacing.md,
                        SecuritySpacing.xl,
                      ),
                      children: [
                        if (_errorMessage != null) ...[
                          _IncidentNotice(
                            message: _errorMessage!,
                            danger: true,
                          ),
                          const SizedBox(height: SecuritySpacing.sm),
                        ],
                        _IncidentDetailSummary(incident: incident),
                        const SizedBox(height: SecuritySpacing.md),
                        _IncidentInfoCard(incident: incident),
                        if (incident.patrolContext != null) ...[
                          const SizedBox(height: SecuritySpacing.md),
                          _PatrolContextCard(context: incident.patrolContext!),
                        ],
                        const SizedBox(height: SecuritySpacing.md),
                        Text(
                          context.l10n.incidentTimeline,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: SecuritySpacing.sm),
                        if (incident.timeline.isEmpty)
                          _IncidentEmptyState(
                            icon: Icons.timeline_rounded,
                            title: context.l10n.noTimeline,
                            message: context.l10n.noTimelineMessage,
                          )
                        else
                          ...incident.timeline.map(
                            (event) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: SecuritySpacing.sm,
                              ),
                              child: _TimelineCard(event: event),
                            ),
                          ),
                        const SizedBox(height: SecuritySpacing.sm),
                        _IncidentNotice(
                          message: context.l10n.incidentNoMediaNotice,
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHistory(BuildContext context) {
    final visible = _historyFilter == null
        ? _history
        : _history
            .where((incident) => incident.status == _historyFilter)
            .toList(growable: false);
    return _IncidentScaffold(
      header: _IncidentHeader(
        title: context.l10n.incidentHistory,
        onBack: _returnDashboard,
      ),
      child: _loading && _history.isEmpty
          ? _IncidentLoading(label: context.l10n.loadingIncidents)
          : _errorMessage != null && _history.isEmpty
              ? _IncidentErrorState(
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
                        context.l10n.terminalIncidentActivity,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.terminalIncidentActivityDescription,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      Wrap(
                        spacing: SecuritySpacing.xs,
                        runSpacing: SecuritySpacing.xs,
                        children: [
                          ChoiceChip(
                            label: Text(context.l10n.all),
                            selected: _historyFilter == null,
                            onSelected: (_) => setState(() => _historyFilter = null),
                          ),
                          ...<IncidentStatus>[
                            IncidentStatus.resolved,
                            IncidentStatus.closed,
                            IncidentStatus.cancelled,
                          ].map(
                            (status) => ChoiceChip(
                              label: Text(_statusLabel(context, status)),
                              selected: _historyFilter == status,
                              onSelected: (_) =>
                                  setState(() => _historyFilter = status),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: SecuritySpacing.md),
                      if (_errorMessage != null) ...[
                        _IncidentNotice(message: _errorMessage!, danger: true),
                        const SizedBox(height: SecuritySpacing.sm),
                      ],
                      if (visible.isEmpty)
                        _IncidentEmptyState(
                          icon: Icons.history_rounded,
                          title: context.l10n.noIncidentHistory,
                          message: context.l10n.noIncidentHistoryMessage,
                        )
                      else
                        ...visible.map(
                          (incident) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: SecuritySpacing.sm,
                            ),
                            child: _IncidentCard(
                              incident: incident,
                              onTap: () => _openIncident(
                                incident.incidentId,
                                returnToHistory: true,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCreate(BuildContext context) {
    final properties = widget.securityUser?.properties ?? const <SecurityProperty>[];
    final createContext = _createContext;
    final showPropertyPicker = createContext == null && properties.length > 1;
    return _IncidentScaffold(
      header: _IncidentHeader(
        title: context.l10n.createIncident,
        onBack: createContext == null ? _returnDashboard : widget.onBackHome,
      ),
      footer: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.md,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('submitIncidentButton'),
              onPressed: _mutating ? null : _submitIncident,
              icon: _mutating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _mutating
                    ? context.l10n.submittingIncident
                    : context.l10n.submitIncident,
              ),
            ),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          SecuritySpacing.md,
          SecuritySpacing.xs,
          SecuritySpacing.md,
          SecuritySpacing.xl,
        ),
        children: [
          _IncidentNotice(message: context.l10n.incidentOperationalNotice),
          if (createContext != null) ...[
            const SizedBox(height: SecuritySpacing.sm),
            _IncidentNotice(
              message:
                  '${context.l10n.linkedPatrolCheckpoint}: ${createContext.checkpointName} • ${createContext.sessionNumber}',
            ),
          ],
          const SizedBox(height: SecuritySpacing.md),
          if (showPropertyPicker) ...[
            DropdownButtonFormField<int>(
              key: const Key('incidentPropertyDropdown'),
              initialValue: _selectedPropertyId,
              decoration: InputDecoration(labelText: context.l10n.selectProperty),
              items: properties
                  .map(
                    (property) => DropdownMenuItem<int>(
                      value: property.id,
                      child: Text('${property.code} • ${property.name}'),
                    ),
                  )
                  .toList(growable: false),
              onChanged: _mutating
                  ? null
                  : (value) => setState(() => _selectedPropertyId = value),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.propertyContextHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: SecuritySpacing.sm),
          ],
          TextField(
            key: const Key('incidentTitleField'),
            controller: _titleController,
            enabled: !_mutating,
            decoration: InputDecoration(labelText: context.l10n.incidentTitle),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          TextField(
            key: const Key('incidentCategoryField'),
            controller: _categoryController,
            enabled: !_mutating,
            decoration: InputDecoration(
              labelText: context.l10n.category,
              hintText: context.l10n.incidentCategoryExample,
            ),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          DropdownButtonFormField<IncidentSeverity>(
            key: const Key('incidentSeverityDropdown'),
            initialValue: _createSeverity,
            decoration: InputDecoration(labelText: context.l10n.severity),
            items: IncidentSeverity.values
                .map(
                  (severity) => DropdownMenuItem<IncidentSeverity>(
                    value: severity,
                    child: Text(_severityLabel(context, severity)),
                  ),
                )
                .toList(growable: false),
            onChanged: _mutating
                ? null
                : (value) {
                    if (value != null) {
                      setState(() => _createSeverity = value);
                    }
                  },
          ),
          const SizedBox(height: SecuritySpacing.sm),
          TextField(
            key: const Key('incidentLocationField'),
            controller: _locationController,
            enabled: !_mutating,
            decoration: InputDecoration(labelText: context.l10n.locationOptional),
          ),
          const SizedBox(height: SecuritySpacing.sm),
          TextField(
            key: const Key('incidentDescriptionField'),
            controller: _descriptionController,
            enabled: !_mutating,
            minLines: 4,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: context.l10n.incidentDescription,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: SecuritySpacing.md),
          _IncidentNotice(message: context.l10n.incidentNoMediaNotice),
        ],
      ),
    );
  }

  Widget _buildDetailFooter(BuildContext context, IncidentRecord incident) {
    final lifecycleActions = <Widget>[];

    if (incident.canAcknowledge) {
      lifecycleActions.add(
        FilledButton.tonal(
          key: const Key('acknowledgeIncidentButton'),
          onPressed: _mutating ? null : () => _acknowledge(incident),
          child: Text(context.l10n.acknowledgeIncident),
        ),
      );
    }
    if (incident.canStart) {
      lifecycleActions.add(
        FilledButton.tonal(
          key: const Key('startIncidentButton'),
          onPressed: _mutating ? null : () => _startIncident(incident),
          child: Text(context.l10n.startHandling),
        ),
      );
    }
    if (incident.canResolve) {
      lifecycleActions.add(
        FilledButton(
          key: const Key('resolveIncidentButton'),
          onPressed: _mutating ? null : () => _resolveIncident(incident),
          child: Text(context.l10n.resolveIncident),
        ),
      );
    }

    final canAddNote = incident.canAddNote;
    if (!canAddNote && lifecycleActions.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget lifecycleRow() {
      if (lifecycleActions.length == 1) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: lifecycleActions.single,
        );
      }

      return Row(
        children: [
          for (var index = 0; index < lifecycleActions.length; index++) ...[
            if (index > 0) const SizedBox(width: SecuritySpacing.xs),
            Expanded(
              child: SizedBox(
                height: 48,
                child: lifecycleActions[index],
              ),
            ),
          ],
        ],
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          SecuritySpacing.md,
          SecuritySpacing.sm,
          SecuritySpacing.md,
          SecuritySpacing.md,
        ),
        decoration: const BoxDecoration(
          color: SecurityColors.surface,
          border: Border(top: BorderSide(color: SecurityColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_mutating) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: SecuritySpacing.xs),
            ],
            if (canAddNote)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  key: const Key('addIncidentNoteButton'),
                  onPressed: _mutating ? null : () => _addNote(incident),
                  icon: const Icon(Icons.note_add_outlined),
                  label: Text(context.l10n.addIncidentNote),
                ),
              ),
            if (canAddNote && lifecycleActions.isNotEmpty)
              const SizedBox(height: SecuritySpacing.xs),
            if (lifecycleActions.isNotEmpty) lifecycleRow(),
          ],
        ),
      ),
    );
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.repository.dashboard(),
        widget.repository.incidents(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as IncidentDashboard;
        _incidents = results[1] as List<IncidentRecord>;
        _loading = false;
      });
    } on IncidentRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _failureMessage(context, error);
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final history = await widget.repository.history();
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
      });
    } on IncidentRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _failureMessage(context, error);
      });
    }
  }

  Future<void> _openIncident(int incidentId, {bool returnToHistory = false}) async {
    setState(() {
      _view = _IncidentView.detail;
      _selectedIncidentId = incidentId;
      _selectedIncident = null;
      _loading = true;
      _errorMessage = null;
    });
    try {
      final incident = await widget.repository.findById(incidentId);
      if (!mounted) return;
      setState(() {
        _selectedIncident = incident;
        _loading = false;
      });
      _detailReturnsToHistory = returnToHistory;
    } on IncidentRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMessage = _failureMessage(context, error);
      });
    }
  }

  bool _detailReturnsToHistory = false;

  Future<void> _retrySelectedIncident() async {
    final id = _selectedIncidentId;
    if (id != null) await _openIncident(id, returnToHistory: _detailReturnsToHistory);
  }

  void _openCreate() {
    _clearCreateForm();
    setState(() {
      _view = _IncidentView.create;
      _errorMessage = null;
    });
  }

  void _openHistory() {
    setState(() {
      _view = _IncidentView.history;
      _historyFilter = null;
      _errorMessage = null;
    });
    _loadHistory();
  }

  void _returnDashboard() {
    if (_detailReturnsToHistory && _view == _IncidentView.detail) {
      setState(() {
        _view = _IncidentView.history;
        _selectedIncident = null;
        _selectedIncidentId = null;
        _errorMessage = null;
      });
      _detailReturnsToHistory = false;
      return;
    }
    setState(() {
      _view = _IncidentView.dashboard;
      _selectedIncident = null;
      _selectedIncidentId = null;
      _errorMessage = null;
      _detailReturnsToHistory = false;
    });
  }

  Future<void> _submitIncident() async {
    final title = _titleController.text.trim();
    final category = _categoryController.text.trim();
    final description = _descriptionController.text.trim();
    final properties = widget.securityUser?.properties ?? const <SecurityProperty>[];
    if (_createContext == null &&
        properties.length > 1 &&
        _selectedPropertyId == null) {
      _showMessage(context.l10n.incidentPropertyRequired);
      return;
    }
    if (title.isEmpty) {
      _showMessage(context.l10n.incidentTitleRequired);
      return;
    }
    if (category.isEmpty) {
      _showMessage(context.l10n.incidentCategoryRequired);
      return;
    }
    if (description.isEmpty) {
      _showMessage(context.l10n.incidentDescriptionRequired);
      return;
    }

    setState(() => _mutating = true);
    try {
      await widget.repository.createIncident(
        IncidentCreateInput(
          propertyId: _selectedPropertyId,
          patrolCheckpointVisitId: _createContext?.patrolCheckpointVisitId,
          title: title,
          description: description,
          category: category,
          severity: _createSeverity,
          location: _locationController.text,
        ),
      );
      if (!mounted) return;
      final success = context.l10n.reportIncidentSuccess;
      _clearCreateForm();
      setState(() {
        _mutating = false;
        _view = _IncidentView.dashboard;
      });
      _showMessage(success);
      await _loadDashboard();
    } on IncidentRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() => _mutating = false);
      _showMessage(_failureMessage(context, error));
    }
  }

  Future<void> _acknowledge(IncidentRecord incident) async {
    final notes = await _promptNotes(
      title: context.l10n.acknowledgeIncident,
      label: context.l10n.optionalNotes,
      required: false,
    );
    if (notes == null || !mounted) return;
    await _runMutation(
      () => widget.repository.acknowledge(incident.incidentId, notes: notes),
    );
  }

  Future<void> _startIncident(IncidentRecord incident) async {
    final notes = await _promptNotes(
      title: context.l10n.startHandling,
      label: context.l10n.optionalNotes,
      required: false,
    );
    if (notes == null || !mounted) return;
    await _runMutation(
      () => widget.repository.start(incident.incidentId, notes: notes),
    );
  }

  Future<void> _resolveIncident(IncidentRecord incident) async {
    final notes = await _promptNotes(
      title: context.l10n.resolveIncident,
      label: context.l10n.resolutionNotes,
      required: true,
      validationMessage: context.l10n.resolutionNotesRequired,
    );
    if (notes == null || !mounted) return;
    await _runMutation(
      () => widget.repository.resolve(incident.incidentId, notes: notes),
    );
  }

  Future<void> _addNote(IncidentRecord incident) async {
    final notes = await _promptNotes(
      title: context.l10n.addIncidentNote,
      label: context.l10n.incidentNote,
      required: true,
      validationMessage: context.l10n.incidentNoteRequired,
    );
    if (notes == null || !mounted) return;
    await _runMutation(
      () => widget.repository.addNote(incident.incidentId, notes: notes),
    );
  }

  Future<void> _runMutation(Future<IncidentRecord> Function() action) async {
    setState(() {
      _mutating = true;
      _errorMessage = null;
    });
    try {
      final incident = await action();
      if (!mounted) return;
      setState(() {
        _selectedIncident = incident;
        _mutating = false;
      });
      await _refreshListsSilently();
    } on IncidentRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _mutating = false;
        _errorMessage = _failureMessage(context, error);
      });
    }
  }

  Future<void> _refreshListsSilently() async {
    try {
      final results = await Future.wait<Object>([
        widget.repository.dashboard(),
        widget.repository.incidents(),
      ]);
      if (!mounted) return;
      setState(() {
        _dashboard = results[0] as IncidentDashboard;
        _incidents = results[1] as List<IncidentRecord>;
      });
    } on Object {
      // Detail already holds canonical mutation state. Dashboard refresh can be
      // retried later without hiding the successful lifecycle mutation.
    }
  }

  Future<String?> _promptNotes({
    required String title,
    required String label,
    required bool required,
    String? validationMessage,
  }) async {
    final controller = TextEditingController();
    String? localError;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(title),
          content: TextField(
            key: const Key('incidentNotesDialogField'),
            controller: controller,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: label,
              errorText: localError,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              key: const Key('incidentNotesDialogSubmit'),
              onPressed: () {
                final value = controller.text.trim();
                if (required && value.isEmpty) {
                  setDialogState(
                    () => localError = validationMessage ?? context.l10n.incidentNoteRequired,
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(value);
              },
              child: Text(context.l10n.done),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  Future<bool> _handleSessionExpired(IncidentRepositoryException error) async {
    if (error.code != IncidentRepositoryFailureCode.unauthorized) return false;
    final onSessionExpired = widget.onSessionExpired;
    if (onSessionExpired != null) await onSessionExpired();
    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _clearCreateForm() {
    _createContext = null;
    _titleController.clear();
    _categoryController.clear();
    _locationController.clear();
    _descriptionController.clear();
    _createSeverity = IncidentSeverity.medium;
    _selectedPropertyId = widget.securityUser?.defaultPropertyId;
  }
}

class _IncidentScaffold extends StatelessWidget {
  const _IncidentScaffold({
    required this.header,
    required this.child,
    this.footer,
  });

  final Widget header;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          header,
          const Divider(height: 1),
          Expanded(child: child),
          ?footer,
        ],
      ),
    );
  }
}

class _IncidentHeader extends StatelessWidget {
  const _IncidentHeader({
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
      height: 56,
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

  final IncidentDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, Color)>[
      (context.l10n.openIncidents, dashboard.open, SecurityColors.info),
      (context.l10n.criticalIncidents, dashboard.critical, SecurityColors.danger),
      (context.l10n.escalatedIncidents, dashboard.escalated, SecurityColors.warning),
      (context.l10n.resolvedToday, dashboard.resolvedToday, SecurityColors.success),
    ];
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SecuritySpacing.xs,
        mainAxisSpacing: SecuritySpacing.xs,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final (label, value, color) = items[index];
        return Container(
          padding: const EdgeInsets.all(SecuritySpacing.sm),
          decoration: BoxDecoration(
            color: SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.md),
            border: Border.all(color: SecurityColors.border),
            boxShadow: SecurityShadows.soft,
          ),
          child: Row(
            children: [
              Text(
                '$value',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final IncidentRecord incident;
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
                children: [
                  Expanded(
                    child: Text(
                      incident.incidentNumber,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: SecurityColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _IncidentSeverityChip(severity: incident.severity),
                ],
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                incident.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  _IncidentStatusChip(status: incident.status),
                  const SizedBox(width: SecuritySpacing.xs),
                  Expanded(
                    child: Text(
                      incident.location ?? incident.property.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(context, incident.reportedAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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

class _IncidentDetailSummary extends StatelessWidget {
  const _IncidentDetailSummary({required this.incident});

  final IncidentRecord incident;

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(
                  incident.incidentNumber,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: SecurityColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              _IncidentSeverityChip(severity: incident.severity),
            ],
          ),
          const SizedBox(height: SecuritySpacing.xs),
          Text(
            incident.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: SecuritySpacing.sm),
          Wrap(
            spacing: SecuritySpacing.xs,
            runSpacing: SecuritySpacing.xs,
            children: [
              _IncidentStatusChip(status: incident.status),
              if (incident.escalationLevel > 0)
                _SimplePill(
                  label: '${context.l10n.escalationLevel} ${incident.escalationLevel}',
                  foreground: SecurityColors.warning,
                  background: SecurityColors.warningSoft,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IncidentInfoCard extends StatelessWidget {
  const _IncidentInfoCard({required this.incident});

  final IncidentRecord incident;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(label: context.l10n.category, value: incident.category),
          _InfoRow(
            label: context.l10n.property,
            value: '${incident.property.code} • ${incident.property.name}',
          ),
          _InfoRow(
            label: context.l10n.location,
            value: incident.location ?? '—',
          ),
          _InfoRow(
            label: context.l10n.reportedBy,
            value: incident.reportedBy?.name ?? '—',
          ),
          _InfoRow(
            label: context.l10n.assignedTo,
            value: incident.assignedTo?.name ?? '—',
          ),
          _InfoRow(
            label: context.l10n.incidentReportedAt,
            value: _formatDateTime(context, incident.reportedAt),
          ),
          if (incident.acknowledgedAt != null)
            _InfoRow(
              label: context.l10n.incidentAcknowledgedAt,
              value: _formatDateTime(context, incident.acknowledgedAt!),
            ),
          if (incident.resolvedAt != null)
            _InfoRow(
              label: context.l10n.incidentResolvedAt,
              value: _formatDateTime(context, incident.resolvedAt!),
            ),
          const Divider(height: SecuritySpacing.lg),
          Text(
            context.l10n.description,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(incident.description),
          if (incident.resolutionNotes != null) ...[
            const SizedBox(height: SecuritySpacing.md),
            Text(
              context.l10n.incidentResolution,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 6),
            Text(incident.resolutionNotes!),
          ],
        ],
      ),
    );
  }
}

class _PatrolContextCard extends StatelessWidget {
  const _PatrolContextCard({required this.context});

  final IncidentPatrolContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.primarySoft,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            buildContext.l10n.patrolContext,
            style: Theme.of(buildContext).textTheme.titleSmall,
          ),
          const SizedBox(height: SecuritySpacing.xs),
          _InfoRow(
            label: buildContext.l10n.patrolRoute,
            value: context.sessionNumber,
          ),
          _InfoRow(
            label: buildContext.l10n.checkpoint,
            value: context.checkpointName,
          ),
          if (context.checkpointLocation != null)
            _InfoRow(
              label: buildContext.l10n.location,
              value: context.checkpointLocation!,
            ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.event});

  final IncidentTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: SecurityColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.timeline_rounded,
              size: 18,
              color: SecurityColors.primary,
            ),
          ),
          const SizedBox(width: SecuritySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _eventLabel(context, event.event),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (event.fromStatus != null || event.toStatus != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    '${event.fromStatus == null ? '' : '${context.l10n.from}: ${_statusLabel(context, event.fromStatus!)}'}'
                    '${event.fromStatus != null && event.toStatus != null ? ' • ' : ''}'
                    '${event.toStatus == null ? '' : '${context.l10n.to}: ${_statusLabel(context, event.toStatus!)}'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (event.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(event.notes!),
                ],
                const SizedBox(height: 5),
                Text(
                  '${event.actor?.name ?? '—'} • ${_formatDateTime(context, event.createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SecurityColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
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
            width: 118,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: SecuritySpacing.xs),
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

class _IncidentStatusChip extends StatelessWidget {
  const _IncidentStatusChip({required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      IncidentStatus.open => (SecurityColors.info, SecurityColors.infoSoft),
      IncidentStatus.acknowledged => (SecurityColors.warning, SecurityColors.warningSoft),
      IncidentStatus.inProgress => (SecurityColors.primary, SecurityColors.primarySoft),
      IncidentStatus.resolved => (SecurityColors.success, SecurityColors.successSoft),
      IncidentStatus.closed => (SecurityColors.textSecondary, SecurityColors.surfaceMuted),
      IncidentStatus.cancelled => (SecurityColors.danger, SecurityColors.dangerSoft),
    };
    return _SimplePill(
      label: _statusLabel(context, status),
      foreground: foreground,
      background: background,
    );
  }
}

class _IncidentSeverityChip extends StatelessWidget {
  const _IncidentSeverityChip({required this.severity});

  final IncidentSeverity severity;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (severity) {
      IncidentSeverity.low => (SecurityColors.success, SecurityColors.successSoft),
      IncidentSeverity.medium => (SecurityColors.info, SecurityColors.infoSoft),
      IncidentSeverity.high => (SecurityColors.warning, SecurityColors.warningSoft),
      IncidentSeverity.critical => (SecurityColors.danger, SecurityColors.dangerSoft),
    };
    return _SimplePill(
      label: _severityLabel(context, severity),
      foreground: foreground,
      background: background,
    );
  }
}

class _SimplePill extends StatelessWidget {
  const _SimplePill({
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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _IncidentNotice extends StatelessWidget {
  const _IncidentNotice({required this.message, this.danger = false});

  final String message;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: danger ? SecurityColors.dangerSoft : SecurityColors.infoSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(
          color: danger ? SecurityColors.danger : SecurityColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            danger ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            size: 18,
            color: danger ? SecurityColors.danger : SecurityColors.info,
          ),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidentLoading extends StatelessWidget {
  const _IncidentLoading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: SecuritySpacing.sm),
          Text(label),
        ],
      ),
    );
  }
}

class _IncidentErrorState extends StatelessWidget {
  const _IncidentErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(SecuritySpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 42,
              color: SecurityColors.danger,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: SecuritySpacing.md),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _IncidentEmptyState extends StatelessWidget {
  const _IncidentEmptyState({
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
      width: double.infinity,
      padding: const EdgeInsets.all(SecuritySpacing.xl),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: SecurityColors.textMuted),
          const SizedBox(height: SecuritySpacing.xs),
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

String _statusLabel(BuildContext context, IncidentStatus status) => switch (status) {
      IncidentStatus.open => context.l10n.incidentStatusOpen,
      IncidentStatus.acknowledged => context.l10n.incidentStatusAcknowledged,
      IncidentStatus.inProgress => context.l10n.incidentStatusInProgress,
      IncidentStatus.resolved => context.l10n.incidentStatusResolved,
      IncidentStatus.closed => context.l10n.incidentStatusClosed,
      IncidentStatus.cancelled => context.l10n.incidentStatusCancelled,
    };

String _severityLabel(BuildContext context, IncidentSeverity severity) => switch (severity) {
      IncidentSeverity.low => context.l10n.severityLow,
      IncidentSeverity.medium => context.l10n.severityMedium,
      IncidentSeverity.high => context.l10n.severityHigh,
      IncidentSeverity.critical => context.l10n.severityCritical,
    };

String _eventLabel(BuildContext context, String event) => switch (event) {
      'reported' => context.l10n.eventReported,
      'status_changed' => context.l10n.eventStatusChanged,
      'note_added' => context.l10n.eventNoteAdded,
      _ => event.replaceAll('_', ' '),
    };

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatMediumDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date • $time';
}

String _failureMessage(
  BuildContext context,
  IncidentRepositoryException error,
) {
  return switch (error.code) {
    IncidentRepositoryFailureCode.incidentNotFound =>
      context.l10n.incidentFailureNotFound,
    IncidentRepositoryFailureCode.patrolCheckpointNotFound =>
      context.l10n.incidentFailureCheckpointNotFound,
    IncidentRepositoryFailureCode.patrolNotInProgress =>
      context.l10n.incidentFailurePatrolNotInProgress,
    IncidentRepositoryFailureCode.patrolCheckpointAlreadyProcessed =>
      context.l10n.incidentFailureCheckpointProcessed,
    IncidentRepositoryFailureCode.alreadyAcknowledged =>
      context.l10n.incidentFailureAlreadyAcknowledged,
    IncidentRepositoryFailureCode.alreadyInProgress =>
      context.l10n.incidentFailureAlreadyInProgress,
    IncidentRepositoryFailureCode.alreadyResolved =>
      context.l10n.incidentFailureAlreadyResolved,
    IncidentRepositoryFailureCode.closed => context.l10n.incidentFailureClosed,
    IncidentRepositoryFailureCode.cancelled =>
      context.l10n.incidentFailureCancelled,
    IncidentRepositoryFailureCode.invalidState =>
      context.l10n.incidentFailureInvalidState,
    IncidentRepositoryFailureCode.validation =>
      context.l10n.incidentFailureValidation,
    IncidentRepositoryFailureCode.unauthorized =>
      context.l10n.incidentFailureUnauthorized,
    IncidentRepositoryFailureCode.forbidden =>
      context.l10n.incidentFailureForbidden,
    IncidentRepositoryFailureCode.network =>
      context.l10n.incidentFailureNetwork,
    IncidentRepositoryFailureCode.unknown =>
      context.l10n.incidentFailureUnknown,
  };
}
