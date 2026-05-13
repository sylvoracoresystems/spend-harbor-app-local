import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';

/// 回收站保留天数。
const int kRecycleRetentionDays = 30;

DateTime _retentionCutoff(DateTime now) =>
    now.subtract(const Duration(days: kRecycleRetentionDays));

/// 回收站内的交易（30 天保留期内）。
final trashedTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final dao = ref.watch(transactionDaoProvider);
  return dao.watchTrashed(_retentionCutoff(DateTime.now()));
});

/// 回收站操作 API：恢复 / 彻底删除 / 自动清理过期项。
class RecycleBinController {
  RecycleBinController(this._ref);
  final Ref _ref;

  Future<void> restore(String id) =>
      _ref.read(transactionDaoProvider).restore(id);

  Future<void> purge(String id) =>
      _ref.read(transactionDaoProvider).purge(id);

  /// 把超过 [kRecycleRetentionDays] 天的软删项物理清理掉。
  Future<int> purgeExpired() =>
      _ref.read(transactionDaoProvider).purgeOlderThan(
            _retentionCutoff(DateTime.now()),
          );
}

final recycleBinControllerProvider = Provider<RecycleBinController>(
  (ref) => RecycleBinController(ref),
);

/// 计算保留期剩余天数（向下取整，至少 0）。
int daysLeft(DateTime deletedAt, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final remaining =
      const Duration(days: kRecycleRetentionDays) - n.difference(deletedAt);
  if (remaining.isNegative) return 0;
  return remaining.inDays;
}
