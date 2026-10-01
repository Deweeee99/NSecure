import 'package:flutter/material.dart';

import 'security_tokens.dart';

abstract final class SecurityTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: SecurityColors.primary,
      onPrimary: Colors.white,
      secondary: SecurityColors.accent,
      onSecondary: Colors.white,
      surface: SecurityColors.surface,
      onSurface: SecurityColors.textPrimary,
      error: SecurityColors.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SecurityColors.background,
      dividerColor: SecurityColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: SecurityColors.surface,
        foregroundColor: SecurityColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: SecurityColors.surface,
        selectedItemColor: SecurityColors.primary,
        unselectedItemColor: SecurityColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SecurityColors.primaryDeep,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SecurityRadius.md),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          color: SecurityColors.textPrimary,
          fontSize: 24,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: SecurityColors.textPrimary,
          fontSize: 20,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: SecurityColors.textPrimary,
          fontSize: 16,
          height: 1.35,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: SecurityColors.textPrimary,
          fontSize: 16,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          color: SecurityColors.textSecondary,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: SecurityColors.textMuted,
          fontSize: 12,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: SecurityColors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
        labelMedium: TextStyle(
          color: SecurityColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SecurityColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: SecuritySpacing.md,
          vertical: SecuritySpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SecurityRadius.md),
          borderSide: const BorderSide(color: SecurityColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SecurityRadius.md),
          borderSide: const BorderSide(color: SecurityColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(SecurityRadius.md),
          borderSide: const BorderSide(
            color: SecurityColors.primary,
            width: 1.4,
          ),
        ),
      ),
    );
  }
}
