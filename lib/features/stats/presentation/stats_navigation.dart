import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../application/stats_buckets.dart';
import '../application/stats_filter.dart';
import '../application/stats_filter_provider.dart';

void navigateToTransactions(
  BuildContext context,
  WidgetRef ref, {
  String? categoryId,
  String? tagId,
  bool untagged = false,
}) {
  final f = ref.read(statsFilterProvider);
  final qp = <String, String>{};
  switch (f.period) {
    case StatsPeriod.month:
      qp['month'] =
          '${f.selectedBucketStart.year.toString().padLeft(4, '0')}'
          '-${f.selectedBucketStart.month.toString().padLeft(2, '0')}';
      break;
    case StatsPeriod.week:
      final start = f.selectedBucketStart;
      final end = DateTime(start.year, start.month, start.day + 6);
      qp['dateStart'] = isoDate(start);
      qp['dateEnd'] = isoDate(end);
      break;
    case StatsPeriod.year:
      final y = f.selectedBucketStart.year.toString().padLeft(4, '0');
      qp['dateStart'] = '$y-01-01';
      qp['dateEnd'] = '$y-12-31';
      break;
  }
  if (f.sourceId != null) qp['source'] = f.sourceId!;
  if (categoryId != null) qp['category'] = categoryId;
  if (tagId != null) qp['tag'] = tagId;
  if (untagged) qp['untagged'] = '1';
  final uri = Uri(path: '/transactions', queryParameters: qp);
  context.go(uri.toString());
}
