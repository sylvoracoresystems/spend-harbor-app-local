/// Stats 视图的时间桶纯函数：period 对齐、桶序列生成、相对位移。
/// 不依赖 DB / provider / Flutter，所以单测里随便造时间也安全。
library;

import 'stats_filter.dart';

class TrendBucket {
  const TrendBucket({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// 把任意时刻对齐到所属 period 的起点：周一 00:00 / 月一 00:00 / 1月1日 00:00。
/// 周起点固定为周一（ISO 8601 / 也是 Dart `weekday` 的 1）。
DateTime alignToPeriodStart(DateTime d, StatsPeriod p) {
  switch (p) {
    case StatsPeriod.week:
      final dow = d.weekday; // Mon=1..Sun=7
      return DateTime(d.year, d.month, d.day - (dow - 1));
    case StatsPeriod.month:
      return DateTime(d.year, d.month, 1);
    case StatsPeriod.year:
      return DateTime(d.year, 1, 1);
  }
}

/// 视口里"目标可见桶数"的底线：年 3 / 周月 6。横向超出的部分用户可滚动。
int _bucketCount(StatsPeriod p) =>
    p == StatsPeriod.year ? 3 : 6;

/// 公开默认桶数，供 provider 计算"最少桨数底线"。
int defaultBucketCount(StatsPeriod p) => _bucketCount(p);

/// 两个对齐起点之间相差多少个 period 步长（b - a，可能为负）。
int periodStepsBetween(DateTime a, DateTime b, StatsPeriod p) {
  switch (p) {
    case StatsPeriod.week:
      return b.difference(a).inDays ~/ 7;
    case StatsPeriod.month:
      return (b.year - a.year) * 12 + (b.month - a.month);
    case StatsPeriod.year:
      return b.year - a.year;
  }
}

DateTime _addPeriod(DateTime start, StatsPeriod p, int n) {
  switch (p) {
    case StatsPeriod.week:
      return DateTime(start.year, start.month, start.day + n * 7);
    case StatsPeriod.month:
      return DateTime(start.year, start.month + n, 1);
    case StatsPeriod.year:
      return DateTime(start.year + n, 1, 1);
  }
}

DateTime _endOfBucket(DateTime start, StatsPeriod p) {
  switch (p) {
    case StatsPeriod.week:
      return DateTime(start.year, start.month, start.day + 6);
    case StatsPeriod.month:
      final next = DateTime(start.year, start.month + 1, 1);
      return next.subtract(const Duration(days: 1));
    case StatsPeriod.year:
      return DateTime(start.year, 12, 31);
  }
}

/// 生成最右端含 [anchor] 所在桶、向左铺 n-1 个的连续桶序列。
/// 调用方传 [count] 是为了让最早交易也可见（见 trendBucketsProvider）。
List<TrendBucket> generateBuckets(StatsPeriod p, DateTime anchor, {int? count}) {
  final rightStart = alignToPeriodStart(anchor, p);
  final n = count ?? _bucketCount(p);
  final out = <TrendBucket>[];
  for (var i = n - 1; i >= 0; i--) {
    final start = _addPeriod(rightStart, p, -i);
    out.add(TrendBucket(start: start, end: _endOfBucket(start, p)));
  }
  return out;
}

String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
