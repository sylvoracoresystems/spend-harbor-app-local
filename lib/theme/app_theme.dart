import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.action,
      onPrimary: Colors.white,
      secondary: c.mint,
      onSecondary: c.actionInk,
      error: c.expense,
      onError: Colors.white,
      surface: c.surface,
      onSurface: c.textBody,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: c.bgMint,
      colorScheme: colorScheme,
      textTheme: AppTypography.buildTextTheme(c.textBody, c.actionInk),
      dividerColor: c.borderSoft,
      cardColor: c.surface,
      iconTheme: IconThemeData(color: c.textMuted),
      appBarTheme: AppBarTheme(
        backgroundColor: c.bgMint,
        foregroundColor: c.actionInk,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.lg.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: c.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: c.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: c.action, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brLg,
          borderSide: BorderSide(color: c.expense),
        ),
        hintStyle: AppTypography.sm.copyWith(color: c.textHint),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.action,
          foregroundColor: Colors.white,
          disabledBackgroundColor: c.action.withValues(alpha: 0.5),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
          textStyle:
              AppTypography.sm.copyWith(fontWeight: AppTypography.weightSemibold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.action,
          side: BorderSide(color: c.action),
          minimumSize: const Size(0, 40),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
          textStyle:
              AppTypography.sm.copyWith(fontWeight: AppTypography.weightSemibold),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.action,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textStyle:
              AppTypography.sm.copyWith(fontWeight: AppTypography.weightSemibold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.action,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXxl),
        elevation: 0,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? c.surfacePress : c.actionInk,
        contentTextStyle: AppTypography.sm.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brXl),
      ),
      dividerTheme: DividerThemeData(
        color: c.borderSoft,
        thickness: 1,
        space: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[c],
    );
  }
}
