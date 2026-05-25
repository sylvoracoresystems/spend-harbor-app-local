import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../dashboard/application/dashboard_filter_provider.dart';

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

/// 临时筛选：支持单日、日期区间、分类、标签、无标签、账户来源。
class TransactionsFilter {
  const TransactionsFilter({
    this.dayIso,
    this.dateStartIso,
    this.dateEndIso,
    this.categoryId,
    this.tagId,
    this.untagged = false,
    this.sourceId,
  });
  final String? dayIso;
  final String? dateStartIso;
  final String? dateEndIso;
  final String? categoryId;
  final String? tagId;
  final bool untagged;
  final String? sourceId;

  bool get isEmpty =>
      dayIso == null &&
      dateStartIso == null &&
      dateEndIso == null &&
      categoryId == null &&
      tagId == null &&
      !untagged &&
      sourceId == null;

  /// 是否携带完整的日期区间（由 query 层处理，不在 matches 中重复过滤）。
  bool get hasDateRange => dateStartIso != null && dateEndIso != null;

  /// [tagIds] 为当前行关联的标签 id 集合（可为 null 表示未加载）。
  bool matches(Transaction t, {Set<String>? tagIds}) {
    if (dayIso != null && t.transactedOn != dayIso) return false;
    if (categoryId != null && t.categoryId != categoryId) return false;
    if (sourceId != null && t.sourceId != sourceId) return false;
    if (tagId != null && (tagIds == null || !tagIds.contains(tagId))) {
      return false;
    }
    if (untagged && (tagIds != null && tagIds.isNotEmpty)) return false;
    return true;
  }
}

/// 临时筛选状态（从 Stats 跳转时设置，TransactionsPage 顶部 chip 可清除）。
final transactionsFilterProvider =
    StateProvider<TransactionsFilter?>((ref) => null);

/// 当前月份内的交易（date-range 模式下按区间查询，否则按月查询）。
final transactionsOfMonthProvider = StreamProvider<List<Transaction>>((ref) {
  final filter = ref.watch(transactionsFilterProvider);
  final dao = ref.watch(transactionDaoProvider);
  if (filter != null && filter.hasDateRange) {
    return dao.watchBetween(filter.dateStartIso!, filter.dateEndIso!);
  }
  final ym = ref.watch(currentMonthProvider);
  return dao.watchByMonth(ym.key);
});

/// 月份切换时自动清空筛选（date-range 模式下保持不变）。
final _monthChangeListenerProvider = Provider<void>((ref) {
  ref.listen(currentMonthProvider, (_, __) {
    final cur = ref.read(transactionsFilterProvider);
    if (cur != null && cur.hasDateRange) return; // 保持区间模式
    ref.read(transactionsFilterProvider.notifier).state = null;
  });
});

/// 预加载当前列表所有交易的标签关联。
final tagsForCurrentListProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final rows = await ref.watch(transactionsOfMonthProvider.future);
  if (rows.isEmpty) return const {};
  return ref
      .watch(transactionDaoProvider)
      .tagIdsForMany(rows.map((r) => r.id).toList());
});

/// 月份内交易经过 filter 后的视图（支持标签过滤）。
final filteredTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  ref.watch(_monthChangeListenerProvider);
  final filter = ref.watch(transactionsFilterProvider);
  final dash = ref.watch(dashboardFilterProvider);
  final txAsync = ref.watch(transactionsOfMonthProvider);

  bool dashMatches(Transaction t) {
    if (dash.currency != null && t.currency != dash.currency) return false;
    if (dash.sourceId != null && t.sourceId != dash.sourceId) return false;
    return true;
  }

  final filterEmpty = filter == null || filter.isEmpty;
  final needsTags = !filterEmpty && (filter.tagId != null || filter.untagged);
  if (!needsTags) {
    return txAsync.whenData((rows) => rows
        .where((t) => dashMatches(t) && (filterEmpty || filter.matches(t)))
        .toList());
  }
  final tagsAsync = ref.watch(tagsForCurrentListProvider);
  if (tagsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }
  if (tagsAsync is AsyncError) {
    return AsyncValue.error(tagsAsync.error!, tagsAsync.stackTrace ?? StackTrace.empty);
  }
  final tagsByTx = tagsAsync.value ?? const <String, List<String>>{};
  return txAsync.whenData((rows) {
    return rows
        .where((t) =>
            dashMatches(t) &&
            filter.matches(t, tagIds: tagsByTx[t.id]?.toSet()))
        .toList();
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

/// [filteredTransactionsProvider] 的派生：按日分组后的结果。
///
/// 走 provider 而非每次 build 内调用 [groupByDay]，避免选择模式 toggle 等
/// 与列表数据无关的重建也触发 O(rows) 的分组+排序+DateTime.parse。
final groupedTransactionsProvider =
    Provider<AsyncValue<List<DayGroup>>>((ref) {
  return ref.watch(filteredTransactionsProvider).whenData(groupByDay);
});

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
