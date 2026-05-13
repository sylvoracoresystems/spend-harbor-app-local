import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../transactions/application/transactions_list_controller.dart';

/// 单一币种内的本月汇总。
class CurrencySummary {
  const CurrencySummary({
    required this.currency,
    required this.incomeCents,
    required this.expenseCents,
  });

  final String currency;
  final int incomeCents;
  final int expenseCents;

  int get netCents => incomeCents - expenseCents;
}

/// Dashboard 本月汇总。
///
/// 多币种**不换算**（硬约束）：按 currency 分行展示。
class DashboardSummary {
  const DashboardSummary({
    required this.byCurrency,
    required this.transactionCount,
  });

  final List<CurrencySummary> byCurrency;
  final int transactionCount;

  bool get isEmpty => transactionCount == 0;
}

/// 把交易聚合为 [DashboardSummary]。
DashboardSummary aggregateSummary(List<Transaction> rows) {
  final byCcy = <String, ({int income, int expense})>{};
  for (final t in rows) {
    final prev = byCcy[t.currency] ?? (income: 0, expense: 0);
    byCcy[t.currency] = t.type == TransactionType.income
        ? (income: prev.income + t.amountCents, expense: prev.expense)
        : (income: prev.income, expense: prev.expense + t.amountCents);
  }
  // 币种排序：CAD 优先，然后按 code 字母序，保证渲染稳定。
  final codes = byCcy.keys.toList()
    ..sort((a, b) {
      if (a == 'CAD') return -1;
      if (b == 'CAD') return 1;
      return a.compareTo(b);
    });
  return DashboardSummary(
    byCurrency: [
      for (final code in codes)
        CurrencySummary(
          currency: code,
          incomeCents: byCcy[code]!.income,
          expenseCents: byCcy[code]!.expense,
        ),
    ],
    transactionCount: rows.length,
  );
}

final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  return ref.watch(transactionsOfMonthProvider).whenData(aggregateSummary);
});

/// 近期交易（按 transactedOn 降序，截取前 N 条）。
final recentTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  return ref
      .watch(transactionsOfMonthProvider)
      .whenData((rows) => rows.take(10).toList());
});
