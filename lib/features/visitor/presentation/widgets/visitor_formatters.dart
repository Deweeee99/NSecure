import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations_x.dart';

abstract final class VisitorFormatters {
  static String text(String? value, {String fallback = '—'}) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? fallback : normalized;
  }

  static String date(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return MaterialLocalizations.of(context).formatMediumDate(value.toLocal());
  }

  static String time(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(value.toLocal()),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
  }

  static String dateTime(BuildContext context, DateTime? value) {
    if (value == null) return '—';
    return '${date(context, value)} • ${time(context, value)}';
  }

  static String unitAndTower(
    BuildContext context, {
    String? unitName,
    String? towerName,
  }) {
    final parts = <String>[];
    final unit = text(unitName, fallback: '');
    final tower = text(towerName, fallback: '');
    if (unit.isNotEmpty) parts.add('${context.l10n.unit} $unit');
    if (tower.isNotEmpty) parts.add(tower);
    return parts.isEmpty ? context.l10n.unitInformationUnavailable : parts.join(' • ');
  }
}
