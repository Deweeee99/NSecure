import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/visitor_visit.dart';
import '../widgets/visitor_formatters.dart';

enum VisitorActionType { checkIn, checkOut }

class VisitorActionConfirmationScreen extends StatelessWidget {
  const VisitorActionConfirmationScreen({
    required this.actionType,
    required this.visit,
    required this.onDone,
    required this.onContinueVerifying,
    super.key,
  });

  final VisitorActionType actionType;
  final VisitorVisit visit;
  final VoidCallback onDone;
  final VoidCallback onContinueVerifying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCheckIn = actionType == VisitorActionType.checkIn;
    final actionTime = isCheckIn ? visit.checkedInAt : visit.checkedOutAt;
    final officer = isCheckIn ? visit.checkedInBy : visit.checkedOutBy;
    final accent = isCheckIn ? SecurityColors.success : SecurityColors.primary;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              key: const Key('visitorConfirmationScroll'),
              padding: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.xxl,
                SecuritySpacing.md,
                SecuritySpacing.md,
              ),
              children: [
                Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                      boxShadow: SecurityShadows.soft,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                ),
                const SizedBox(height: SecuritySpacing.lg),
                Text(
                  isCheckIn ? l10n.checkInSuccessful : l10n.checkOutSuccessful,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: accent,
                      ),
                ),
                const SizedBox(height: SecuritySpacing.xs),
                Text(
                  isCheckIn ? l10n.visitorCheckedIn : l10n.visitorCheckedOut,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: SecuritySpacing.xl),
                Container(
                  padding: const EdgeInsets.all(SecuritySpacing.md),
                  decoration: BoxDecoration(
                    color: SecurityColors.surface,
                    borderRadius: BorderRadius.circular(SecurityRadius.lg),
                    border: Border.all(color: SecurityColors.border),
                    boxShadow: SecurityShadows.soft,
                  ),
                  child: Column(
                    children: [
                      _ConfirmationRow(
                        icon: Icons.person_outline_rounded,
                        label: l10n.visitor,
                        value: visit.visitorName,
                      ),
                      _ConfirmationRow(
                        icon: Icons.qr_code_rounded,
                        label: l10n.visitCode,
                        value: visit.visitCode,
                      ),
                      _ConfirmationRow(
                        icon: Icons.home_work_outlined,
                        label: l10n.residentUnit,
                        value:
                            '${visit.residentName} • ${VisitorFormatters.unitAndTower(context, unitName: visit.unitName, towerName: visit.towerName)}',
                      ),
                      _ConfirmationRow(
                        icon: Icons.schedule_rounded,
                        label: isCheckIn ? l10n.checkInTime : l10n.checkOutTime,
                        value: actionTime == null
                            ? '—'
                            : VisitorFormatters.time(context, actionTime),
                      ),
                      _ConfirmationRow(
                        icon: Icons.verified_user_outlined,
                        label: isCheckIn ? l10n.checkedInBy : l10n.checkedOutBy,
                        value: officer ?? l10n.securityTeam,
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(
              SecuritySpacing.md,
              SecuritySpacing.sm,
              SecuritySpacing.md,
              SecuritySpacing.md,
            ),
            decoration: const BoxDecoration(
              color: SecurityColors.surface,
              border: Border(
                top: BorderSide(color: SecurityColors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    key: const Key('confirmationDoneButton'),
                    onPressed: onDone,
                    child: Text(l10n.done),
                  ),
                ),
                const SizedBox(height: SecuritySpacing.xs),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    key: const Key('continueVerifyingButton'),
                    onPressed: onContinueVerifying,
                    child: Text(l10n.continueVerifying),
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

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: SecuritySpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 19, color: SecurityColors.textSecondary),
              const SizedBox(width: SecuritySpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: SecurityColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }
}
