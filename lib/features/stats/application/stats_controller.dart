import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
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

/// 单组占比切片（用于 Donut）。
class CategorySlice {
  const CategorySlice({
    required this.categoryId,
    required this.totalCents,
  });
  final String categoryId;
  final int totalCents;
}

class TagSlice {
  const TagSlice({required this.tagId, required this.totalCents});
  final String tagId;
  final int totalCents;
}

/// 按分类聚合（指定币种 + expense）。降序返回。
List<CategorySlice> aggregateByCategory(
  List<Transaction> rows, {
  required String currency,
}) {
  final totals = <String, int>{};
  for (final t in rows) {
    if (t.type != TransactionType.expense) continue;
    if (t.currency != currency) continue;
    totals[t.categoryId] =
        (totals[t.categoryId] ?? 0) + t.amountCents;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries)
      CategorySlice(categoryId: e.key, totalCents: e.value),
  ];
}

/// 按标签聚合（指定币种 + expense）。
///
/// 一笔交易可能挂多个标签，按完整金额累加到每个 tagId（不平分）。
/// [tagIdsByTx] 形如 `transactionId → [tagId,...]`。
List<TagSlice> aggregateByTag(
  List<Transaction> rows, {
  required String currency,
  required Map<String, List<String>> tagIdsByTx,
}) {
  final totals = <String, int>{};
  for (final t in rows) {
    if (t.type != TransactionType.expense) continue;
    if (t.currency != currency) continue;
    final tagIds = tagIdsByTx[t.id] ?? const <String>[];
    for (final tagId in tagIds) {
      totals[tagId] = (totals[tagId] ?? 0) + t.amountCents;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [
    for (final e in entries)
      TagSlice(tagId: e.key, totalCents: e.value),
  ];
}

/// 当月分类切片（按 dominant 币种）。
final categorySlicesProvider = FutureProvider<List<CategorySlice>>((ref) async {
  final rows = await ref.watch(transactionsOfMonthProvider.future);
  final bars = aggregateDailyExpenses(
    rows,
    year: ref.watch(currentMonthProvider).year,
    month: ref.watch(currentMonthProvider).month,
  );
  final ccy = dominantCurrency(bars);
  return aggregateByCategory(rows, currency: ccy);
});

/// 当月标签切片（按 dominant 币种）。
final tagSlicesProvider = FutureProvider<List<TagSlice>>((ref) async {
  final rows = await ref.watch(transactionsOfMonthProvider.future);
  if (rows.isEmpty) return const <TagSlice>[];
  final dao = ref.watch(transactionDaoProvider);
  final tagsByTx = await dao.tagIdsForMany(rows.map((r) => r.id).toList());
  final bars = aggregateDailyExpenses(
    rows,
    year: ref.watch(currentMonthProvider).year,
    month: ref.watch(currentMonthProvider).month,
  );
  final ccy = dominantCurrency(bars);
  return aggregateByTag(rows, currency: ccy, tagIdsByTx: tagsByTx);
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
