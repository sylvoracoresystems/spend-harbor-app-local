import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../database/tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionTags])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  /// 监听全部存活交易（按 transactedOn 降序）。
  Stream<List<Transaction>> watchAll() {
    return (select(transactions)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactedOn),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  /// 按月份监听（YYYY-MM 前缀匹配）。
  Stream<List<Transaction>> watchByMonth(String yearMonth) {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() & t.transactedOn.like('$yearMonth-%'))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactedOn),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .watch();
  }

  Future<Transaction?> findById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 新建交易 + 关联标签（事务内执行）。
  Future<void> insertWithTags(
    TransactionsCompanion entry,
    List<String> tagIds,
  ) {
    return transaction(() async {
      await into(transactions).insert(entry);
      if (tagIds.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            transactionTags,
            tagIds
                .map((tagId) => TransactionTagsCompanion.insert(
                      transactionId: entry.id.value,
                      tagId: tagId,
                    ))
                .toList(),
          );
        });
      }
    });
  }

  /// 更新交易 + 重写标签关联。
  Future<void> updateWithTags(
    TransactionsCompanion entry,
    List<String> tagIds,
  ) {
    return transaction(() async {
      await update(transactions).replace(entry);
      final txId = entry.id.value;
      await (delete(transactionTags)
            ..where((t) => t.transactionId.equals(txId)))
          .go();
      if (tagIds.isNotEmpty) {
        await batch((b) {
          b.insertAll(
            transactionTags,
            tagIds
                .map((tagId) => TransactionTagsCompanion.insert(
                      transactionId: txId,
                      tagId: tagId,
                    ))
                .toList(),
          );
        });
      }
    });
  }

  Future<int> softDelete(String id) {
    return (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 获取某笔交易关联的所有标签 id。
  Future<List<String>> tagIdsOf(String transactionId) async {
    final rows = await (select(transactionTags)
          ..where((t) => t.transactionId.equals(transactionId)))
        .get();
    return rows.map((r) => r.tagId).toList();
  }
}
