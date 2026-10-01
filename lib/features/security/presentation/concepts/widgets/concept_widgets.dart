import 'package:flutter/material.dart';

import '../../../../../core/localization/app_localizations_x.dart';

import '../../../../../core/theme/security_tokens.dart';

class ConceptScreenHeader extends StatelessWidget {
  const ConceptScreenHeader({
    required this.title,
    required this.onBack,
    super.key,
    this.trailing,
  });

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          SizedBox(
            width: 48,
            child: trailing,
          ),
        ],
      ),
    );
  }
}

class ConceptNotice extends StatelessWidget {
  const ConceptNotice({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.infoSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.accent.withAlpha(70)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: SecurityColors.info,
          ),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(
              message ?? context.l10n.designConceptNotice,
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
}

class ConceptCard extends StatelessWidget {
  const ConceptCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(SecuritySpacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
        boxShadow: SecurityShadows.soft,
      ),
      child: child,
    );
  }
}

class ConceptSectionTitle extends StatelessWidget {
  const ConceptSectionTitle({
    required this.title,
    super.key,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class ConceptInfoRow extends StatelessWidget {
  const ConceptInfoRow({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: SecurityColors.textMuted),
            const SizedBox(width: SecuritySpacing.xs),
          ],
          SizedBox(
            width: icon == null ? 118 : 102,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: valueColor ?? SecurityColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class ConceptPill extends StatelessWidget {
  const ConceptPill({
    required this.label,
    super.key,
    this.foreground = SecurityColors.info,
    this.background = SecurityColors.infoSoft,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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

class ConceptPageBody extends StatelessWidget {
  const ConceptPageBody({
    required this.header,
    required this.children,
    super.key,
    this.footer,
  });

  final Widget header;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: SecuritySpacing.xs),
            child: header,
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.xs,
                SecuritySpacing.md,
                SecuritySpacing.xl,
              ),
              itemCount: children.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: SecuritySpacing.sm),
              itemBuilder: (context, index) => children[index],
            ),
          ),
          footer ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
