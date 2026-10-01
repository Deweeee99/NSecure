import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';
import '../../../../core/theme/security_tokens.dart';
import '../../domain/models/module_preview.dart';

class SecurityStatusChip extends StatelessWidget {
  const SecurityStatusChip({
    required this.status,
    super.key,
  });

  final ModulePreviewStatus status;

  @override
  Widget build(BuildContext context) {
    final config = switch (status) {
      ModulePreviewStatus.active => _ChipConfig(
          label: context.l10n.active,
          foreground: SecurityColors.success,
          background: SecurityColors.successSoft,
        ),
      ModulePreviewStatus.comingSoon => _ChipConfig(
          label: context.l10n.comingSoon,
          foreground: SecurityColors.info,
          background: SecurityColors.infoSoft,
        ),
      ModulePreviewStatus.designConcept => _ChipConfig(
          label: context.l10n.concept,
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
        config.label,
        maxLines: 1,
        overflow: TextOverflow.fade,
        softWrap: false,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: config.foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .2,
            ),
      ),
    );
  }
}

class _ChipConfig {
  const _ChipConfig({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;
}
