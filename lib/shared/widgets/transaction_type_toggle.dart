import 'package:flutter/material.dart';

import '../../domain/enums/transaction_type.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/app_colors.dart';
import 'pill_segmented.dart';

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
    return PillToggle<TransactionType>(
      value: value,
      first: PillToggleOption(
        value: TransactionType.expense,
        label: l.txTypeExpense,
        activeColor: c.expense,
      ),
      second: PillToggleOption(
        value: TransactionType.income,
        label: l.txTypeIncome,
        activeColor: c.income,
      ),
      onChanged: onChanged,
    );
  }
}
