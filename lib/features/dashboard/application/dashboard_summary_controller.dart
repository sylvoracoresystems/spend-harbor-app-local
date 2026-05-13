import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../transactions/application/transactions_list_controller.dart';
import 'dashboard_filter_provider.dart';

/// 单一币种内的当期汇总。
class CurrencySummary {
  const CurrencySummary({
    required this.currency,
    required this.incomeCents,
    required this.expenseCents,
    required this.count,
  });

  final String currency;
  final int incomeCents;
  final int expenseCents;
  final int count;

  int get netCents => incomeCents - expenseCents;
}

/// 多币种汇总（不换算）。按 currency 分行。
class DashboardSummary {
  const DashboardSummary({
    required this.byCurrency,
    required this.transactionCount,
  });

  final List<CurrencySummary> byCurrency;
  final int transactionCount;

  bool get isEmpty => transactionCount == 0;
}

/// 卡片视图模型：从 [DashboardSummary] 派生出「主币种 + 其它币种数量」。
///
/// - 单币种过滤时 dominantCurrency = 过滤的币种；otherCurrencyCount = 0
/// - 全部货币 + 多币种数据时：dominantCurrency = 笔数最多的币种；
///   otherCurrencyCount = 剩余币种种类数
/// - 无数据时：dominantCurrency = null
class DashboardMetrics {
  const DashboardMetrics({
    required this.dominantCurrency,
    required this.incomeCents,
    required this.expenseCents,
    required this.netCents,
    required this.otherCurrencyCount,
    required this.transactionCount,
  });

  final String? dominantCurrency;
  final int incomeCents;
  final int expenseCents;
  final int netCents;
  final int otherCurrencyCount;
  final int transactionCount;

  bool get isEmpty => transactionCount == 0;
  bool get hasOthers => otherCurrencyCount > 0;
}

/// 按过滤条件筛选交易（纯函数，便于测试）。
List<Transaction> applyDashboardFilter(
  List<Transaction> rows,
  DashboardFilter filter,
) {
  return rows.where((t) {
    if (filter.currency != null && t.currency != filter.currency) return false;
    if (filter.sourceId != null && t.sourceId != filter.sourceId) return false;
    return true;
  }).toList();
}

/// 把交易聚合为 [DashboardSummary]（按币种分行，CAD 优先 + 字母序）。
DashboardSummary aggregateSummary(List<Transaction> rows) {
  final byCcy = <String, ({int income, int expense, int count})>{};
  for (final t in rows) {
    final prev = byCcy[t.currency] ?? (income: 0, expense: 0, count: 0);
    byCcy[t.currency] = t.type == TransactionType.income
        ? (
            income: prev.income + t.amountCents,
            expense: prev.expense,
            count: prev.count + 1,
          )
        : (
            income: prev.income,
            expense: prev.expense + t.amountCents,
            count: prev.count + 1,
          );
  }
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
          count: byCcy[code]!.count,
        ),
    ],
    transactionCount: rows.length,
  );
}

/// 从 [DashboardSummary] 派生卡片视图：主币种 = 笔数最多的币种。
DashboardMetrics toMetrics(DashboardSummary s) {
  if (s.byCurrency.isEmpty) {
    return const DashboardMetrics(
      dominantCurrency: null,
      incomeCents: 0,
      expenseCents: 0,
      netCents: 0,
      otherCurrencyCount: 0,
      transactionCount: 0,
    );
  }
  // 笔数降序；同笔数下保持 aggregateSummary 已确定的顺序（CAD 优先 + 字母序）。
  final sorted = [...s.byCurrency]
    ..sort((a, b) => b.count.compareTo(a.count));
  final top = sorted.first;
  return DashboardMetrics(
    dominantCurrency: top.currency,
    incomeCents: top.incomeCents,
    expenseCents: top.expenseCents,
    netCents: top.netCents,
    otherCurrencyCount: s.byCurrency.length - 1,
    transactionCount: s.transactionCount,
  );
}

/// 当前月份内、按 dashboard filter 过滤后的交易。
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref
      .watch(transactionsOfMonthProvider)
      .whenData((rows) => applyDashboardFilter(rows, filter));
});

/// Dashboard 4 张卡用的视图模型。
final dashboardMetricsProvider =
    Provider<AsyncValue<DashboardMetrics>>((ref) {
  return ref.watch(filteredTransactionsProvider).whenData(
        (rows) => toMetrics(aggregateSummary(rows)),
      );
});

/// 兼容旧 API：完整 byCurrency 汇总（widget 或 test 仍可能用到）。
final dashboardSummaryProvider = Provider<AsyncValue<DashboardSummary>>((ref) {
  return ref
      .watch(filteredTransactionsProvider)
      .whenData(aggregateSummary);
});

/// 近期交易（按 transactedOn 降序、截取前 10 条；过滤生效）。
final recentTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  return ref
      .watch(filteredTransactionsProvider)
      .whenData((rows) => rows.take(10).toList());
});
