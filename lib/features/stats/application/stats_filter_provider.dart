import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database_provider.dart';
import '../../../shared/providers/preferences_provider.dart';
import '../../settings/application/default_currency_provider.dart';
import 'stats_buckets.dart';
import 'stats_filter.dart';

const _kPrefsCurrencyKey = 'stats.lastCurrency';

/// 初始过滤器：period=month，桶 = 今天所在月一号。
StatsFilter initialFilter({
  required String currency,
  required DateTime today,
}) {
  final monthStart = alignToPeriodStart(today, StatsPeriod.month);
  return StatsFilter(
    currency: currency,
    period: StatsPeriod.month,
    selectedBucketStart: monthStart,
    rememberedMonthAnchor: monthStart,
    rememberedYearAnchor: alignToPeriodStart(today, StatsPeriod.year),
  );
}

/// 点击桶时的状态过渡。
StatsFilter applySelectBucket(StatsFilter f, DateTime start) {
  switch (f.period) {
    case StatsPeriod.month:
      return f.copyWith(
        selectedBucketStart: start,
        rememberedMonthAnchor: start,
      );
    case StatsPeriod.year:
      return f.copyWith(
        selectedBucketStart: start,
        rememberedYearAnchor: start,
      );
    case StatsPeriod.week:
      return f.copyWith(selectedBucketStart: start);
  }
}

/// 切换 Period 时推导新 anchor，应用上下文记忆。
StatsFilter applySetPeriod(
  StatsFilter f,
  StatsPeriod p, {
  required DateTime today,
}) {
  final anchor = alignToPeriodStart(today, p);
  return f.copyWith(period: p, selectedBucketStart: anchor);
}

/// 切换 currency 时，根据回调判断 source 是否兼容新币种。
StatsFilter applySetCurrency(
  StatsFilter f,
  String currency, {
  required bool Function(String sourceId, String currency) sourceBelongsToCurrency,
}) {
  final sid = f.sourceId;
  if (sid == null) {
    return f.copyWith(currency: currency);
  }
  final keep = sourceBelongsToCurrency(sid, currency);
  return f.copyWith(
    currency: currency,
    sourceId: keep ? sid : null,
  );
}

/// 管理 Stats 过滤条件：周期切换、桶位移、币种/来源选择 + 切换锚点记忆。
class StatsFilterController extends StateNotifier<StatsFilter> {
  StatsFilterController(this._ref, StatsFilter seed) : super(seed);

  final Ref _ref;

  /// 内部：异步初始化结束后更新 currency。
  void _setCurrencyInternal(String c) {
    state = state.copyWith(currency: c);
  }

  void setPeriod(StatsPeriod p) {
    state = applySetPeriod(state, p, today: DateTime.now());
  }

  void selectBucket(DateTime start) {
    state = applySelectBucket(state, start);
  }

  void setCurrency(String c) {
    state = applySetCurrency(
      state,
      c,
      sourceBelongsToCurrency: (id, ccy) {
        final sources = _ref.read(allSourcesProvider).valueOrNull;
        if (sources == null) return false;
        for (final s in sources) {
          if (s.id == id) return s.currency == ccy;
        }
        return false;
      },
    );
    final prefs = _ref.read(sharedPreferencesProvider);
    prefs.setString(_kPrefsCurrencyKey, c); // 异步但不需要 await
  }

  void setSourceId(String? id) {
    state = state.copyWith(sourceId: id);
  }

  /// 把选中桶重置为当前 period 下包含 today 的桶（month → 本月一号 / week → 本周一 / year → 今年）。
  void snapSelectionToToday() {
    final today = DateTime.now();
    final start = alignToPeriodStart(today, state.period);
    state = applySelectBucket(state, start);
  }
}

/// `statsFilterProvider`：同步种子用 defaultCurrencyProvider；启动后异步解析真实 currency。
final statsFilterProvider =
    StateNotifierProvider<StatsFilterController, StatsFilter>((ref) {
  final defaultCcy = ref.read(defaultCurrencyProvider);
  final seed = initialFilter(currency: defaultCcy, today: DateTime.now());
  final ctrl = StatsFilterController(ref, seed);
  final initialMonthStart = seed.selectedBucketStart;
  Future.microtask(() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_kPrefsCurrencyKey);
    if (saved != null && saved.isNotEmpty) {
      ctrl._setCurrencyInternal(saved);
      return;
    }
    // 用当前选中桶（本月）的交易记录推断最常用币种。
    final dao = ref.read(transactionDaoProvider);
    final monthStart = initialMonthStart;
    final monthEnd = DateTime(monthStart.year, monthStart.month + 1, 0);
    final rows = await dao.findByDateRange(isoDate(monthStart), isoDate(monthEnd));
    if (rows.isEmpty) return;
    final counts = <String, int>{};
    for (final r in rows) {
      counts[r.currency] = (counts[r.currency] ?? 0) + 1;
    }
    final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    ctrl._setCurrencyInternal(top.first.key);
  });
  return ctrl;
});
