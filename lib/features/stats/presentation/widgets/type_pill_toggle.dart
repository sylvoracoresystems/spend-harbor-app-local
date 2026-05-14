import 'package:flutter/material.dart';

import '../../../../domain/enums/transaction_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_typography.dart';

/// 胶囊式 expense / income 切换，带滑动 thumb。
///
/// 外层 `surfacePress` 软底胶囊（borderRadius 999 + borderSoft 描边），
/// 内部 thumb 通过 AnimatedAlign 在左右两半间 200ms 缓动滑动；
/// thumb 颜色随语义变化（expense→红、income→绿），文字白色；
/// 未选中半边透明、文字 muted。两半固定为 `max(label 宽度)`，
/// 保证 thumb 与文字始终对齐（en/zh 字宽差异不影响）。
class TypePillToggle extends StatelessWidget {
  const TypePillToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final TransactionType value;
  final ValueChanged<TransactionType> onChanged;

  static const double _height = 30;
  static const double _inset = 2;
  static const double _hPad = 14;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final isExpense = value == TransactionType.expense;
    final thumbColor = isExpense ? c.expense : c.income;
    final textStyle = AppTypography.xs.copyWith(
      fontWeight: AppTypography.weightSemibold,
    );
    final scaler = MediaQuery.textScalerOf(context);

    final halfW = _maxLabelWidth(
      [l.statsTypeExpense, l.statsTypeIncome],
      textStyle,
      scaler,
    ) + _hPad * 2;

    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: c.surfacePress,
        border: Border.all(color: c.borderSoft),
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        width: halfW * 2,
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment:
                  isExpense ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: thumbColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _Half(
                    label: l.statsTypeExpense,
                    active: isExpense,
                    style: textStyle,
                    onTap: () => onChanged(TransactionType.expense),
                  ),
                ),
                Expanded(
                  child: _Half(
                    label: l.statsTypeIncome,
                    active: !isExpense,
                    style: textStyle,
                    onTap: () => onChanged(TransactionType.income),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _maxLabelWidth(
    List<String> labels,
    TextStyle style,
    TextScaler scaler,
  ) {
    double max = 0;
    for (final text in labels) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      if (tp.width > max) max = tp.width;
    }
    return max;
  }
}

class _Half extends StatelessWidget {
  const _Half({
    required this.label,
    required this.active,
    required this.style,
    required this.onTap,
  });

  final String label;
  final bool active;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            style: style.copyWith(
              color: active ? Colors.white : c.textMuted,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
