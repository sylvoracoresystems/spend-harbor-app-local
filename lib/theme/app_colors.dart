import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.action,
    required this.actionHover,
    required this.actionInk,
    required this.mint,
    required this.mintSoft,
    required this.mintTint,
    required this.bgMint,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.textPrimary,
    required this.textBody,
    required this.textMuted,
    required this.textHint,
    required this.border,
    required this.borderSoft,
    required this.surfacePress,
    required this.surface,
  });

  final Color action;
  final Color actionHover;
  final Color actionInk;
  final Color mint;
  final Color mintSoft;
  final Color mintTint;
  final Color bgMint;

  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;

  final Color textPrimary;
  final Color textBody;
  final Color textMuted;
  final Color textHint;

  final Color border;
  final Color borderSoft;
  final Color surfacePress;
  final Color surface;

  static const light = AppColors(
    action: Color(0xFF10B981),
    actionHover: Color(0xFF059669),
    actionInk: Color(0xFF064E3B),
    mint: Color(0xFF7AE8A6),
    mintSoft: Color(0xFFE8FBF1),
    mintTint: Color(0xFFCFF5DD),
    bgMint: Color(0xFFF6FBF8),
    income: Color(0xFF19C17D),
    incomeSoft: Color(0xFFDCFCE7),
    expense: Color(0xFFF06262),
    expenseSoft: Color(0xFFFEE2E2),
    textPrimary: Color(0xFF0F172A),
    textBody: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    textHint: Color(0xFF94A3B8),
    border: Color(0xFFE2E8F0),
    borderSoft: Color(0xFFF1F5F9),
    surfacePress: Color(0xFFF1F5F9),
    surface: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    action: Color(0xFF10B981),
    actionHover: Color(0xFF34D399),
    actionInk: Color(0xFFA7F3D0),
    mint: Color(0xFF34D399),
    mintSoft: Color(0xFF064E3B),
    mintTint: Color(0xFF065F46),
    bgMint: Color(0xFF0B1410),
    income: Color(0xFF34D399),
    incomeSoft: Color(0xFF064E3B),
    expense: Color(0xFFF87171),
    expenseSoft: Color(0xFF7F1D1D),
    textPrimary: Color(0xFFE2E8F0),
    textBody: Color(0xFFCBD5E1),
    textMuted: Color(0xFF94A3B8),
    textHint: Color(0xFF64748B),
    border: Color(0xFF1E293B),
    borderSoft: Color(0xFF0F172A),
    surfacePress: Color(0xFF1E293B),
    surface: Color(0xFF111A16),
  );

  @override
  AppColors copyWith({
    Color? action,
    Color? actionHover,
    Color? actionInk,
    Color? mint,
    Color? mintSoft,
    Color? mintTint,
    Color? bgMint,
    Color? income,
    Color? incomeSoft,
    Color? expense,
    Color? expenseSoft,
    Color? textPrimary,
    Color? textBody,
    Color? textMuted,
    Color? textHint,
    Color? border,
    Color? borderSoft,
    Color? surfacePress,
    Color? surface,
  }) {
    return AppColors(
      action: action ?? this.action,
      actionHover: actionHover ?? this.actionHover,
      actionInk: actionInk ?? this.actionInk,
      mint: mint ?? this.mint,
      mintSoft: mintSoft ?? this.mintSoft,
      mintTint: mintTint ?? this.mintTint,
      bgMint: bgMint ?? this.bgMint,
      income: income ?? this.income,
      incomeSoft: incomeSoft ?? this.incomeSoft,
      expense: expense ?? this.expense,
      expenseSoft: expenseSoft ?? this.expenseSoft,
      textPrimary: textPrimary ?? this.textPrimary,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textHint: textHint ?? this.textHint,
      border: border ?? this.border,
      borderSoft: borderSoft ?? this.borderSoft,
      surfacePress: surfacePress ?? this.surfacePress,
      surface: surface ?? this.surface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      action: Color.lerp(action, other.action, t)!,
      actionHover: Color.lerp(actionHover, other.actionHover, t)!,
      actionInk: Color.lerp(actionInk, other.actionInk, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      mintTint: Color.lerp(mintTint, other.mintTint, t)!,
      bgMint: Color.lerp(bgMint, other.bgMint, t)!,
      income: Color.lerp(income, other.income, t)!,
      incomeSoft: Color.lerp(incomeSoft, other.incomeSoft, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      expenseSoft: Color.lerp(expenseSoft, other.expenseSoft, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textBody: Color.lerp(textBody, other.textBody, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderSoft: Color.lerp(borderSoft, other.borderSoft, t)!,
      surfacePress: Color.lerp(surfacePress, other.surfacePress, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;
}
