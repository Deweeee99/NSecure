import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/theme/security_tokens.dart';
import '../domain/models/emergency_alert_models.dart';
import '../domain/repositories/emergency_alert_repository.dart';

class EmergencyManagementScreen extends StatefulWidget {
  const EmergencyManagementScreen({
    required this.repository,
    required this.onBackHome,
    this.initialAlertId,
    this.onActiveAlertsChanged,
    this.onSessionExpired,
    super.key,
  });

  final EmergencyAlertRepository repository;
  final VoidCallback onBackHome;
  final int? initialAlertId;
  final VoidCallback? onActiveAlertsChanged;
  final Future<void> Function()? onSessionExpired;

  @override
  State<EmergencyManagementScreen> createState() =>
      _EmergencyManagementScreenState();
}

class _EmergencyManagementScreenState extends State<EmergencyManagementScreen> {
  List<EmergencyAlert> _unresolved = const <EmergencyAlert>[];
  List<EmergencyAlert> _history = const <EmergencyAlert>[];
  EmergencyAlert? _selected;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  final _resolutionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _resolutionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    if (selected != null) {
      return _buildDetail(context, selected);
    }
    return _buildDashboard(context);
  }

  Widget _buildDashboard(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          children: [
            _Header(
              title: context.l10n.emergencySos,
              subtitle: context.l10n.emergencySosSubtitle,
              onBack: widget.onBackHome,
            ),
            const SizedBox(height: SecuritySpacing.md),
            _Notice(message: context.l10n.emergencyBackendSourceOfTruth),
            const SizedBox(height: SecuritySpacing.lg),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(SecuritySpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _load)
            else ...[
              _SectionTitle(
                title: context.l10n.emergencyUnresolvedAlerts,
                count: _unresolved.length,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              if (_unresolved.isEmpty)
                _EmptyCard(
                  icon: Icons.verified_user_outlined,
                  title: context.l10n.emergencyNoUnresolved,
                  message: context.l10n.emergencyNoUnresolvedMessage,
                )
              else
                ..._unresolved.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: SecuritySpacing.sm),
                    child: _EmergencyCard(
                      alert: alert,
                      onTap: () => _openAlert(alert.emergencyAlertId),
                    ),
                  ),
                ),
              const SizedBox(height: SecuritySpacing.lg),
              _SectionTitle(
                title: context.l10n.emergencyHistory,
                count: _history.length,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              if (_history.isEmpty)
                _EmptyCard(
                  icon: Icons.history_rounded,
                  title: context.l10n.emergencyNoHistory,
                  message: context.l10n.emergencyNoHistoryMessage,
                )
              else
                ..._history.map(
                  (alert) => Padding(
                    padding: const EdgeInsets.only(bottom: SecuritySpacing.sm),
                    child: _EmergencyCard(
                      alert: alert,
                      onTap: () => _openAlert(alert.emergencyAlertId),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, EmergencyAlert alert) {
    final canAcknowledge = alert.status == EmergencyAlertStatus.open;
    final canResolve = alert.status == EmergencyAlertStatus.acknowledged &&
        alert.takenByMe;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            120,
          ),
          children: [
            _Header(
              title: context.l10n.emergencyAlertDetail,
              subtitle: alert.alertCode,
              onBack: () => setState(() => _selected = null),
            ),
            const SizedBox(height: SecuritySpacing.md),
            _EmergencyCard(alert: alert, onTap: () {}),
            const SizedBox(height: SecuritySpacing.md),
            _InfoCard(
              rows: <(String, String)>[
                (context.l10n.property, alert.property.name),
                (context.l10n.emergencyResident, alert.resident.name),
                (context.l10n.emergencyUnit, _unitLabel(alert)),
                (
                  context.l10n.emergencyTriggeredAt,
                  _formatDateTime(context, alert.triggeredAt),
                ),
                if (alert.acknowledgedAt != null)
                  (
                    context.l10n.emergencyAcknowledgedAt,
                    _formatDateTime(context, alert.acknowledgedAt!),
                  ),
                if (alert.acknowledgedBy != null)
                  (
                    context.l10n.emergencyTakenBy,
                    alert.acknowledgedBy!.name,
                  ),
                if (alert.resolvedAt != null)
                  (
                    context.l10n.emergencyResolvedAt,
                    _formatDateTime(context, alert.resolvedAt!),
                  ),
              ],
            ),
            if (alert.message != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _InfoCard(
                rows: <(String, String)>[
                  (context.l10n.emergencyMessage, alert.message!),
                ],
              ),
            ],
            if (alert.resolutionNotes != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _InfoCard(
                rows: <(String, String)>[
                  (context.l10n.emergencyResolutionNotes, alert.resolutionNotes!),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _ErrorCard(message: _error!, onRetry: () => _openAlert(alert.emergencyAlertId)),
            ],
            if (canResolve) ...[
              const SizedBox(height: SecuritySpacing.md),
              TextField(
                key: const Key('emergencyResolutionNotesField'),
                controller: _resolutionController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.emergencyResolutionNotes,
                  hintText: context.l10n.emergencyResolutionNotesHint,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: (canAcknowledge || canResolve)
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.xs,
                SecuritySpacing.md,
                SecuritySpacing.md,
              ),
              child: FilledButton.icon(
                key: Key(
                  canAcknowledge
                      ? 'emergencyDetailAcknowledgeButton'
                      : 'emergencyResolveButton',
                ),
                onPressed: _submitting
                    ? null
                    : canAcknowledge
                        ? () => _acknowledge(alert)
                        : () => _resolve(alert),
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        canAcknowledge
                            ? Icons.pan_tool_alt_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                label: Text(
                  canAcknowledge
                      ? context.l10n.emergencyTakeAlert
                      : context.l10n.emergencyResolveAlert,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<Object>(<Future<Object>>[
        widget.repository.unresolvedAlerts(),
        widget.repository.history(),
      ]);
      if (!mounted) return;
      setState(() {
        _unresolved = results[0] as List<EmergencyAlert>;
        _history = results[1] as List<EmergencyAlert>;
        _loading = false;
      });
      final initialId = widget.initialAlertId;
      if (initialId != null) {
        await _openAlert(initialId);
      }
    } on EmergencyRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _failureMessage(context, error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.emergencyFailureUnknown;
      });
    }
  }

  Future<void> _openAlert(int emergencyAlertId) async {
    try {
      final alert = await widget.repository.findById(emergencyAlertId);
      if (!mounted) return;
      if (alert == null) {
        setState(() => _error = context.l10n.emergencyFailureNotFound);
        return;
      }
      setState(() {
        _selected = alert;
        _error = null;
        _resolutionController.text = alert.resolutionNotes ?? '';
      });
    } on EmergencyRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() => _error = _failureMessage(context, error));
    }
  }

  Future<void> _acknowledge(EmergencyAlert alert) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.acknowledge(alert.emergencyAlertId);
      if (!mounted) return;
      setState(() {
        _selected = updated;
        _submitting = false;
      });
      widget.onActiveAlertsChanged?.call();
      await _refreshListsOnly();
    } on EmergencyRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _failureMessage(context, error);
      });
      if (error.code == EmergencyRepositoryFailureCode.alreadyTaken ||
          error.code == EmergencyRepositoryFailureCode.alreadyResolved) {
        widget.onActiveAlertsChanged?.call();
      }
    }
  }

  Future<void> _resolve(EmergencyAlert alert) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.resolve(
        alert.emergencyAlertId,
        notes: _resolutionController.text,
      );
      if (!mounted) return;
      setState(() {
        _selected = updated;
        _submitting = false;
      });
      widget.onActiveAlertsChanged?.call();
      await _refreshListsOnly();
    } on EmergencyRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _failureMessage(context, error);
      });
    }
  }

  Future<void> _refreshListsOnly() async {
    try {
      final unresolved = await widget.repository.unresolvedAlerts();
      final history = await widget.repository.history();
      if (!mounted) return;
      setState(() {
        _unresolved = unresolved;
        _history = history;
      });
    } on Object {
      // The current mutation already succeeded. A follow-up list refresh is
      // best effort and must not erase the canonical detail returned by it.
    }
  }

  Future<bool> _handleSessionExpired(EmergencyRepositoryException error) async {
    if (error.code != EmergencyRepositoryFailureCode.unauthorized) return false;
    final handler = widget.onSessionExpired;
    if (handler != null) await handler();
    return true;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: context.l10n.back,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.infoSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_done_outlined, color: SecurityColors.info, size: 20),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        Text('$count', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({required this.alert, required this.onTap});

  final EmergencyAlert alert;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusLabel(context, alert.status);
    final tone = switch (alert.status) {
      EmergencyAlertStatus.open => (SecurityColors.danger, SecurityColors.dangerSoft),
      EmergencyAlertStatus.acknowledged => (SecurityColors.warning, SecurityColors.warningSoft),
      EmergencyAlertStatus.resolved => (SecurityColors.success, SecurityColors.successSoft),
    };
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
                      alert.resident.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: tone.$2,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: tone.$1,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${alert.alertCode} • ${_unitLabel(alert)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (alert.message != null) ...[
                const SizedBox(height: SecuritySpacing.xs),
                Text(
                  alert.message!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                _formatDateTime(context, alert.triggeredAt),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: SecurityColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});

  final List<(String, String)> rows;

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
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 128,
                      child: Text(row.$1, style: Theme.of(context).textTheme.bodySmall),
                    ),
                    const SizedBox(width: SecuritySpacing.xs),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.dangerSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: SecurityColors.danger)),
          const SizedBox(height: SecuritySpacing.xs),
          TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.lg),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: SecurityColors.textMuted),
          const SizedBox(height: SecuritySpacing.xs),
          Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

String _statusLabel(BuildContext context, EmergencyAlertStatus status) => switch (status) {
      EmergencyAlertStatus.open => context.l10n.emergencyStatusOpen,
      EmergencyAlertStatus.acknowledged => context.l10n.emergencyStatusAcknowledged,
      EmergencyAlertStatus.resolved => context.l10n.emergencyStatusResolved,
    };

String _unitLabel(EmergencyAlert alert) {
  final unit = alert.unit;
  return <String>[
    if (unit.tower?.trim().isNotEmpty == true) unit.tower!.trim(),
    unit.code,
  ].join(' • ');
}

String _formatDateTime(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final localizations = MaterialLocalizations.of(context);
  final date = localizations.formatShortDate(local);
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date • $time';
}

String _failureMessage(BuildContext context, EmergencyRepositoryException error) {
  return switch (error.code) {
    EmergencyRepositoryFailureCode.notFound => context.l10n.emergencyFailureNotFound,
    EmergencyRepositoryFailureCode.alreadyTaken => context.l10n.emergencyFailureAlreadyTaken,
    EmergencyRepositoryFailureCode.alreadyResolved => context.l10n.emergencyFailureAlreadyResolved,
    EmergencyRepositoryFailureCode.notAcknowledged => context.l10n.emergencyFailureNotAcknowledged,
    EmergencyRepositoryFailureCode.assignedToOther => context.l10n.emergencyFailureAssignedToOther,
    EmergencyRepositoryFailureCode.validation => context.l10n.emergencyFailureValidation,
    EmergencyRepositoryFailureCode.unauthorized => context.l10n.authUnauthenticated,
    EmergencyRepositoryFailureCode.forbidden => context.l10n.authForbidden,
    EmergencyRepositoryFailureCode.network => context.l10n.authNetwork,
    EmergencyRepositoryFailureCode.unknown =>
      error.message?.trim().isNotEmpty == true ? error.message! : context.l10n.emergencyFailureUnknown,
  };
}
