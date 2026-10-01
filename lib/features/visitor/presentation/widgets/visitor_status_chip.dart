import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/visitor_visit.dart';

class VisitorStatusChip extends StatelessWidget {
  const VisitorStatusChip({
    required this.status,
    super.key,
  });

  final VisitorStatus status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      VisitorStatus.pending => const _VisitorStatusConfig(
          foreground: SecurityColors.warning,
          background: SecurityColors.warningSoft,
        ),
      VisitorStatus.approved => const _VisitorStatusConfig(
          foreground: SecurityColors.success,
          background: SecurityColors.successSoft,
        ),
      VisitorStatus.checkedIn => const _VisitorStatusConfig(
          foreground: SecurityColors.info,
          background: SecurityColors.infoSoft,
        ),
      VisitorStatus.checkedOut => const _VisitorStatusConfig(
          foreground: SecurityColors.info,
          background: SecurityColors.infoSoft,
        ),
      VisitorStatus.expired => const _VisitorStatusConfig(
          foreground: SecurityColors.danger,
          background: SecurityColors.dangerSoft,
        ),
      VisitorStatus.rejected => const _VisitorStatusConfig(
          foreground: SecurityColors.danger,
          background: SecurityColors.dangerSoft,
        ),
      VisitorStatus.cancelled => const _VisitorStatusConfig(
          foreground: SecurityColors.textSecondary,
          background: SecurityColors.surfaceMuted,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _localizedStatus(context, status).toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: config.foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .15,
            ),
      ),
    );
  }

  String _localizedStatus(BuildContext context, VisitorStatus status) {
    final l10n = context.l10n;
    return switch (status) {
      VisitorStatus.pending => l10n.visitorStatusPending,
      VisitorStatus.approved => l10n.approvedStatus,
      VisitorStatus.checkedIn => l10n.checkedInStatus,
      VisitorStatus.checkedOut => l10n.checkedOutStatus,
      VisitorStatus.expired => l10n.expiredStatus,
      VisitorStatus.rejected => l10n.rejectedStatus,
      VisitorStatus.cancelled => l10n.cancelledStatus,
    };
  }
}

class _VisitorStatusConfig {
  const _VisitorStatusConfig({
    required this.foreground,
    required this.background,
  });

  final Color foreground;
  final Color background;
}
