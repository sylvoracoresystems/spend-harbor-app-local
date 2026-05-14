import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database_provider.dart';

/// 近 30 天内每个 tag 被使用的次数（tagId -> count）。
/// 用于交易表单中的标签排序。
final tagUsageLast30dProvider = FutureProvider<Map<String, int>>((ref) async {
  final dao = ref.watch(transactionDaoProvider);
  final now = DateTime.now();
  final since = now.subtract(const Duration(days: 30));
  final iso = '${since.year.toString().padLeft(4, '0')}-'
      '${since.month.toString().padLeft(2, '0')}-'
      '${since.day.toString().padLeft(2, '0')}';
  return dao.tagUsageSince(iso);
});
