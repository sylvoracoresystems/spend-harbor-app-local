import 'package:flutter/material.dart';

import '../../domain/enums/transaction_type.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_typography.dart';

/// Expense / Income 胶囊式切换：在交易表单、分类编辑等处共用。
class TransactionTypeToggle extends StatelessWidget {
  const TransactionTypeToggle({
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.borderSoft,
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        children: [
          Expanded(
            child: _Seg(
              label: l.txTypeExpense,
              active: value == TransactionType.expense,
              activeColor: c.expense,
              onTap: () => onChanged(TransactionType.expense),
            ),
          ),
          Expanded(
            child: _Seg(
              label: l.txTypeIncome,
              active: value == TransactionType.income,
              activeColor: c.income,
              onTap: () => onChanged(TransactionType.income),
            ),
          ),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.brFull,
        onTap: onTap,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? activeColor : Colors.transparent,
            borderRadius: AppRadius.brFull,
          ),
          child: Text(
            label,
            style: AppTypography.sm.copyWith(
              fontWeight: AppTypography.weightSemibold,
              color: active ? Colors.white : c.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
