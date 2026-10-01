import 'package:flutter/material.dart';

/// Visual tokens interpreted from the two Aparthub Security source-of-truth
/// presentation panels. Exact brand values can be adjusted later if an
/// official design token export is provided.
abstract final class SecurityColors {
  static const primary = Color(0xFF073096);
  static const primaryDeep = Color(0xFF082556);
  static const primarySoft = Color(0xFFEAF0FF);
  static const accent = Color(0xFF2F65D9);

  static const background = Color(0xFFF6F8FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFD);
  static const border = Color(0xFFE2E7F0);

  static const textPrimary = Color(0xFF10224B);
  static const textSecondary = Color(0xFF4D5B78);
  static const textMuted = Color(0xFF7C879F);

  static const success = Color(0xFF22A447);
  static const successSoft = Color(0xFFEAF8EE);
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF5DF);
  static const danger = Color(0xFFE34949);
  static const dangerSoft = Color(0xFFFFECEC);
  static const info = Color(0xFF2F65D9);
  static const infoSoft = Color(0xFFEAF0FF);
}

abstract final class SecuritySpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class SecurityRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
}

abstract final class SecurityShadows {
  static const soft = <BoxShadow>[
    BoxShadow(
      color: Color(0x140D2A66),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];
}
