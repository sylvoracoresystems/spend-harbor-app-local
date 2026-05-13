import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/enums/transaction_type.dart';
import '../../transactions/application/transactions_list_controller.dart';

/// 当月一日的支出聚合：用于趋势柱状图。
class DailyExpenseBar {
  const DailyExpenseBar({required this.day, required this.byCurrency});

  /// 当月 1..N
  final int day;

  /// 同一日按币种分桶，避免换算。
  final Map<String, int> byCurrency;

  int totalCentsForCurrency(String code) => byCurrency[code] ?? 0;
}

/// 把交易按 `transactedOn` 的「日」聚合为 [DailyExpenseBar] 列表（1..daysInMonth）。
List<DailyExpenseBar> aggregateDailyExpenses(
  List<Transaction> rows, {
  required int year,
  required int month,
}) {
  final daysInMonth = DateTime(
    month == 12 ? year + 1 : year,
    month == 12 ? 1 : month + 1,
    1,
  ).subtract(const Duration(days: 1)).day;

  final buckets = <int, Map<String, int>>{
    for (var d = 1; d <= daysInMonth; d++) d: <String, int>{},
  };
  for (final t in rows) {
    if (t.type != TransactionType.expense) continue;
    final parts = t.transactedOn.split('-');
    final d = int.tryParse(parts.last);
    if (d == null || d < 1 || d > daysInMonth) continue;
    final byCcy = buckets[d]!;
    byCcy[t.currency] = (byCcy[t.currency] ?? 0) + t.amountCents;
  }
  return [
    for (var d = 1; d <= daysInMonth; d++)
      DailyExpenseBar(day: d, byCurrency: buckets[d]!),
  ];
}

/// 当月趋势数据。
final dailyExpenseBarsProvider = Provider<AsyncValue<List<DailyExpenseBar>>>((
  ref,
) {
  final ym = ref.watch(currentMonthProvider);
  return ref.watch(transactionsOfMonthProvider).whenData(
        (rows) =>
            aggregateDailyExpenses(rows, year: ym.year, month: ym.month),
      );
});

/// 主币种：聚合中数据最多的币种；都为空时返回 'CAD'。
String dominantCurrency(List<DailyExpenseBar> bars) {
  final totals = <String, int>{};
  for (final b in bars) {
    b.byCurrency.forEach((k, v) {
      totals[k] = (totals[k] ?? 0) + v;
    });
  }
  if (totals.isEmpty) return 'CAD';
  final sorted = totals.entries.toList()
    ..sort((a, b) {
      if (a.key == 'CAD') return -1;
      if (b.key == 'CAD') return 1;
      return b.value.compareTo(a.value);
    });
  return sorted.first.key;
}
