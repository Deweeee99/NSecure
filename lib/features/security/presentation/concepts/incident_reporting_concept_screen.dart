import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import 'widgets/concept_widgets.dart';

class IncidentReportingConceptScreen extends StatefulWidget {
  const IncidentReportingConceptScreen({
    required this.onBackHome,
    super.key,
  });

  final VoidCallback onBackHome;

  @override
  State<IncidentReportingConceptScreen> createState() =>
      _IncidentReportingConceptScreenState();
}

class _IncidentReportingConceptScreenState
    extends State<IncidentReportingConceptScreen> {
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    return _showDetail ? _buildDetail(context) : _buildReporting(context);
  }

  Widget _buildReporting(BuildContext context) {
    final l10n = context.l10n;

    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: l10n.incidentReporting,
        onBack: widget.onBackHome,
      ),
      children: [
        ConceptNotice(message: l10n.incidentConceptNotice),
        _incidentTypeSelector(context),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            labelText: l10n.location,
            hintText: l10n.enterLocationDetails,
            suffixIcon: const Icon(Icons.chevron_right_rounded),
          ),
        ),
        TextField(
          readOnly: true,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: l10n.description,
            hintText: l10n.provideIncidentDescription,
            alignLabelWithHint: true,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.photoEvidenceOptional,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: SecuritySpacing.xs),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: SecuritySpacing.md,
                vertical: SecuritySpacing.xl,
              ),
              decoration: BoxDecoration(
                color: SecurityColors.surface,
                borderRadius: BorderRadius.circular(SecurityRadius.md),
                border: Border.all(
                  color: SecurityColors.border,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    color: SecurityColors.textMuted,
                  ),
                  const SizedBox(height: SecuritySpacing.xs),
                  Text(
                    l10n.photoEvidenceConceptArea,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: null,
            child: Text(l10n.submitReportFuture),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('incidentDetailConceptButton'),
            onPressed: () => setState(() => _showDetail = true),
            icon: const Icon(Icons.visibility_outlined),
            label: Text(l10n.viewExampleIncidentDetail),
          ),
        ),
      ],
    );
  }

  Widget _incidentTypeSelector(BuildContext context) {
    final l10n = context.l10n;
    final types = [
      (l10n.securityBreach, Icons.shield_outlined, true),
      (l10n.suspiciousActivity, Icons.person_search_outlined, false),
      (l10n.accident, Icons.warning_amber_rounded, false),
      (l10n.vandalism, Icons.handyman_outlined, false),
      (l10n.fire, Icons.local_fire_department_outlined, false),
      (l10n.other, Icons.more_horiz_rounded, false),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.incidentType,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: SecuritySpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: types.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: SecuritySpacing.xs,
            mainAxisSpacing: SecuritySpacing.xs,
            childAspectRatio: 2.15,
          ),
          itemBuilder: (context, index) {
            final (label, icon, selected) = types[index];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected
                    ? SecurityColors.primarySoft
                    : SecurityColors.surface,
                borderRadius: BorderRadius.circular(SecurityRadius.sm),
                border: Border.all(
                  color: selected
                      ? SecurityColors.primary
                      : SecurityColors.border,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected
                        ? SecurityColors.primary
                        : SecurityColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: selected
                                ? SecurityColors.primary
                                : SecurityColors.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDetail(BuildContext context) {
    final l10n = context.l10n;

    return ConceptPageBody(
      header: ConceptScreenHeader(
        title: l10n.incidentDetail,
        onBack: () => setState(() => _showDetail = false),
      ),
      children: [
        ConceptNotice(message: l10n.exampleIncidentDetailNotice),
        ConceptCard(
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: const BoxDecoration(
                      color: SecurityColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_search_outlined,
                      color: SecurityColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: SecuritySpacing.sm),
                  Expanded(
                    child: Column(
                      children: [
                        ConceptInfoRow(
                          label: l10n.incidentId,
                          value: 'INC-240515-014',
                        ),
                        ConceptInfoRow(
                          label: l10n.incidentType,
                          value: l10n.suspiciousActivity,
                        ),
                        ConceptInfoRow(
                          label: l10n.reportedAt,
                          value: '15 May 2024 • 09:42 PM',
                        ),
                        ConceptInfoRow(
                          label: l10n.location,
                          value: l10n.incidentSampleLocation,
                        ),
                        ConceptInfoRow(
                          label: l10n.reportedBy,
                          value: l10n.incidentSampleReportedBy,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: SecuritySpacing.lg),
              ConceptInfoRow(
                label: l10n.currentStatus,
                value: l10n.reportedStatus,
                valueColor: SecurityColors.info,
              ),
            ],
          ),
        ),
        ConceptCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConceptSectionTitle(title: l10n.description),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                l10n.incidentSampleDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        ConceptCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConceptSectionTitle(title: l10n.evidence),
              const SizedBox(height: SecuritySpacing.sm),
              Container(
                height: 118,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: SecurityColors.primaryDeep,
                  borderRadius: BorderRadius.circular(SecurityRadius.md),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(painter: _ParkingEvidencePainter()),
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(SecuritySpacing.sm),
                        child: ConceptPill(
                          label: l10n.evidencePreview,
                          foreground: Colors.white,
                          background: const Color(0x66000000),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _showDetail = false),
            child: Text(l10n.done),
          ),
        ),
      ],
    );
  }
}

class _ParkingEvidencePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.white.withAlpha(45)
      ..strokeWidth = 2;
    final lightPaint = Paint()..color = Colors.white.withAlpha(28);

    canvas.drawRect(Offset.zero & size, lightPaint);
    for (var x = 18.0; x < size.width; x += 72) {
      canvas.drawLine(
        Offset(x, size.height * .66),
        Offset(x + 34, size.height),
        linePaint,
      );
    }
    canvas.drawLine(
      Offset(0, size.height * .62),
      Offset(size.width, size.height * .62),
      linePaint,
    );
    canvas.drawCircle(
      Offset(size.width * .72, size.height * .32),
      13,
      Paint()..color = SecurityColors.accent.withAlpha(140),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
