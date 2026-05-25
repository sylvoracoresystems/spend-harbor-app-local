import 'package:meta/meta.dart';

enum StatsPeriod { week, month, year }

@immutable
/// Stats 视图的过滤条件：币种/来源/周期/当前桶 + 周/年/月切换记忆锚点。
class StatsFilter {
  const StatsFilter({
    required this.currency,
    this.sourceId,
    required this.period,
    required this.selectedBucketStart,
    required this.rememberedMonthAnchor,
    required this.rememberedYearAnchor,
  });

  final String currency;
  final String? sourceId;
  final StatsPeriod period;

  /// 选中桶的起点（对齐到 period：周一 / 月一 / 1月1日）。
  final DateTime selectedBucketStart;

  /// 用户在 month 模式最近选中的月（默认当月）。
  final DateTime rememberedMonthAnchor;

  /// 用户在 year 模式最近选中的年（默认当年）。
  final DateTime rememberedYearAnchor;

  StatsFilter copyWith({
    String? currency,
    Object? sourceId = _unset,
    StatsPeriod? period,
    DateTime? selectedBucketStart,
    DateTime? rememberedMonthAnchor,
    DateTime? rememberedYearAnchor,
  }) {
    return StatsFilter(
      currency: currency ?? this.currency,
      sourceId: identical(sourceId, _unset) ? this.sourceId : sourceId as String?,
      period: period ?? this.period,
      selectedBucketStart: selectedBucketStart ?? this.selectedBucketStart,
      rememberedMonthAnchor:
          rememberedMonthAnchor ?? this.rememberedMonthAnchor,
      rememberedYearAnchor:
          rememberedYearAnchor ?? this.rememberedYearAnchor,
    );
  }
}

/// sentinel：用于 copyWith 区分"没传"（保留旧值）和"显式传 null"（清空）。
/// 仅适用于 nullable 字段；普通字段直接用 `?? this.x` 即可。
const _unset = Object();
