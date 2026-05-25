import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/application/default_currency_provider.dart';

/// Dashboard 顶部过滤条状态。
///
/// - [currency] = null → 「全部货币」分行展示
/// - [sourceId] = null → 「全部来源」
class DashboardFilter {
  const DashboardFilter({this.currency, this.sourceId});

  final String? currency;
  final String? sourceId;

  DashboardFilter copyWith({
    Object? currency = _sentinel,
    Object? sourceId = _sentinel,
  }) {
    return DashboardFilter(
      currency: currency == _sentinel ? this.currency : currency as String?,
      sourceId: sourceId == _sentinel ? this.sourceId : sourceId as String?,
    );
  }

  static const _sentinel = Object();
}

/// 维护 dashboard 顶部过滤条的当次选择（货币 / 来源）。
class DashboardFilterController extends StateNotifier<DashboardFilter> {
  DashboardFilterController(String defaultCurrency)
      : super(DashboardFilter(currency: defaultCurrency));

  /// 设置货币；传 null 表示「全部」。
  void setCurrency(String? code) => state = state.copyWith(currency: code);

  /// 设置来源；传 null 表示「全部」。
  void setSource(String? id) => state = state.copyWith(sourceId: id);
}

final dashboardFilterProvider =
    StateNotifierProvider<DashboardFilterController, DashboardFilter>((ref) {
  // 初始货币 = 用户设置的默认货币。
  // 注意：不 watch defaultCurrencyProvider —— 用户后续在设置里改了默认，
  // 不影响已经打开的 dashboard 当次选择；下次进 app 重启会重置到新默认。
  final initial = ref.read(defaultCurrencyProvider);
  return DashboardFilterController(initial);
});
