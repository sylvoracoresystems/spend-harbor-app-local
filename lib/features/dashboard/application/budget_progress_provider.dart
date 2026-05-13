import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/budget_scope.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../budgets/application/budget_form_controller.dart';
import '../../budgets/application/budget_period_alignment.dart';

/// 单条预算的本期进度。
class BudgetProgress {
  const BudgetProgress({
    required this.budget,
    required this.spentCents,
  });

  final Budget budget;
  final int spentCents;

  double get ratio {
    if (budget.amountCents <= 0) return 0;
    return spentCents / budget.amountCents;
  }

  bool get overBudget => spentCents > budget.amountCents;
}

/// 根据「本期窗口内的全部交易」+ 单条预算，算出已花金额。
///
/// 规则：
/// - 只计 `type == expense`
/// - currency 必须匹配
/// - scope=category 时仅累加同 categoryId
int spentForBudget(Budget budget, List<Transaction> txs) {
  return txs
      .where((t) =>
          t.type == TransactionType.expense &&
          t.currency == budget.currency &&
          (budget.scope == BudgetScope.total ||
              t.categoryId == budget.categoryId))
      .fold<int>(0, (acc, t) => acc + t.amountCents);
}

/// 各预算本期进度。每条预算单独按其 period 决定窗口起止。
final budgetProgressListProvider =
    FutureProvider<List<BudgetProgress>>((ref) async {
  final budgets = await ref.watch(allBudgetsProvider.future);
  if (budgets.isEmpty) return const <BudgetProgress>[];

  final dao = ref.watch(transactionDaoProvider);
  final now = DateTime.now();
  final results = <BudgetProgress>[];
  for (final b in budgets) {
    final start = alignToPeriodStart(now, b.period);
    final end = periodEndOn(now, b.period);
    final txs = await dao
        .watchBetween(formatIsoDate(start), formatIsoDate(end))
        .first;
    results.add(BudgetProgress(
      budget: b,
      spentCents: spentForBudget(b, txs),
    ));
  }
  return results;
});
