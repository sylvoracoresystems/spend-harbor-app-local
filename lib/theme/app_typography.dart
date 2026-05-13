import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  static const FontWeight weightNormal = FontWeight.w400;
  static const FontWeight weightMedium = FontWeight.w500;
  static const FontWeight weightSemibold = FontWeight.w600;
  static const FontWeight weightBold = FontWeight.w700;

  static const TextStyle xs = TextStyle(fontSize: 12, height: 16 / 12);
  static const TextStyle sm = TextStyle(fontSize: 14, height: 20 / 14);
  static const TextStyle base = TextStyle(fontSize: 16, height: 24 / 16);
  static const TextStyle lg = TextStyle(fontSize: 18, height: 28 / 18);
  static const TextStyle xl = TextStyle(fontSize: 20, height: 28 / 20);
  static const TextStyle xxl = TextStyle(fontSize: 24, height: 32 / 24);
  static const TextStyle xxxl = TextStyle(fontSize: 30, height: 36 / 30);

  static const List<FontFeature> monoFeatures = [FontFeature.tabularFigures()];

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: monoFeatures,
  );

  static TextTheme buildTextTheme(Color body, Color strong) {
    return TextTheme(
      displayLarge: xxxl.copyWith(color: strong, fontWeight: weightSemibold),
      displayMedium: xxl.copyWith(color: strong, fontWeight: weightSemibold),
      headlineMedium: xl.copyWith(color: strong, fontWeight: weightSemibold),
      titleLarge: lg.copyWith(color: strong, fontWeight: weightSemibold),
      titleMedium: base.copyWith(color: body, fontWeight: weightMedium),
      bodyLarge: base.copyWith(color: body),
      bodyMedium: sm.copyWith(color: body),
      bodySmall: xs.copyWith(color: body),
      labelLarge: sm.copyWith(color: body, fontWeight: weightSemibold),
      labelMedium: xs.copyWith(color: body, fontWeight: weightMedium),
    );
  }
}
