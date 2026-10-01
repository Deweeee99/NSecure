import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/visitor_visit.dart';
import '../widgets/visitor_formatters.dart';
import '../widgets/visitor_status_chip.dart';

class VisitorDetailScreen extends StatelessWidget {
  const VisitorDetailScreen({
    required this.visit,
    required this.isLoading,
    required this.onBack,
    required this.onCheckIn,
    required this.onCheckOut,
    super.key,
  });

  final VisitorVisit visit;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _DetailHeader(onBack: onBack),
          Expanded(
            child: ListView(
              key: const Key('visitorDetailScroll'),
              padding: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.sm,
                SecuritySpacing.md,
                SecuritySpacing.md,
              ),
              children: [
                _IdentityCard(visit: visit),
                const SizedBox(height: SecuritySpacing.sm),
                _VisitInformationCard(visit: visit),
                const SizedBox(height: SecuritySpacing.sm),
                _OperationalStateCard(visit: visit),
              ],
            ),
          ),
          _DetailActionFooter(
            visit: visit,
            isLoading: isLoading,
            onCheckIn: onCheckIn,
            onCheckOut: onCheckOut,
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: SecuritySpacing.xs),
      color: SecurityColors.surface,
      child: Row(
        children: [
          IconButton(
            key: const Key('visitorDetailBack'),
            tooltip: context.l10n.back,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Expanded(
            child: Text(
              context.l10n.visitorDetail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.visit});

  final VisitorVisit visit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: SecurityColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: SecuritySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  visit.visitorName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  visit.visitorPhone,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: SecuritySpacing.sm),
          VisitorStatusChip(status: visit.status),
        ],
      ),
    );
  }
}

class _VisitInformationCard extends StatelessWidget {
  const _VisitInformationCard({required this.visit});

  final VisitorVisit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _DetailRow(label: l10n.visitCode, value: visit.visitCode),
          _DetailRow(label: l10n.visitorId, value: visit.visitorId),
          _DetailRow(label: l10n.residentName, value: visit.residentName),
          _DetailRow(label: l10n.property, value: visit.propertyName),
          _DetailRow(label: l10n.tower, value: VisitorFormatters.text(visit.towerName)),
          _DetailRow(label: l10n.unit, value: VisitorFormatters.text(visit.unitName)),
          _DetailRow(label: l10n.visitPurpose, value: visit.purpose),
          _DetailRow(
            label: l10n.scheduledDate,
            value: VisitorFormatters.date(context, visit.scheduledAt),
          ),
          _DetailRow(
            label: l10n.validTimeWindow,
            value:
                '${VisitorFormatters.time(context, visit.validFrom)} – ${VisitorFormatters.time(context, visit.validUntil)}',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _OperationalStateCard extends StatelessWidget {
  const _OperationalStateCard({required this.visit});

  final VisitorVisit visit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = <Widget>[
      _DetailRow(label: l10n.currentStatus, value: _visitorStatusLabel(context, visit.status)),
    ];

    if (visit.checkedInAt != null) {
      rows.add(
        _DetailRow(
          label: l10n.checkInTime,
          value: VisitorFormatters.dateTime(context, visit.checkedInAt!),
        ),
      );
    }
    if (visit.checkedInBy != null) {
      rows.add(
        _DetailRow(label: l10n.checkedInBy, value: visit.checkedInBy!),
      );
    }
    if (visit.checkedOutAt != null) {
      rows.add(
        _DetailRow(
          label: l10n.checkOutTime,
          value: VisitorFormatters.dateTime(context, visit.checkedOutAt!),
        ),
      );
    }
    if (visit.checkedOutBy != null) {
      rows.add(
        _DetailRow(
          label: l10n.checkedOutBy,
          value: visit.checkedOutBy!,
          showDivider: false,
        ),
      );
    } else if (rows.isNotEmpty) {
      final last = rows.removeLast();
      if (last is _DetailRow) {
        rows.add(
          _DetailRow(
            label: last.label,
            value: last.value,
            showDivider: false,
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: _cardDecoration(),
      child: Column(children: rows),
    );
  }
}

class _DetailActionFooter extends StatelessWidget {
  const _DetailActionFooter({
    required this.visit,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final VisitorVisit visit;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: _PrimaryAction(
        visit: visit,
        isLoading: isLoading,
        onCheckIn: onCheckIn,
        onCheckOut: onCheckOut,
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.visit,
    required this.isLoading,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  final VisitorVisit visit;
  final bool isLoading;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (visit.canCheckIn) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('checkInVisitorButton'),
          onPressed: isLoading ? null : onCheckIn,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.login_rounded),
          label: Text(isLoading ? l10n.checkingIn : l10n.checkInVisitor),
        ),
      );
    }

    if (visit.canCheckOut) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          key: const Key('checkOutVisitorButton'),
          onPressed: isLoading ? null : onCheckOut,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.logout_rounded),
          label: Text(isLoading ? l10n.checkingOut : l10n.checkOutVisitor),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surfaceMuted,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 19,
            color: SecurityColors.textMuted,
          ),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(
              _blockedMessage(context, visit),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static String _blockedMessage(BuildContext context, VisitorVisit visit) {
    final l10n = context.l10n;
    return switch (visit.status) {
      VisitorStatus.pending => l10n.visitPendingActionHint,
      VisitorStatus.checkedOut => l10n.visitCheckedOutHint,
      VisitorStatus.expired => l10n.visitExpiredHint,
      VisitorStatus.rejected => l10n.visitRejectedHint,
      VisitorStatus.cancelled => l10n.visitCancelledHint,
      VisitorStatus.approved => l10n.visitApprovedCheckInUnavailable,
      VisitorStatus.checkedIn => l10n.visitCheckedInHint,
    };
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

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
              SizedBox(
                width: 112,
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: SecuritySpacing.xs),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SecurityColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
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

String _visitorStatusLabel(BuildContext context, VisitorStatus status) {
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

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: SecurityColors.surface,
    borderRadius: BorderRadius.circular(SecurityRadius.lg),
    border: Border.all(color: SecurityColors.border),
    boxShadow: SecurityShadows.soft,
  );
}
