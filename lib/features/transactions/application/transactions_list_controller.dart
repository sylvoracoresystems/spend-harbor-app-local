import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';

/// 年-月 值对象（YYYY-MM）。
class YearMonth {
  const YearMonth(this.year, this.month)
      : assert(month >= 1 && month <= 12);

  factory YearMonth.now() {
    final n = DateTime.now();
    return YearMonth(n.year, n.month);
  }

  factory YearMonth.parse(String yyyyMm) {
    final parts = yyyyMm.split('-');
    return YearMonth(int.parse(parts[0]), int.parse(parts[1]));
  }

  final int year;
  final int month;

  String get key =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';

  YearMonth next() =>
      month == 12 ? YearMonth(year + 1, 1) : YearMonth(year, month + 1);

  YearMonth prev() =>
      month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}

/// 当前查看月份；默认当月。可由 URL query 与 UI 双向控制。
class CurrentMonthController extends StateNotifier<YearMonth> {
  CurrentMonthController() : super(YearMonth.now());

  void set(YearMonth m) => state = m;
  void next() => state = state.next();
  void prev() => state = state.prev();
}

final currentMonthProvider =
    StateNotifierProvider<CurrentMonthController, YearMonth>(
  (ref) => CurrentMonthController(),
);

/// 当前月份内的交易（按日期降序）。
final transactionsOfMonthProvider = StreamProvider<List<Transaction>>((ref) {
  final ym = ref.watch(currentMonthProvider);
  return ref.watch(transactionDaoProvider).watchByMonth(ym.key);
});

/// 临时筛选：单日 / 单分类，二选一或都为 null。
class TransactionsFilter {
  const TransactionsFilter({this.dayIso, this.categoryId});
  final String? dayIso;
  final String? categoryId;

  bool get isEmpty => dayIso == null && categoryId == null;

  bool matches(Transaction t) {
    if (dayIso != null && t.transactedOn != dayIso) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    return true;
  }
}

/// 临时筛选状态（从 Stats 跳转时设置，TransactionsPage 顶部 chip 可清除）。
final transactionsFilterProvider =
    StateProvider<TransactionsFilter?>((ref) => null);

/// 月份切换时自动清空筛选（避免月外 day 残留）。
final _monthChangeListenerProvider = Provider<void>((ref) {
  ref.listen(currentMonthProvider, (_, __) {
    ref.read(transactionsFilterProvider.notifier).state = null;
  });
});

/// 月份内交易经过 filter 后的视图。
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  ref.watch(_monthChangeListenerProvider);
  final filter = ref.watch(transactionsFilterProvider);
  return ref.watch(transactionsOfMonthProvider).whenData((rows) {
    if (filter == null || filter.isEmpty) return rows;
    return rows.where(filter.matches).toList();
  });
});

/// DayGroup：同一日期的交易聚合。
class DayGroup {
  const DayGroup({
    required this.date,
    required this.items,
  });
  final DateTime date;
  final List<Transaction> items;
}

/// 交易列表选择模式状态：空集 = 未进入选择模式。
class SelectionController extends StateNotifier<Set<String>> {
  SelectionController() : super(const <String>{});

  bool get isActive => state.isNotEmpty;

  void toggle(String id) {
    final next = {...state};
    if (!next.add(id)) next.remove(id);
    state = next;
  }

  void clear() => state = const <String>{};
}

final selectionControllerProvider =
    StateNotifierProvider<SelectionController, Set<String>>(
  (ref) => SelectionController(),
);

/// 把交易按 `transactedOn` 分组，日期降序。
List<DayGroup> groupByDay(List<Transaction> rows) {
  final byDate = <String, List<Transaction>>{};
  for (final r in rows) {
    byDate.putIfAbsent(r.transactedOn, () => []).add(r);
  }
  final keys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final k in keys)
      DayGroup(date: DateTime.parse(k), items: byDate[k]!),
  ];
}
