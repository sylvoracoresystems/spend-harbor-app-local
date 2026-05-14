import 'package:meta/meta.dart';

enum StatsPeriod { week, month, year }

@immutable
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

const _unset = Object();
