import 'package:flutter/material.dart';

import '../../../../domain/enums/transaction_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// 胶囊式 expense / income 切换。
///
/// 整体一颗圆角 999 的胶囊，两半按下后用语义色填充（expense→红、income→绿），
/// 未选中半边背景透明、文字 muted。
class TypePillToggle extends StatelessWidget {
  const TypePillToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.surfacePress,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Half(
            label: l.statsTypeExpense,
            active: value == TransactionType.expense,
            activeColor: c.expense,
            mutedColor: c.textMuted,
            onTap: () => onChanged(TransactionType.expense),
          ),
          _Half(
            label: l.statsTypeIncome,
            active: value == TransactionType.income,
            activeColor: c.income,
            mutedColor: c.textMuted,
            onTap: () => onChanged(TransactionType.income),
          ),
        ],
      ),
    );
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.mutedColor,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color activeColor;
  final Color mutedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTypography.xs.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: active ? Colors.white : mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}
