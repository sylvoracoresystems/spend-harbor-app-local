/// Stats 页面的 provider DAG。所有衍生 provider 链最终都收敛到两个共享 future：
/// - [bucketTransactionsProvider]：选中桶 + currency/source 过滤后的 raw rows
/// - [bucketTagsByTxProvider]：上述 rows 的 tagId 反查
/// 这样 distribution / top / 等卡片切换 type/mode 时只重算聚合、不重新查 DB。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../domain/enums/transaction_type.dart';
import 'stats_buckets.dart';
import 'stats_filter.dart';
import 'stats_filter_provider.dart';
import 'stats_top_aggregator.dart';

/// 单桶在某币种下的双值（income / expense cents）。
class TrendBucketValues {
  const TrendBucketValues({
    required this.bucket,
    required this.incomeCents,
    required this.expenseCents,
  });
  final TrendBucket bucket;
  final int incomeCents;
  final int expenseCents;
}

/// Trend 数据：桶数 = max(默认 6/3, 最早 tx 到 anchor 的 period 跨度 + 1)，
/// 让用户能横向滚回到全部历史数据。
final trendBucketsProvider =
    FutureProvider<List<TrendBucketValues>>((ref) async {
  final f = ref.watch(statsFilterProvider);
  final anchor = DateTime.now();
  final dao = ref.watch(transactionDaoProvider);
  final earliestIso = await dao.findEarliestDate(
    currency: f.currency,
    sourceId: f.sourceId,
  );
  int count = defaultBucketCount(f.period);
  if (earliestIso != null) {
    final earliest = alignToPeriodStart(DateTime.parse(earliestIso), f.period);
    final rightStart = alignToPeriodStart(anchor, f.period);
    final span = periodStepsBetween(earliest, rightStart, f.period) + 1;
    if (span > count) count = span;
  }
  final buckets = generateBuckets(f.period, anchor, count: count);
  final start = buckets.first.start;
  final end = buckets.last.end;
  final rows = await dao.findByDateRange(isoDate(start), isoDate(end));

  final out = <TrendBucketValues>[];
  for (final b in buckets) {
    int inc = 0;
    int exp = 0;
    for (final r in rows) {
      if (r.currency != f.currency) continue;
      if (f.sourceId != null && r.sourceId != f.sourceId) continue;
      final d = DateTime.parse(r.transactedOn);
      if (d.isBefore(b.start) || d.isAfter(b.end)) continue;
      if (r.type == TransactionType.expense) {
        exp += r.amountCents;
      } else {
        inc += r.amountCents;
      }
    }
    out.add(TrendBucketValues(bucket: b, incomeCents: inc, expenseCents: exp));
  }
  return out;
});

/// 选中桶范围内 + currency/source 过滤后的原始 rows（给 Distribution / Top 复用）。
/// [start, end] 闭区间；month/year 的 end 走 "下月/年首减 1 天" 算法避免硬编码月长。
final bucketTransactionsProvider =
    FutureProvider<List<Transaction>>((ref) async {
  final f = ref.watch(statsFilterProvider);
  final start = f.selectedBucketStart;
  final DateTime end;
  switch (f.period) {
    case StatsPeriod.week:
      end = DateTime(start.year, start.month, start.day + 6);
      break;
    case StatsPeriod.month:
      end = DateTime(start.year, start.month + 1, 0);
      break;
    case StatsPeriod.year:
      end = DateTime(start.year, 12, 31);
      break;
  }
  final dao = ref.watch(transactionDaoProvider);
  final all = await dao.findByDateRange(isoDate(start), isoDate(end));
  return [
    for (final r in all)
      if (r.currency == f.currency &&
          (f.sourceId == null || r.sourceId == f.sourceId))
        r,
  ];
});

/// 选中桶内的 tagIdsByTx（一次查询，给 Tag Distribution + Top 复用）。
final bucketTagsByTxProvider =
    FutureProvider<Map<String, List<String>>>((ref) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  if (rows.isEmpty) return const {};
  return ref
      .watch(transactionDaoProvider)
      .tagIdsForMany(rows.map((r) => r.id).toList());
});

/// 分类维度的单片：分类 id + 该分类金额合计（cents）。
class CategorySlice {
  const CategorySlice({required this.categoryId, required this.totalCents});
  final String categoryId;
  final int totalCents;
}

/// 标签维度的单片：标签 id + 该标签金额合计（cents）。
class TagSlice {
  const TagSlice({required this.tagId, required this.totalCents});
  final String tagId;
  final int totalCents;
}

/// 分类分布的聚合结果：所有 slice + 总金额。
class CategoryDistribution {
  const CategoryDistribution({required this.slices, required this.totalCents});
  final List<CategorySlice> slices;
  final int totalCents;
}

/// 标签分布的聚合结果：所有 slice + 总金额 + 未打标签金额。
class TagDistribution {
  const TagDistribution({
    required this.slices,
    required this.totalCents,
    required this.untaggedCents,
  });
  final List<TagSlice> slices;
  final int totalCents;
  final int untaggedCents;
}

final categoryDistributionProvider =
    FutureProvider.family<CategoryDistribution, TransactionType>(
        (ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final totals = <String, int>{};
  int sum = 0;
  for (final r in rows) {
    if (r.type != type) continue;
    totals[r.categoryId] = (totals[r.categoryId] ?? 0) + r.amountCents;
    sum += r.amountCents;
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return CategoryDistribution(
    slices: [
      for (final e in entries)
        CategorySlice(categoryId: e.key, totalCents: e.value),
    ],
    totalCents: sum,
  );
});

final tagDistributionProvider =
    FutureProvider.family<TagDistribution, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tagsByTx = await ref.watch(bucketTagsByTxProvider.future);
  final totals = <String, int>{};
  int sum = 0;
  int untagged = 0;
  for (final r in rows) {
    if (r.type != type) continue;
    sum += r.amountCents;
    final tags = tagsByTx[r.id] ?? const <String>[];
    if (tags.isEmpty) {
      untagged += r.amountCents;
      continue;
    }
    for (final tag in tags) {
      totals[tag] = (totals[tag] ?? 0) + r.amountCents;
    }
  }
  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return TagDistribution(
    slices: [
      for (final e in entries) TagSlice(tagId: e.key, totalCents: e.value),
    ],
    totalCents: sum,
    untaggedCents: untagged,
  );
});

final topByCategoryProvider =
    FutureProvider.family<List<TopCategoryRow>, TransactionType>(
        (ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tags = await ref.watch(bucketTagsByTxProvider.future);
  final f = ref.read(statsFilterProvider);
  return aggregateTopByCategory(
    rows,
    type: type,
    currency: f.currency,
    sourceId: f.sourceId,
    tagsByTx: tags,
    limit: 10,
  );
});

final topByTagProvider =
    FutureProvider.family<TopTagAggregate, TransactionType>((ref, type) async {
  final rows = await ref.watch(bucketTransactionsProvider.future);
  final tags = await ref.watch(bucketTagsByTxProvider.future);
  final f = ref.read(statsFilterProvider);
  return aggregateTopByTag(
    rows,
    type: type,
    currency: f.currency,
    sourceId: f.sourceId,
    tagsByTx: tags,
    limit: 10,
  );
});
