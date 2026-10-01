import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/theme/security_tokens.dart';
import '../domain/models/emergency_alert_models.dart';

class EmergencyAlertOverlay extends StatelessWidget {
  const EmergencyAlertOverlay({
    required this.alert,
    required this.onAcknowledge,
    this.isSubmitting = false,
    this.errorMessage,
    super.key,
  });

  final EmergencyAlert alert;
  final Future<void> Function() onAcknowledge;
  final bool isSubmitting;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.46),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              key: const Key('emergencyPersistentModal'),
              margin: const EdgeInsets.all(SecuritySpacing.md),
              padding: const EdgeInsets.all(SecuritySpacing.lg),
              decoration: BoxDecoration(
                color: SecurityColors.surface,
                borderRadius: BorderRadius.circular(SecurityRadius.xl),
                border: Border.all(color: SecurityColors.danger.withValues(alpha: 0.28)),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    blurRadius: 30,
                    offset: Offset(0, 12),
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: SecurityColors.dangerSoft,
                          borderRadius: BorderRadius.circular(SecurityRadius.md),
                        ),
                        child: const Icon(
                          Icons.sos_rounded,
                          color: SecurityColors.danger,
                        ),
                      ),
                      const SizedBox(width: SecuritySpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.emergencySosAlert,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: SecurityColors.danger,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            Text(
                              alert.alertCode,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: SecuritySpacing.md),
                  Text(
                    alert.resident.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _unitLabel(alert),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: SecurityColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (alert.message != null) ...[
                    const SizedBox(height: SecuritySpacing.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(SecuritySpacing.sm),
                      decoration: BoxDecoration(
                        color: SecurityColors.dangerSoft,
                        borderRadius: BorderRadius.circular(SecurityRadius.md),
                      ),
                      child: Text(
                        alert.message!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: SecurityColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                  const SizedBox(height: SecuritySpacing.sm),
                  Text(
                    '${context.l10n.emergencyTriggeredAt}: ${_formatDateTime(context, alert.triggeredAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: SecuritySpacing.sm),
                    Text(
                      errorMessage!,
                      key: const Key('emergencyModalError'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: SecurityColors.danger,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                  const SizedBox(height: SecuritySpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const Key('emergencyAcknowledgeButton'),
                      onPressed: isSubmitting ? null : onAcknowledge,
                      icon: isSubmitting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.pan_tool_alt_rounded),
                      label: Text(
                        isSubmitting
                            ? context.l10n.emergencyTakingAlert
                            : context.l10n.emergencyTakeAlert,
                      ),
                    ),
                  ),
                  const SizedBox(height: SecuritySpacing.xs),
                  Text(
                    context.l10n.emergencyPersistentModalHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: SecurityColors.textMuted,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _unitLabel(EmergencyAlert alert) {
  final unit = alert.unit;
  final parts = <String>[
    if (unit.tower?.trim().isNotEmpty == true) unit.tower!.trim(),
    unit.code,
  ];
  return parts.join(' • ');
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
